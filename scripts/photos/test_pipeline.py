#!/usr/bin/env python3
"""Tests of the photo pipeline (offline: providers and downloads are faked).

    python3 scripts/photos/test_pipeline.py
"""
from __future__ import annotations

import argparse
import copy
import json
import math
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import pipeline as P  # noqa: E402


def ns(**kw):
    return argparse.Namespace(**{"dry_run": False, "offline": False, **kw})


class Sandbox:
    """Points every output path of the pipeline to a temporary folder."""

    NAMES = ["CATALOG", "MANIFEST", "PHOTOS_XCASSETS", "CREDITS_JSON", "DOCS", "CACHE", "REPORTS"]

    def __enter__(self):
        self.dir = Path(tempfile.mkdtemp())
        self.saved = {n: getattr(P, n) for n in self.NAMES}
        self.saved_root = P.ROOT
        P.CATALOG = self.dir / "photo_catalog.json"
        P.MANIFEST = self.dir / "photo_sources.json"
        P.PHOTOS_XCASSETS = self.dir / "Photos"
        P.CREDITS_JSON = self.dir / "PhotoCredits.json"
        P.DOCS = self.dir / "docs"
        P.CACHE = self.dir / "cache"
        P.REPORTS = self.dir / "reports"
        P.ROOT = self.dir
        return self.dir

    def __exit__(self, *exc):
        for n, v in self.saved.items():
            setattr(P, n, v)
        P.ROOT = self.saved_root
        shutil.rmtree(self.dir, ignore_errors=True)


def fake_candidate(pid: str, provider="pexels", w=3000, h=2000, title="", lic="pexels", **extra):
    c = {"provider": provider, "providerPhotoId": pid, "width": w, "height": h, "title": title, "tags": [],
         "photographer": "Jane Doe", "photographerUrl": "https://example.org/jane", "sourceUrl": f"https://example.org/p/{pid}",
         "downloadUrl": f"https://example.org/img/{pid}.jpg", "license": lic, "licenseUrl": "https://example.org/license",
         "licenseCode": lic, "mature": False, "avgColor": None}
    c.update(extra)
    return c


class FakeWorld:
    """Replaces the network: search returns fixed candidates, download writes generated images."""

    def __init__(self, dark=False):
        self.dark = dark
        self.searches = 0

    def search(self, http, cfg, query, offline):
        self.searches += 1
        base = abs(hash(query)) % 10_000
        return [fake_candidate(f"{base}{i}", title=query) for i in range(3)]

    def download(self, url, dest):
        from PIL import Image, ImageDraw
        import hashlib
        seed = int(hashlib.sha1(url.encode()).hexdigest(), 16) % 100_000
        level = 20 if self.dark else 170
        im = Image.new("RGB", (2400, 1600), (level, level, level))
        d = ImageDraw.Draw(im)
        for i in range(12):
            x = (seed * 37 + i * 190) % 2300
            y = (seed // 7 + i * 97) % 1400
            d.rectangle([x, y, x + 60 + seed % 90, y + 80 + (seed // 3) % 120], fill=((seed + i * 20) % 255, level, (seed // 11) % 255))
        dest.parent.mkdir(parents=True, exist_ok=True)
        im.save(dest, "JPEG", quality=90)
        return True


class AuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = P.load_json(P.CONFIG)
        with Sandbox():
            cls.catalog = P.cmd_audit(ns(dry_run=True), copy.deepcopy(cls.cfg))

    def test_every_photo_of_every_case_has_one_decision(self):
        photos = [ph for case in P.load_cases() for dev in case["devices"] for ph in dev["photos"]]
        self.assertEqual(len(self.catalog["photos"]), len(photos))
        ids = [p["assetId"] for p in self.catalog["photos"]]
        self.assertEqual(len(ids), len(set(ids)))
        for p in self.catalog["photos"]:
            self.assertIn(p["decision"], P.DECISIONS)
            self.assertTrue(p["reason"])

    def test_evidence_is_real_only_when_its_query_sheet_says_so(self):
        for p in self.catalog["photos"]:
            if p["isEvidence"] and p["decision"] == "REPLACE_REAL":
                self.assertTrue(p["planned"], p["assetId"])

    def test_query_sheets_decide(self):
        by_id = {p["assetId"]: p for p in self.catalog["photos"]}
        for path in sorted(P.QUERIES_DIR.glob("case_*.json")):
            sheet = P.load_json(path)
            for pid, plan in sheet["photos"].items():
                aid = P.asset_name(sheet["case"], pid)
                self.assertIn(aid, by_id, f"{path.name}: {pid} is not a photo of the case")
                expected = {"REAL": "REPLACE_REAL", "PROCEDURAL": "PROCEDURAL"}.get(plan["decision"], "CUSTOM_REAL")
                self.assertEqual(by_id[aid]["decision"], expected, aid)
                if plan["decision"] == "REAL":
                    self.assertTrue(plan["query"].strip(), aid)
                    self.assertTrue(plan.get("subject"), aid)
        self.assertEqual(by_id["case001_photo_p_b08"]["decision"], "PROCEDURAL")  # screenshot

    def test_every_case_has_a_query_sheet(self):
        for case in P.load_cases():
            key = f"{case['number']:03d}"
            sheet = P.load_json(P.QUERIES_DIR / f"case_{key}.json")
            self.assertIsNotNone(sheet, key)
            photos = {ph["id"] for dev in case["devices"] for ph in dev["photos"]}
            self.assertEqual(set(sheet["photos"]), photos, key)

    def test_shared_photos_use_one_photograph(self):
        by_id = {p["assetId"]: p for p in self.catalog["photos"]}
        for p in self.catalog["photos"]:
            if p.get("shareWith") and p.get("source"):
                other = by_id[P.asset_name(p["case"], p["shareWith"])]
                self.assertEqual(p["source"], other.get("source"), p["assetId"])
                self.assertNotEqual(p["variant"], other.get("variant"), p["assetId"])

    def test_sources_have_queries_and_share_photos(self):
        self.assertGreaterEqual(len(self.catalog["sources"]), 30)
        for s in self.catalog["sources"]:
            self.assertTrue(s["query"].strip(), s["id"])
            self.assertLessEqual(len(s["variants"] if isinstance(s["variants"], list) else s["photos"]), len(P.VARIANTS), s["id"])
        assigned = [p for p in self.catalog["photos"] if p.get("source")]
        self.assertEqual(len(assigned), sum(len(s["photos"]) for s in self.catalog["sources"]))

    def test_night_photos_ask_for_night(self):
        for s in self.catalog["sources"]:
            if s["requireDark"]:
                self.assertTrue(s["night"])


class ScoreTests(unittest.TestCase):
    cfg = P.load_json(P.CONFIG)
    src = {"query": "Marseille street at night", "minWidth": 1200, "minHeight": 800, "night": True}

    def test_rejects_non_commercial_or_no_derivatives(self):
        for lic in ("by-nc", "by-nd", "by-nc-sa"):
            c = fake_candidate("1", provider="openverse", lic=lic)
            self.assertEqual(P.score(c, self.src, self.cfg)[0], -math.inf, lic)

    def test_rejects_missing_licence_data(self):
        c = fake_candidate("1", provider="openverse", lic="by", licenseUrl="")
        self.assertEqual(P.score(c, self.src, self.cfg)[0], -math.inf)
        c = fake_candidate("2", provider="openverse", lic="by", photographer="")
        self.assertEqual(P.score(c, self.src, self.cfg)[0], -math.inf)

    def test_accepts_cc0_and_by(self):
        for lic in ("cc0", "by", "by-sa", "pdm"):
            c = fake_candidate("1", provider="openverse", lic=lic, title="Marseille street night")
            self.assertGreater(P.score(c, self.src, self.cfg)[0], 0, lic)

    def test_rejects_low_resolution(self):
        self.assertEqual(P.score(fake_candidate("1", w=800, h=600), self.src, self.cfg)[0], -math.inf)

    def test_prefers_night_and_no_people(self):
        night = P.score(fake_candidate("1", title="street at night lights", avgColor="#1a1a22"), self.src, self.cfg)[0]
        day = P.score(fake_candidate("2", title="sunny street day", avgColor="#d0d8e0"), self.src, self.cfg)[0]
        people = P.score(fake_candidate("3", title="woman portrait street at night", avgColor="#1a1a22"), self.src, self.cfg)[0]
        self.assertGreater(night, day)
        self.assertGreater(night, people)

    def test_rejects_foreign_places_brands_and_off_subject(self):
        src = {**self.src, "case": "001"}
        for title in ("Old Bagan, Myanmar, sunset over pagodas", "Crossing the busy street to Old Shanghai",
                      "Apliu Street BMW black car at night"):
            self.assertEqual(P.score(fake_candidate("1", title=title), src, self.cfg)[0], -math.inf, title)
        # The subject (« street ») must be in the title or the tags; the city alone is not enough.
        self.assertEqual(P.score(fake_candidate("2", title="Bonne Mère Marseille"), src, self.cfg)[0], -math.inf)
        self.assertGreater(P.score(fake_candidate("3", title="Marseille, rue le soir", tags=["street", "night"]), src, self.cfg)[0], 0)

    def test_titles_are_cleaned(self):
        self.assertEqual(P.clean_title("<div class='fn'> Bonne Mère Marseille</div>"), "Bonne Mère Marseille")
        self.assertEqual(P.clean_title("File:Quai du Rhône (36045409450).jpg"), "Quai du Rhône")

    def test_wikimedia_licences(self):
        self.assertEqual(P.wikimedia_licence("CC BY-SA 4.0"), ("by-sa", "4.0"))
        self.assertEqual(P.wikimedia_licence("CC BY 2.0"), ("by", "2.0"))
        self.assertEqual(P.wikimedia_licence("CC0"), ("cc0", ""))
        self.assertEqual(P.wikimedia_licence("Public domain"), ("pdm", ""))
        for refused in ("CC BY-NC 2.0", "CC BY-ND 4.0", "GFDL", "Copyrighted free use", ""):
            self.assertEqual(P.wikimedia_licence(refused)[0], "", refused)

    def test_rejects_ai_images_and_non_photos(self):
        src = {**self.src, "case": "001"}
        base = dict(provider="wikimedia", lic="by-sa", tags=["street", "night"])
        self.assertGreater(P.score(fake_candidate("1", title="Rue de nuit", **base), src, self.cfg)[0], 0)
        for tags, why in ((["AI-generated images", "street"], "IA"), (["Stable Diffusion", "street"], "IA"),
                          (["Drawings of streets", "street drawing"], "photographie"), (["Maps of Marseille", "street map"], "photographie")):
            sc, reason = P.score(fake_candidate("2", title="Rue de nuit", **{**base, "tags": tags}), src, self.cfg)
            self.assertEqual(sc, -math.inf, tags)
            self.assertIn(why, reason)
        self.assertEqual(P.score(fake_candidate("3", title="Rue de nuit", year=1932, **base), src, self.cfg)[0], -math.inf)
        self.assertEqual(P.score(fake_candidate("4", title="Rue de nuit", restrictions="Personality rights", **base), src, self.cfg)[0], -math.inf)
        self.assertEqual(P.score(fake_candidate("5", title="Rue de nuit", mime="image/png", **base), src, self.cfg)[0], -math.inf)

    def test_evidence_never_shows_people(self):
        src = {**self.src, "case": "001", "isEvidence": True}
        self.assertEqual(P.score(fake_candidate("1", title="street at night woman", tags=["street"]), src, self.cfg)[0], -math.inf)

    def test_subject_words_of_the_query_sheet(self):
        src = {**self.src, "case": "001", "subject": ["métro", "subway"]}
        self.assertEqual(P.score(fake_candidate("1", title="Marseille street at night"), src, self.cfg)[0], -math.inf)
        self.assertGreater(P.score(fake_candidate("2", title="Marseille metro at night"), src, self.cfg)[0], 0)

    def test_attribution_texts(self):
        self.assertEqual(P.attribution_text(fake_candidate("1")), "Photo by Jane Doe on Pexels")
        self.assertIn("CC BY", P.attribution_text(fake_candidate("1", provider="openverse", lic="by", licenseVersion="4.0", title="Port")))


class EndToEndTests(unittest.TestCase):
    def run_pipeline(self, world, dry_run=False):
        cfg = P.load_json(P.CONFIG)
        P.pexels_search = world.search
        P.openverse_search = lambda *a: []
        P.wikimedia_search = lambda *a: []
        P.Http.download = world.download
        stats = {"requests": {}, "rejected": 0, "errors": []}
        args = ns(dry_run=dry_run)
        catalog = P.cmd_audit(args, cfg)
        if dry_run:
            P.write_json(P.CATALOG, catalog)  # the other steps read it; nothing else is written
        manifest = P.load_json(P.MANIFEST, {}) or {"sources": [], "assets": []}
        manifest.setdefault("sources", []); manifest.setdefault("assets", [])
        for step in (P.cmd_search, P.cmd_download, P.cmd_process):
            step(args, cfg, catalog, manifest, stats)
        if not dry_run:
            P.write_json(P.MANIFEST, manifest)
            P.cmd_report(args, cfg, catalog, manifest, stats)
        return cfg, catalog, manifest, stats

    def setUp(self):
        self.saved = (P.pexels_search, P.openverse_search, P.Http.download, P.wikimedia_search)

    def tearDown(self):
        P.pexels_search, P.openverse_search, P.Http.download, P.wikimedia_search = self.saved

    def test_full_run_produces_credited_images(self):
        with Sandbox() as d:
            cfg, catalog, manifest, stats = self.run_pipeline(FakeWorld())
            fetched = [e for e in manifest["sources"] if e["status"] == "fetched"]
            # Day sources are fetched; night sources need dark images (the fake world is bright).
            day_sources = [s for s in catalog["sources"] if not s["requireDark"]]
            self.assertGreaterEqual(len(fetched), len(day_sources) * 0.6)
            self.assertTrue(manifest["assets"])
            from PIL import Image
            for a in manifest["assets"]:
                path = d / a["finalAssetPath"]
                self.assertTrue(path.exists(), path)
                with Image.open(path) as im:
                    self.assertEqual(im.size, (1024, 768))
                self.assertTrue((path.parent / "Contents.json").exists())
            problems = P.cmd_validate(ns(), cfg, catalog, manifest, stats)
            self.assertEqual([p for p in problems if "clé" not in p], [])
            credits = json.loads((d / "PhotoCredits.json").read_text())
            self.assertTrue(credits["pexels"])
            self.assertTrue(all(i["attribution"].startswith("Photo by") for i in credits["items"]))
            self.assertIn("REAL PHOTO COMPLIANCE", (d / "docs" / "PHOTO_SOURCES.md").read_text())
            self.assertIn("REAL PHOTO COMPLIANCE", (d / "docs" / "PHOTO_AUDIT.md").read_text())

    def test_night_sources_reject_bright_images(self):
        with Sandbox():
            _, catalog, manifest, stats = self.run_pipeline(FakeWorld(dark=False))
            dark = {s["id"] for s in catalog["sources"] if s["requireDark"]}
            for e in manifest["sources"]:
                if e["sourceId"] in dark:
                    self.assertEqual(e["status"], "missing", e["sourceId"])
            self.assertGreater(stats["rejected"] + manifest.get("stats", {}).get("rejected", 0), 0)

    def test_cache_avoids_new_requests(self):
        with Sandbox():
            world = FakeWorld()
            self.run_pipeline(world)
            first = world.searches
            P.pexels_search = self.saved[0]  # the real function: must answer from the cache
            cfg = P.load_json(P.CONFIG)
            catalog = P.load_json(P.CATALOG)
            manifest = P.load_json(P.MANIFEST)
            stats = {"requests": {}, "rejected": 0, "errors": []}
            P.cmd_search(ns(offline=True), cfg, catalog, manifest, stats)
            self.assertEqual(stats["requests"], {})
            self.assertGreater(first, 0)

    def test_dry_run_writes_no_asset(self):
        with Sandbox() as d:
            self.run_pipeline(FakeWorld(), dry_run=True)
            self.assertFalse((d / "Photos").exists())
            self.assertFalse((d / "photo_sources.json").exists())
            self.assertFalse((d / "cache" / "originals").exists())

    def test_crops_are_deterministic_and_distinct(self):
        from PIL import Image
        im = Image.new("RGB", (3000, 2000), (120, 120, 120))
        boxes = {side: P.smart_box(im, 4 / 3, zoom, side) for side, zoom in P.VARIANTS}
        self.assertEqual(boxes["best"], P.smart_box(im, 4 / 3, 1.0, "best"))
        self.assertNotEqual(boxes["left"], boxes["right"])
        for (x0, y0, x1, y1) in boxes.values():
            self.assertAlmostEqual((x1 - x0) / (y1 - y0), 4 / 3, delta=0.01)


class SecurityTests(unittest.TestCase):
    def test_no_api_key_in_repository(self):
        bad = []
        for path in P.ROOT.rglob("*"):
            if path.is_file() and ".git" not in path.parts and "cache" not in path.parts and ".build" not in path.parts \
                    and path.suffix in (".json", ".py", ".sh", ".yml", ".md", ".swift", ".xcconfig", ".plist"):
                if P.KEY_PATTERN.search(path.read_text(encoding="utf-8", errors="ignore")):
                    bad.append(str(path))
        self.assertEqual(bad, [])

    def test_game_never_calls_the_photo_apis(self):
        ui = P.ROOT / "ScreenshotKit" / "Sources"
        for path in ui.rglob("*.swift"):
            text = path.read_text(encoding="utf-8")
            for word in ("api.pexels.com", "api.openverse.org", "URLSession"):
                self.assertNotIn(word, text, f"{path}: {word}")


if __name__ == "__main__":
    unittest.main(verbosity=1)
