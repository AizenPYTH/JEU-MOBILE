#!/usr/bin/env python3
"""CONCLUDE : ENQUÊTES — photo asset pipeline.

Turns the photos of the case files into REAL photographs, credited, offline (never an AI image):

    case JSON + config/photo_queries ──audit──▶ config/photo_catalog.json (one decision per photo)
              ──search──▶ Wikimedia Commons / Pexels / Openverse candidates (cached), scored, best picked
              ──download─▶ originals (cached)
              ──process──▶ Art.xcassets/Photos/caseNNN_photo_<id>.imageset (crop, resize, JPEG)
              ──validate─▶ checks (files, sizes, provenance, licences, no key, no duplicate)
              ──report───▶ docs/photo_pipeline/PHOTO_AUDIT.md, PHOTO_SOURCES.md, in-app credits

Commands: audit | search | download | process | validate | report | status | all   [--dry-run]
The game never calls these APIs: images are prepared here and shipped in the app bundle.
Docs: docs/photo_pipeline/PHOTO_PIPELINE.md
"""
from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import html
import json
import math
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "config" / "photo_pipeline.json"
CATALOG = ROOT / "config" / "photo_catalog.json"
MANIFEST = ROOT / "config" / "photo_sources.json"
CASES_DIR = ROOT / "ScreenshotKit" / "Sources" / "CaseLibrary" / "Resources" / "Cases"
UI_RESOURCES = ROOT / "ScreenshotKit" / "Sources" / "ScreenshotUI" / "Resources"
PHOTOS_XCASSETS = UI_RESOURCES / "Art.xcassets" / "Photos"
CREDITS_JSON = UI_RESOURCES / "PhotoCredits.json"
DOCS = ROOT / "docs" / "photo_pipeline"
CACHE = ROOT / "cache" / "photos"
REPORTS = ROOT / "reports"

QUERIES_DIR = ROOT / "config" / "photo_queries"

# KEEP_REAL: a real photo already shipped and kept · REPLACE_REAL: a real photo from a free library ·
# CUSTOM_REAL: a real photo we have to take ourselves · PROCEDURAL: drawn by the game on purpose (screenshots,
# documents, receipts: not photographs) · REMOVE: an image to delete (AI, placeholder, unused).
DECISIONS = ["KEEP_REAL", "REPLACE_REAL", "CUSTOM_REAL", "PROCEDURAL", "REMOVE"]


# ─────────────────────────────────────────────────────────── helpers

def load_json(path: Path, default=None):
    if not path.exists():
        return default
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8")


def fold(text: str) -> str:
    """Lower case, no accents: « Élise » → « elise »."""
    text = unicodedata.normalize("NFD", text or "")
    return "".join(c for c in text if unicodedata.category(c) != "Mn").lower()


def tokens(text: str) -> set[str]:
    return {t for t in re.split(r"[^a-z0-9]+", fold(text)) if len(t) > 2}


def clean_title(text: str) -> str:
    """A provider title as a caption: no HTML, no « File: » prefix, no file extension."""
    text = html.unescape(re.sub(r"<[^>]+>", " ", text or ""))
    text = re.sub(r"^\s*File:\s*", "", text)
    text = re.sub(r"\s*\(\d{6,}\)", "", text)
    text = re.sub(r"\.(jpe?g|png|tiff?|webp)$", "", text.strip(), flags=re.I)
    return re.sub(r"\s+", " ", text).strip()


def now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat()


def log(msg: str) -> None:
    print(msg, flush=True)


def asset_name(case: str, photo_id: str) -> str:
    """Deterministic, readable asset name: case001_photo_p_b01 (the photo id comes from the case)."""
    return f"case{case}_photo_{photo_id}"


def hour_of(moment: str) -> int:
    m = re.search(r"(\d{2}):(\d{2})$", moment or "")
    return int(m.group(1)) if m else 12


# ─────────────────────────────────────────────────────────── audit

def load_cases() -> list[dict]:
    cases = []
    for path in sorted(list(CASES_DIR.glob("case_*.json")) + list(CASES_DIR.glob("alibi_*.json"))):
        data = load_json(path)
        cases.append(data)
    return cases


def evidence_index(case: dict) -> dict[str, list[str]]:
    """photo id → evidence ids that point at it (photo:… or photoInfo:…)."""
    index: dict[str, list[str]] = {}
    for ev in case.get("evidence", []):
        for ref in ev.get("refs", []):
            kind, _, ident = ref.partition(":")
            if kind in ("photo", "photoInfo"):
                index.setdefault(ident, []).append(ev["id"])
    return index


def photo_usage(case: dict) -> dict[str, list[str]]:
    """photo id → where it is shown besides the Photos app (message bubbles)."""
    usage: dict[str, list[str]] = {}
    for dev in case.get("devices", []):
        for conv in dev.get("conversations", []):
            for msg in conv.get("messages", []):
                if msg.get("photo"):
                    usage.setdefault(msg["photo"], []).append(f"Messages › {conv['id']}")
    return usage


def people_names(case: dict, extra: list[str]) -> list[str]:
    names = set(extra)
    for dev in case.get("devices", []):
        for c in dev.get("contacts", []):
            first = re.split(r"[\s(—-]+", c.get("name", "").strip())[0]
            if first and first[0].isupper() and len(first) > 1 and first not in ("Banque", "Colis", "Cabinet", "Garage", "École", "Relais", "Maison", "Arteo", "ColiPoint", "Dr", "M.", "Mme", "Maître", "Seb"):
                names.add(first)
    return sorted(names, key=len, reverse=True)


def is_night(photo: dict, rules: dict) -> bool:
    if photo.get("style") == "night" or photo["scene"] in rules["nocturnalScenes"]:
        return True
    h = hour_of(photo.get("takenAt", ""))
    if photo["scene"] in rules.get("nightByHourExcludes", []):
        return False
    return photo["scene"] in rules["outdoorScenes"] and (h >= rules["nightFromHour"] or h < rules["nightUntilHour"])


def classify(photo: dict, case: dict, ev_index: dict, names: list[str], cfg: dict, seen: dict) -> tuple[str, str]:
    rules = cfg["audit"]
    pid, scene, style = photo["id"], photo["scene"], photo.get("style")
    text = f"{photo.get('caption', '')} {photo.get('details', '')}"
    folded = fold(text)
    forced = rules.get("forceCustom", {}).get(f"{case['number']:03d}/{pid}")
    if pid in ev_index:
        return "CUSTOM_REAL", f"Preuve ({', '.join(ev_index[pid])}) : le cadrage, l'heure ou le contenu sert le raisonnement ; jamais de photo de banque d'images."
    if forced:
        return "CUSTOM_REAL", f"Détail utile à l'enquête (règle manuelle) : {forced}"
    if scene in rules["proceduralScenes"] or style in rules["proceduralStyles"] or photo.get("lines"):
        return "PROCEDURAL", "Texte lisible exact ou photo ratée : le rendu du jeu (texte généré, flou) reste la bonne source."
    if scene in rules["peopleScenes"] or style in rules["peopleStyles"]:
        return "CUSTOM_REAL", "Personnes de l'affaire à l'image (selfie, groupe, miroir) : une photo générique montrerait des inconnus."
    for name in names:
        if re.search(r"(?<![\wÀ-ÿ])" + re.escape(name) + r"(?![\wÀ-ÿ])", text):
            return "CUSTOM_REAL", f"Personne nommée à l'image ({name}) : une photo générique montrerait un inconnu."
    for word in rules["personWords"]:
        if re.search(r"(?<![a-z])" + re.escape(fold(word)) + r"(?![a-z])", folded):
            return "CUSTOM_REAL", f"Personne reconnaissable décrite (« {word} ») : une photo générique la contredirait."
    for pattern in rules["readableTextPatterns"]:
        if pattern in text or fold(pattern) in folded:
            return "CUSTOM_REAL", f"Texte, écran ou marque précis décrit dans la photo (« {pattern} ») : une photo générique le contredirait."
    key = (scene, fold(photo.get("caption", "")))
    if key in seen:
        return "REPLACE_REAL", f"Même scène et même légende que {seen[key]} : même photo réelle, autre cadrage."
    seen[key] = pid
    return "REPLACE_REAL", "Photo d'ambiance sans rôle dans le raisonnement : vraie photo sous licence libre, recadrée."


def build_queries(case_key: str, photo: dict, cfg: dict) -> tuple[str, list[str]]:
    ctx = cfg["cases"][case_key]
    override = cfg["overrides"].get(f"{case_key}/{photo['id']}")
    scene_cfg = cfg["scenes"].get(photo["scene"], {"query": "", "fallbacks": []})
    base = override or scene_cfg
    fill = lambda q: q.replace("{city}", ctx["city"]).replace("{region}", ctx["region"])
    query = fill(base.get("query", ""))
    fallbacks = [fill(q) for q in base.get("fallbacks", [])]
    if override:
        fallbacks += [fill(q) for q in scene_cfg.get("fallbacks", [])[:1]]
    return query, list(dict.fromkeys(q for q in fallbacks if q and q != query))


def cmd_audit(args, cfg) -> dict:
    """Classifies every photo of every case and groups the API photos into shared sources."""
    old = load_json(CATALOG, {}) or {}
    manual = {p["assetId"]: p for p in old.get("photos", []) if p.get("manual")}
    photos, groups = [], {}
    for case in load_cases():
        case_key = f"{case['number']:03d}"
        ctx = cfg["cases"].get(case_key, {"city": case.get("dossier", {}).get("city", ""), "region": "", "extraPeople": []})
        cfg["cases"].setdefault(case_key, ctx)
        ev_index, usage = evidence_index(case), photo_usage(case)
        names = people_names(case, ctx.get("extraPeople", []))
        planned = (load_json(QUERIES_DIR / f"case_{case_key}.json", {}) or {}).get("photos", {})
        seen: dict = {}
        for dev in case["devices"]:
            for photo in dev["photos"]:
                aid = asset_name(case_key, photo["id"])
                if aid in manual:
                    photos.append(manual[aid])
                    continue
                plan = planned.get(photo["id"])
                if plan:
                    decision = {"REAL": "REPLACE_REAL", "PROCEDURAL": "PROCEDURAL"}.get(plan.get("decision"), "CUSTOM_REAL")
                    reason = plan.get("reason") or ("Vraie photo sous licence libre, choisie pour ce que la photo montre dans l'affaire"
                                                    + (" (preuve : ce qu'elle prouve tient à son heure, son lieu ou son sujet)" if photo["id"] in ev_index else "") + ".")
                    night = bool(plan.get("night")) or is_night(photo, cfg["audit"])
                else:
                    decision, reason = classify(photo, case, ev_index, names, cfg, seen)
                    night = is_night(photo, cfg["audit"])
                if not plan and decision == "REPLACE_REAL":
                    q, _ = build_queries(case_key, photo, cfg)
                    night = night or bool(re.search(r"\b(night|fireworks)\b", q))
                entry = {
                    "assetId": aid, "case": case_key, "caseTitle": case["title"], "photoId": photo["id"],
                    "screens": ["Photos"] + usage.get(photo["id"], []), "scene": photo["scene"],
                    "style": photo.get("style") or "standard", "takenAt": photo.get("takenAt"),
                    "caption": photo.get("caption"), "isEvidence": photo["id"] in ev_index,
                    "decision": decision, "reason": reason, "night": night, "required": decision == "REPLACE_REAL",
                    "currentSource": "procédural (GeneratedPhoto, scène « %s »)" % photo["scene"],
                    "planned": bool(plan),
                }
                if decision == "REPLACE_REAL":
                    if plan:
                        query, fallbacks = plan.get("query", "").strip(), [q for q in plan.get("fallbacks", []) if q.strip()]
                        share = plan.get("shareWith")
                        # Evidence gets its own photograph; the same place/object shown twice shares one
                        # (two crops); ambient photos with the same query share one, as before.
                        gkey = (case_key, "share", share) if share else ((case_key, "own", photo["id"]) if photo["id"] in ev_index else (case_key, query, night))
                    else:
                        query, fallbacks = build_queries(case_key, photo, cfg)
                        gkey = (case_key, query, night)
                    group = groups.get(gkey) or {"query": query, "fallbacks": fallbacks, "night": night, "case": case_key,
                                                  "scene": photo["scene"], "photos": [], "subject": (plan or {}).get("subject", []),
                                                  "evidence": False, "key": gkey}
                    group["evidence"] = group["evidence"] or photo["id"] in ev_index
                    group["photos"].append(aid)
                    groups[gkey] = group
                    entry["shareWith"] = (plan or {}).get("shareWith")
                photos.append(entry)
    # Sources: a group of photos with the same query shares 1 source per `photosPerSource` photos.
    per_source = cfg["selection"]["photosPerSource"]
    sources = []
    assignment = {}
    # A photo shared with another (`shareWith`) joins that one's group.
    for gkey, g in list(groups.items()):
        if gkey[1] == "share":
            owner = next((q for k, q in groups.items() if q and k[1] != "share" and asset_name(gkey[0], gkey[2]) in q["photos"]), None)
            if g and owner:
                owner["photos"] += g["photos"]
                owner["evidence"] = owner["evidence"] or g["evidence"]
                owner["single"] = True  # the same photograph for all of them
            elif g:
                groups[(gkey[0], "own", gkey[2])] = g
            groups.pop(gkey)
    for key, g in sorted(groups.items(), key=lambda kv: tuple(str(x) for x in kv[0])):
        case_key, query, night = g["case"], g["query"], g["night"]
        slug = re.sub(r"[^a-z0-9]+", "_", fold(query)).strip("_")[:40]
        if key[1] == "own":
            slug = f"{slug}_{re.sub(r'[^a-z0-9]+', '_', key[2])}"
        single = key[1] == "own" or g.get("single")
        count = 1 if single else math.ceil(len(g["photos"]) / per_source)
        size = len(g["photos"]) if single else per_source
        for i in range(count):
            sid = f"case{case_key}_src_{slug}{'_night' if night and 'night' not in slug else ''}_{i + 1:02d}"
            members = g["photos"][i * size:(i + 1) * size]
            # Night outdoors must look like night; indoors (a bar, a room) may be lit.
            outdoor_dark = night and (g["scene"] in cfg["audit"]["outdoorScenes"] + ["club", "concert"]
                                      or g["scene"] not in cfg["audit"].get("indoorScenes", []))
            sources.append({
                "id": sid, "case": case_key, "type": "ambient", "usage": "phone-photo", "scene": g["scene"],
                "query": query, "fallbackQueries": g["fallbacks"], "orientation": "landscape", "ratio": "4:3",
                "minWidth": cfg["selection"]["minSourceWidth"], "minHeight": cfg["selection"]["minSourceHeight"],
                "priority": 1 if len(members) > 1 else 2, "providers": cfg["providers"]["order"],
                "sensitivity": "real photograph, no identifiable people, no brands, no AI image", "isEvidence": g["evidence"],
                "subject": g.get("subject", []),
                "night": night, "requireDark": outdoor_dark, "variants": len(members), "photos": members,
                "transform": {"profile": "phone-photo", "crop": "smart", "variantCrops": [VARIANTS[v % len(VARIANTS)][0] for v in range(len(members))]},
            })
            for v, aid in enumerate(members):
                assignment[aid] = (sid, v)
    for p in photos:
        if p["assetId"] in assignment:
            p["source"], p["variant"] = assignment[p["assetId"]]
            p["replacement"] = f"{p['source']} (variante {p['variant'] + 1})"
        elif p["decision"] == "CUSTOM_REAL":
            p["replacement"] = "vraie photo à prendre nous-mêmes ; le rendu procédural reste en attendant"
        elif p["decision"] == "PROCEDURAL":
            p["replacement"] = "aucun : rendu procédural conservé"
    catalog = {
        "about": "Generated by `scripts/photos.sh audit` from the case files, then editable: set \"manual\": true on a photo entry to keep your edits. One entry per photo of the game; ambient photos share `sources`.",
        "version": 2, "sources": sources, "photos": photos, "removedImages": cfg.get("removedImages", []),
    }
    if not args.dry_run:
        write_json(CATALOG, catalog)
        write_audit_doc(catalog)
    counts = {d: sum(1 for p in photos if p["decision"] == d) for d in DECISIONS}
    log(f"audit: {len(photos)} photos → {counts} · {len(sources)} sources")
    return catalog


# ─────────────────────────────────────────────────────────── providers

class RateLimited(Exception):
    pass


class Http:
    def __init__(self, cfg: dict, stats: dict):
        self.cfg, self.stats = cfg, stats
        self.last: dict[str, float] = {}
        self.disabled: dict[str, str] = {}

    def get_json(self, provider: str, url: str, headers: dict, min_interval: float):
        if provider in self.disabled:
            raise RateLimited(self.disabled[provider])
        net = self.cfg["network"]
        for attempt in range(net["retries"]):
            wait = min_interval - (time.time() - self.last.get(provider, 0))
            if wait > 0:
                time.sleep(wait)
            self.last[provider] = time.time()
            req = urllib.request.Request(url, headers={"User-Agent": net["userAgent"], **headers})
            try:
                self.stats["requests"][provider] = self.stats["requests"].get(provider, 0) + 1
                with urllib.request.urlopen(req, timeout=net["timeoutSeconds"]) as resp:
                    return json.loads(resp.read().decode("utf-8"))
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    retry = int(e.headers.get("Retry-After", "0") or 0)
                    if retry > 120 or attempt == net["retries"] - 1:
                        self.disabled[provider] = f"429 (rate limit) — retry after {retry or '?'} s"
                        raise RateLimited(self.disabled[provider])
                    time.sleep(max(retry, net["backoffSeconds"] * (attempt + 1)))
                    continue
                if e.code in (401, 403):
                    self.disabled[provider] = f"HTTP {e.code} (key or access refused)"
                    raise RateLimited(self.disabled[provider])
                if attempt == net["retries"] - 1:
                    raise
                time.sleep(net["backoffSeconds"] * (attempt + 1))
            except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
                if attempt == net["retries"] - 1:
                    self.disabled[provider] = f"network unavailable ({e})"
                    raise RateLimited(self.disabled[provider])
                time.sleep(net["backoffSeconds"] * (attempt + 1))
        return None

    def download(self, url: str, dest: Path) -> bool:
        net = self.cfg["network"]
        for attempt in range(net["retries"]):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": net["userAgent"]})
                with urllib.request.urlopen(req, timeout=net["timeoutSeconds"] * 2) as resp:
                    data = resp.read()
                if len(data) < 10_000:
                    return False
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
                self.stats["downloads"] = self.stats.get("downloads", 0) + 1
                return True
            except Exception:  # noqa: BLE001 — any failure: try again, then give up on this candidate
                time.sleep(net["backoffSeconds"] * (attempt + 1))
        return False


def cache_path(provider: str, query: str, extra: str = "") -> Path:
    h = hashlib.sha1(f"{query}|{extra}".encode()).hexdigest()[:16]
    slug = re.sub(r"[^a-z0-9]+", "-", fold(query))[:40]
    return CACHE / "search" / provider / f"{slug}-{h}.json"


def pexels_search(http: Http, cfg: dict, query: str, offline: bool) -> list[dict]:
    pcfg = cfg["providers"]["pexels"]
    key = os.environ.get(pcfg["apiKeyEnv"], "").strip()
    cpath = cache_path("pexels", query, "landscape")
    cached = load_json(cpath)
    if cached is not None:
        http.stats["cacheHits"] = http.stats.get("cacheHits", 0) + 1
        return cached
    if not pcfg["enabled"] or not key or offline:
        return []
    url = pcfg["endpoint"] + "?" + urllib.parse.urlencode({"query": query, "orientation": "landscape", "per_page": pcfg["perPage"], "page": 1})
    data = http.get_json("pexels", url, {"Authorization": key}, pcfg["minIntervalSeconds"])
    if data is None:
        return []  # a failed request is not cached: the next run asks again
    results = []
    for p in data.get("photos", []):
        results.append({
            "provider": "pexels", "providerPhotoId": str(p["id"]), "width": p["width"], "height": p["height"],
            "title": p.get("alt") or "", "tags": [], "photographer": p.get("photographer") or "",
            "photographerUrl": p.get("photographer_url") or "", "sourceUrl": p.get("url") or "",
            "downloadUrl": (p.get("src") or {}).get(pcfg["download"]) or (p.get("src") or {}).get("large"),
            "avgColor": p.get("avg_color"), "license": pcfg["license"], "licenseUrl": pcfg["licenseUrl"],
            "licenseCode": "pexels", "mature": False,
        })
    write_json(cpath, results)
    return results


def openverse_search(http: Http, cfg: dict, query: str, offline: bool) -> list[dict]:
    ocfg = cfg["providers"]["openverse"]
    cpath = cache_path("openverse", query, ocfg["licenseType"])
    cached = load_json(cpath)
    if cached is not None:
        http.stats["cacheHits"] = http.stats.get("cacheHits", 0) + 1
        return cached
    if not ocfg["enabled"] or offline:
        return []
    params = {"q": query, "license_type": ocfg["licenseType"], "mature": "false", "page_size": ocfg["pageSize"],
              "aspect_ratio": "wide", "size": "large"}
    url = ocfg["endpoint"] + "?" + urllib.parse.urlencode(params)
    data = http.get_json("openverse", url, {}, ocfg["minIntervalSeconds"])
    if data is None:
        return []  # a failed request is not cached: the next run asks again
    results = []
    for r in data.get("results", []):
        results.append({
            "provider": "openverse", "providerPhotoId": r.get("id", ""), "width": r.get("width") or 0,
            "height": r.get("height") or 0, "title": clean_title(r.get("title") or ""),
            "tags": [t.get("name", "") for t in (r.get("tags") or [])], "photographer": r.get("creator") or "",
            "photographerUrl": r.get("creator_url") or "", "sourceUrl": r.get("foreign_landing_url") or "",
            "downloadUrl": r.get("url") or "", "license": (r.get("license") or "").lower(),
            "licenseVersion": r.get("license_version") or "", "licenseUrl": r.get("license_url") or "",
            "licenseCode": (r.get("license") or "").lower(), "origin": r.get("source") or r.get("provider") or "",
            "attribution": r.get("attribution") or "", "mature": bool(r.get("mature")),
        })
    write_json(cpath, results)
    return results


WIKI_LICENCES = [  # Commons « LicenseShortName » → our licence code (anything else is refused)
    (re.compile(r"^cc0\b|^cc-zero", re.I), "cc0"),
    (re.compile(r"^public domain|^pd\b|^pdm", re.I), "pdm"),
    (re.compile(r"^cc[ -]by[ -]sa[ -]?(\d(\.\d)?)?", re.I), "by-sa"),
    (re.compile(r"^cc[ -]by[ -]?(\d(\.\d)?)?$", re.I), "by"),
]


def strip_html(text: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", text or ""))).strip()


def wikimedia_licence(short_name: str) -> tuple[str, str]:
    """(code, version) of a Commons licence name, ("", "") when it is not one we accept."""
    name = (short_name or "").strip()
    for pattern, code in WIKI_LICENCES:
        if pattern.search(name):
            version = re.search(r"(\d\.\d|\d)", name)
            return code, (version.group(1) if version and code in ("by", "by-sa") else "")
    return "", ""


def wikimedia_search(http: Http, cfg: dict, query: str, offline: bool) -> list[dict]:
    """Wikimedia Commons, official MediaWiki API: JPEG files matching the query, with their licence,
    author, categories and date (extmetadata). No key needed; one request per query."""
    wcfg = cfg["providers"]["wikimedia"]
    cpath = cache_path("wikimedia", query, "v1")
    cached = load_json(cpath)
    if cached is not None:
        http.stats["cacheHits"] = http.stats.get("cacheHits", 0) + 1
        return cached
    if not wcfg["enabled"] or offline:
        return []
    params = {"action": "query", "format": "json", "formatversion": "2", "generator": "search",
              "gsrsearch": f"{query} filemime:image/jpeg", "gsrnamespace": "6", "gsrlimit": wcfg["pageSize"],
              "prop": "imageinfo", "iiprop": "url|size|mime|extmetadata", "iiurlwidth": wcfg["thumbWidth"],
              "iiextmetadatafilter": "LicenseShortName|LicenseUrl|Artist|ImageDescription|DateTimeOriginal|Restrictions|Categories|ObjectName"}
    data = http.get_json("wikimedia", wcfg["endpoint"] + "?" + urllib.parse.urlencode(params), {}, wcfg["minIntervalSeconds"])
    if data is None:
        return []
    results = []
    for page in (data.get("query") or {}).get("pages", []):
        info = (page.get("imageinfo") or [{}])[0]
        meta = {k: str((v or {}).get("value", "") if isinstance(v, dict) else v or "") for k, v in (info.get("extmetadata") or {}).items()}
        code, version = wikimedia_licence(strip_html(meta.get("LicenseShortName", "")))
        categories = [c.strip() for c in strip_html(meta.get("Categories", "")).split("|") if c.strip()]
        year = re.search(r"(1[89]\d\d|20\d\d)", strip_html(meta.get("DateTimeOriginal", "")))
        artist = strip_html(meta.get("Artist", ""))
        results.append({
            "provider": "wikimedia", "providerPhotoId": str(page.get("pageid", "")), "width": info.get("width") or 0,
            "height": info.get("height") or 0, "title": clean_title(meta.get("ObjectName") or page.get("title", "")),
            "tags": categories[:40] + [strip_html(meta.get("ImageDescription", ""))[:300]],
            "photographer": artist[:120], "photographerUrl": "", "sourceUrl": info.get("descriptionurl") or "",
            "downloadUrl": info.get("thumburl") or info.get("url") or "", "license": code, "licenseVersion": version,
            "licenseUrl": meta.get("LicenseUrl", "") or ("https://creativecommons.org/publicdomain/zero/1.0/" if code == "cc0" else
                                                          "https://commons.wikimedia.org/wiki/Commons:Public_domain" if code == "pdm" else ""),
            "licenseCode": code, "origin": "Wikimedia Commons", "mature": False, "mime": info.get("mime", ""),
            "year": int(year.group(1)) if year else None, "restrictions": strip_html(meta.get("Restrictions", "")),
        })
    write_json(cpath, results)
    return results


def search_provider(provider: str, http: Http, cfg: dict, query: str, offline: bool) -> list[dict]:
    if provider == "pexels":
        return pexels_search(http, cfg, query, offline)
    if provider == "wikimedia":
        return wikimedia_search(http, cfg, query, offline)
    return openverse_search(http, cfg, query, offline)


def hex_luminance(hex_color: str | None) -> float | None:
    if not hex_color or not re.match(r"^#?[0-9a-fA-F]{6}$", hex_color):
        return None
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def licence_ok(c: dict, cfg: dict) -> tuple[bool, str]:
    if c["provider"] == "pexels":
        return True, ""
    ocfg = cfg["providers"]["wikimedia" if c["provider"] == "wikimedia" else "openverse"]
    code = c.get("licenseCode", "")
    if code not in ocfg["allowedLicenses"]:
        return False, f"licence « {code or '?'} » non autorisée (usage commercial + modification requis)"
    if not c.get("licenseUrl") or not c.get("sourceUrl"):
        return False, "licence ou page source manquante"
    if code in ocfg["attributionRequiredFor"] and not c.get("photographer"):
        return False, "auteur inconnu pour une licence qui exige l'attribution"
    return True, ""


def hard_reject(c: dict, cfg: dict) -> str:
    """Why a candidate (or an image already fetched) can never be used; "" when it can."""
    sel = cfg["selection"]
    words = tokens(clean_title(c.get("title", "")) + " " + " ".join(c.get("tags", [])))
    if f"{c['provider']}:{c['providerPhotoId']}" in sel.get("excluded", []):
        return "image refusée à la relecture (selection.excluded)"
    if any(w in words for w in sel["rejectWords"]):
        return "mot exclu dans le titre ou les tags"
    if words & set(sel.get("placeRejectWords", [])):
        return "lieu étranger à l'affaire (placeRejectWords)"
    if words & set(sel.get("strongPeopleWords", [])):
        return "personne identifiable au centre de l'image (strongPeopleWords)"
    text = " " + fold(clean_title(c.get("title", "")) + " " + " ".join(c.get("tags", []))) + " "
    for phrase in sel.get("aiPhrases", []):
        if f" {fold(phrase)} " in re.sub(r"[^a-z0-9]+", " ", text) + " ":
            return "image générée par IA (jamais dans le jeu)"
    for phrase in sel.get("notPhotoPhrases", []):
        if f" {fold(phrase)} " in re.sub(r"[^a-z0-9]+", " ", text) + " ":
            return "pas une photographie (dessin, carte, affiche, rendu…)"
    if c.get("mime") and c["mime"] != "image/jpeg":
        return "pas une photographie JPEG"
    if c.get("year") and c["year"] < sel.get("minYear", 2000):
        return f"photo ancienne ({c['year']}) : pas crédible dans un téléphone récent"
    if "personality" in fold(c.get("restrictions", "")):
        return "personne identifiable (droit à l'image signalé)"
    return ""


def subject_words(source: dict, query: str, cfg: dict) -> set[str]:
    """What the photo must show: the query without the city, the time of day and filler words."""
    if source.get("subject"):
        return set().union(*(tokens(w) for w in source["subject"]))
    case = cfg["cases"].get(source.get("case", ""), {})
    place = tokens(case.get("city", "") + " " + case.get("region", ""))
    return tokens(query) - place - set(cfg["selection"].get("fillerWords", []))


def score(c: dict, source: dict, cfg: dict, query: str | None = None) -> tuple[float, str]:
    """Score of a candidate for a source; (−inf, reason) when rejected."""
    sel = cfg["selection"]
    words = tokens(c.get("title", "") + " " + " ".join(c.get("tags", [])))
    ok, why = licence_ok(c, cfg)
    if not ok:
        return -math.inf, why
    why = hard_reject(c, cfg)
    if why:
        return -math.inf, why
    if c.get("mature"):
        return -math.inf, "contenu signalé sensible"
    if not c.get("downloadUrl"):
        return -math.inf, "pas d'URL de téléchargement"
    subject = subject_words(source, query or source["query"], cfg)
    if subject and not (subject & words):
        return -math.inf, "le sujet demandé n'apparaît ni dans le titre ni dans les tags"
    w, h = c.get("width") or 0, c.get("height") or 0
    if w < source["minWidth"] or h < source["minHeight"]:
        return -math.inf, f"résolution trop faible ({w}×{h})"
    s = 0.0
    q = tokens(source["query"])
    if q:
        s += 3 * len(q & words) / len(q)
    s += 1.0 if w >= source["minWidth"] * 1.5 else 0.4
    ratio = w / h if h else 0
    s += 1.5 if ratio >= 1.2 else -2.0
    s -= min(1.5, abs(ratio - 4 / 3))
    if words & set(sel["peopleWords"]):
        s -= 3.0
    if words & set(sel["brandWords"]):
        s -= 2.0
    lum = hex_luminance(c.get("avgColor"))
    if source["night"]:
        s += 1.5 if words & set(sel["nightWords"]) else 0
        s -= 2.0 if words & set(sel["dayWords"]) else 0
        if lum is not None:
            s += 1.5 if lum < 0.35 else (-2.5 if lum > 0.6 else 0)
    else:
        s -= 1.0 if words & {"night", "dark", "neon"} else 0
    if c["provider"] == "pexels":
        s += 0.5  # consistent quality, no attribution ambiguity
    if source.get("isEvidence") and words & set(sel["peopleWords"]):
        return -math.inf, "une preuve ne montre jamais de personne identifiable"
    return s, ""


# ─────────────────────────────────────────────────────────── search / download

def cmd_search(args, cfg, catalog, manifest, stats) -> None:
    """Chooses candidates for every source that has none yet (the manifest is the lock file)."""
    http = Http(cfg, stats)
    for e in manifest.get("sources", []):
        if e.get("status") == "fetched":
            why = hard_reject(e, cfg)
            if why:
                log(f"  {e['sourceId']}: {e['provider']}:{e['providerPhotoId']} retiré — {why}")
                e.update(status="rejected", reason=why)
    locked = {e["sourceId"] for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    used = {(e["provider"], e["providerPhotoId"]) for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    selection = load_json(CACHE / "selection.json", {}) or {}
    plan_lines = []
    for src in catalog["sources"]:
        if src["id"] in locked:
            continue
        ranked, rejected, reasons, seen = [], 0, {}, 0
        for query in [src["query"]] + src["fallbackQueries"]:
            for provider in src["providers"]:
                try:
                    results = search_provider(provider, http, cfg, query, args.offline)
                except RateLimited as e:
                    stats["errors"].append(f"{provider}: {e}")
                    results = []
                except Exception as e:  # noqa: BLE001
                    stats["errors"].append(f"{provider} « {query} »: {e}")
                    results = []
                for c in results:
                    if (c["provider"], c["providerPhotoId"]) in used:
                        continue
                    seen += 1
                    sc, why = score(c, src, cfg, query)
                    if sc == -math.inf or sc < cfg["selection"]["minScore"]:
                        rejected += 1
                        why = why or "score trop bas"
                        reasons[why] = reasons.get(why, 0) + 1
                        continue
                    ranked.append({**c, "score": round(sc, 2), "queryUsed": query})
            if len(ranked) >= cfg["selection"]["candidatesToTry"]:
                break
        ranked.sort(key=lambda c: -c["score"])
        ranked = ranked[:cfg["selection"]["candidatesToTry"]]
        stats["rejected"] += rejected
        if not ranked:
            detail = ", ".join(f"{n} × {why}" for why, n in sorted(reasons.items(), key=lambda kv: -kv[1]))
            stats.setdefault("why", {})[src["id"]] = f"aucun candidat acceptable sur {seen} résultat(s)" + (f" ({detail})" if detail else "")
        selection[src["id"]] = ranked
        if ranked:
            used.add((ranked[0]["provider"], ranked[0]["providerPhotoId"]))
        best = ranked[0] if ranked else None
        plan_lines.append(f"- `{src['id']}` « {src['query']} » → " + (f"{best['provider']} {best['providerPhotoId']} ({best['score']}) « {best['title'][:60]} »" if best else "aucun candidat"))
    if not args.dry_run:
        write_json(CACHE / "selection.json", selection)
    stats["plan"] = plan_lines
    log(f"search: {sum(1 for s in catalog['sources'] if selection.get(s['id']))}/{len(catalog['sources'])} sources with candidates")


def image_luminance(path: Path) -> float:
    from PIL import Image, ImageStat
    with Image.open(path) as im:
        small = im.convert("L").resize((64, 48))
        return ImageStat.Stat(small).mean[0]


def cmd_download(args, cfg, catalog, manifest, stats) -> None:
    """Downloads the best candidate of each source, checks it (night photos really dark), locks it."""
    http = Http(cfg, stats)
    selection = load_json(CACHE / "selection.json", {}) or {}
    entries = {e["sourceId"]: e for e in manifest.get("sources", [])}
    taken = {(e["provider"], e["providerPhotoId"]): e["sourceId"] for e in entries.values() if e.get("status") == "fetched"}
    for src in catalog["sources"]:
        current = entries.get(src["id"])
        if current and current.get("status") == "fetched" and (CACHE / "originals" / current["file"]).exists():
            continue
        if current and current.get("status") == "fetched" and args.offline:
            continue
        tried = 0
        for cand in selection.get(src["id"], []):
            if taken.get((cand["provider"], cand["providerPhotoId"]), src["id"]) != src["id"]:
                continue  # already the image of another source: two phones never share a photo
            fname = f"{cand['provider']}_{re.sub(r'[^A-Za-z0-9-]', '', cand['providerPhotoId'])}.jpg"
            dest = CACHE / "originals" / fname
            if args.dry_run:
                log(f"  [dry-run] {src['id']} ← {cand['downloadUrl']}")
                break
            if not dest.exists():
                if args.offline or not http.download(cand["downloadUrl"], dest):
                    tried += 1
                    continue
            lum = image_luminance(dest)
            if src["requireDark"] and lum > cfg["selection"]["darkMaxLuminance"]:
                stats["rejected"] += 1
                log(f"  {src['id']}: {fname} rejeté — trop clair pour une photo de nuit (luminance {lum:.0f})")
                continue
            if not src["night"] and lum < cfg["selection"]["dayMinLuminance"]:
                stats["rejected"] += 1
                log(f"  {src['id']}: {fname} rejeté — trop sombre pour une photo de jour (luminance {lum:.0f})")
                continue
            entries[src["id"]] = {
                "sourceId": src["id"], "status": "fetched", "case": src["case"], "provider": cand["provider"],
                "providerPhotoId": cand["providerPhotoId"], "photographer": cand.get("photographer", ""),
                "photographerUrl": cand.get("photographerUrl", ""), "sourceUrl": cand.get("sourceUrl", ""),
                "downloadUrl": cand.get("downloadUrl", ""), "license": cand.get("license", ""),
                "licenseVersion": cand.get("licenseVersion", ""), "licenseUrl": cand.get("licenseUrl", ""),
                "origin": cand.get("origin", "pexels.com" if cand["provider"] == "pexels" else ""),
                "title": clean_title(cand.get("title", "")), "tags": cand.get("tags", [])[:20], "queryUsed": cand.get("queryUsed", src["query"]),
                "dateFetched": now_iso(), "width": cand.get("width"), "height": cand.get("height"),
                "score": cand.get("score"), "luminance": round(lum, 1), "file": fname,
                "sha256": hashlib.sha256(dest.read_bytes()).hexdigest(),
                "attributionRequired": cand["provider"] == "openverse" and cand.get("licenseCode") in cfg["providers"]["openverse"]["attributionRequiredFor"],
                "attributionText": attribution_text(cand),
                "evidence": False,
            }
            taken[(cand["provider"], cand["providerPhotoId"])] = src["id"]
            break
        else:
            if not args.dry_run and (src["id"] not in entries or entries[src["id"]].get("status") != "fetched"):
                entries[src["id"]] = {"sourceId": src["id"], "status": "missing", "case": src["case"],
                                      "reason": stats.get("why", {}).get(src["id"], "aucun candidat acceptable") if not selection.get(src["id"]) else f"{tried} téléchargement(s) échoué(s) ou rejeté(s)"}
    manifest["sources"] = [entries[s["id"]] for s in catalog["sources"] if s["id"] in entries]
    fetched = sum(1 for e in manifest["sources"] if e.get("status") == "fetched")
    log(f"download: {fetched}/{len(catalog['sources'])} sources fetched")


def attribution_text(c: dict) -> str:
    c = {**c, "title": clean_title(c.get("title", ""))}
    who = c.get("photographer") or "auteur inconnu"
    if c["provider"] == "pexels":
        return f"Photo by {who} on Pexels"
    lic = (c.get("licenseCode") or "").upper()
    if lic in ("CC0", "PDM"):
        via = ", Wikimedia Commons" if c["provider"] == "wikimedia" else ""
        return f"« {c.get('title') or 'Sans titre'} » — {who} ({'domaine public' if lic == 'PDM' else lic}{via})"
    via = " — Wikimedia Commons" if c["provider"] == "wikimedia" else ""
    return f"« {c.get('title') or 'Sans titre'} » by {who}, CC {lic} {c.get('licenseVersion', '')}".strip() + via


# ─────────────────────────────────────────────────────────── process

def smart_box(im, target_ratio: float, zoom: float, side: str):
    """Crop window of `target_ratio`, `zoom` times smaller than the largest one, placed where the
    image has the most detail (edge energy) — within the left, right or whole range for variants."""
    from PIL import ImageFilter
    W, H = im.size
    if W / H > target_ratio:
        cw, ch = H * target_ratio, H
    else:
        cw, ch = W, W / target_ratio
    cw, ch = cw / zoom, ch / zoom
    small = im.convert("L").resize((96, max(1, int(96 * H / W))))
    edges = small.filter(ImageFilter.FIND_EDGES)
    sw, sh = edges.size
    px = edges.load()
    col = [sum(px[x, y] for y in range(sh)) for x in range(sw)]
    row = [sum(px[x, y] for x in range(sw)) for y in range(sh)]

    def best(profile, full, window, lo, hi):
        n = len(profile)
        win = max(1, int(round(n * window / full)))
        start_min, start_max = int(lo * (n - win)), int(hi * (n - win))
        best_s, best_v = start_min, -1
        for s0 in range(start_min, max(start_min, start_max) + 1):
            v = sum(profile[s0:s0 + win])
            # A light pull toward the centre, so the subject is rarely cut at the edge.
            v *= 1 - 0.15 * abs((s0 + win / 2) / n - 0.5)
            if v > best_v:
                best_s, best_v = s0, v
        return best_s * full / n

    lo, hi = {"best": (0, 1), "left": (0, 0.45), "right": (0.55, 1)}[side]
    x = best(col, W, cw, lo, hi)
    # Vertically: keep the horizon — never the extreme top or bottom band only.
    y = best(row, H, ch, 0.15, 0.85) if ch < H else 0
    x, y = max(0, min(W - cw, x)), max(0, min(H - ch, y))
    return (int(x), int(y), int(x + cw), int(y + ch))


VARIANTS = [("best", 1.0), ("left", 1.2), ("right", 1.2)]


def xcasset_dir(aid: str) -> Path:
    return PHOTOS_XCASSETS / f"{aid}.imageset"


def cmd_process(args, cfg, catalog, manifest, stats) -> None:
    from PIL import Image, ImageOps
    prof = cfg["profiles"]["phone-photo"]
    by_source = {e["sourceId"]: e for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    assets = {a["assetId"]: a for a in manifest.get("assets", [])}
    produced = 0
    for p in catalog["photos"]:
        src_id = p.get("source")
        if not src_id or src_id not in by_source:
            continue
        entry = by_source[src_id]
        original = CACHE / "originals" / entry["file"]
        side, zoom = VARIANTS[p.get("variant", 0) % len(VARIANTS)]
        transform = {"profile": "phone-photo", "width": prof["width"], "height": prof["height"], "quality": prof["quality"],
                     "crop": side, "zoom": zoom, "source": entry["file"], "sourceSha256": entry["sha256"]}
        out_dir = xcasset_dir(p["assetId"])
        out_file = out_dir / f"{p['assetId']}.jpg"
        prev = assets.get(p["assetId"])
        if prev and prev.get("transformation") == transform and out_file.exists():
            continue
        if not original.exists():
            stats["errors"].append(f"{p['assetId']}: original manquant ({entry['file']}) — relancer download")
            continue
        if args.dry_run:
            log(f"  [dry-run] {p['assetId']} ← {entry['file']} ({side}, ×{zoom})")
            continue
        with Image.open(original) as im:
            im = ImageOps.exif_transpose(im).convert("RGB")
            box = smart_box(im, prof["width"] / prof["height"], zoom, side)
            transform["box"] = list(box)
            out = im.crop(box).resize((prof["width"], prof["height"]), Image.LANCZOS)
            out_dir.mkdir(parents=True, exist_ok=True)
            out.save(out_file, "JPEG", quality=prof["quality"], optimize=True, progressive=True)
        write_json(out_dir / "Contents.json", {"images": [{"filename": out_file.name, "idiom": "universal"}],
                                               "info": {"author": "xcode", "version": 1}})
        assets[p["assetId"]] = {
            "assetId": p["assetId"], "sourceId": src_id, "caseId": p["case"], "photoId": p["photoId"],
            "evidence": bool(p.get("isEvidence")), "finalAssetPath": str(out_file.relative_to(ROOT)), "transformation": transform,
            "sha256": hashlib.sha256(out_file.read_bytes()).hexdigest(), "bytes": out_file.stat().st_size,
        }
        produced += 1
    # Assets whose source disappeared from the catalog are removed (never a hand-made asset: this
    # group only holds pipeline output).
    wanted = {p["assetId"] for p in catalog["photos"] if p.get("source") in by_source}
    for aid in list(assets):
        if aid not in wanted:
            if not args.dry_run and xcasset_dir(aid).exists():
                for f in xcasset_dir(aid).iterdir():
                    f.unlink()
                xcasset_dir(aid).rmdir()
            assets.pop(aid)
    manifest["assets"] = sorted(assets.values(), key=lambda a: a["assetId"])
    if not args.dry_run:
        write_json(PHOTOS_XCASSETS / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    log(f"process: {produced} image(s) written, {len(manifest['assets'])} in the catalogue")


# ─────────────────────────────────────────────────────────── validate / report

KEY_PATTERN = re.compile(r"(PEXELS_API_KEY)\s*[:=]\s*['\"]?([A-Za-z0-9]{20,})")


def cmd_validate(args, cfg, catalog, manifest, stats) -> list[str]:
    problems = []
    prof = cfg["profiles"]["phone-photo"]
    ids = [p["assetId"] for p in catalog["photos"]]
    if len(ids) != len(set(ids)):
        problems.append("catalogue : identifiants en double")
    for p in catalog["photos"]:
        if p["decision"] not in DECISIONS:
            problems.append(f"{p['assetId']}: décision inconnue {p['decision']}")
        if p["isEvidence"] and p["decision"] == "REPLACE_REAL" and not p.get("planned"):
            problems.append(f"{p['assetId']}: une preuve ne vient d'une bibliothèque que si config/photo_queries la décrit")
    for s in catalog["sources"]:
        if not s["query"].strip():
            problems.append(f"{s['id']}: source sans requête")
    sources = {e["sourceId"]: e for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    for e in sources.values():
        for field in ("provider", "providerPhotoId", "sourceUrl", "license", "licenseUrl", "queryUsed", "dateFetched", "attributionText"):
            if not e.get(field):
                problems.append(f"{e['sourceId']}: provenance incomplète ({field})")
        if e["provider"] in ("openverse", "wikimedia") and e.get("license") not in cfg["providers"][e["provider"]]["allowedLicenses"]:
            problems.append(f"{e['sourceId']}: licence non autorisée {e.get('license')}")
    hashes = {}
    try:
        from PIL import Image
    except ImportError:
        Image = None
    for a in manifest.get("assets", []):
        path = ROOT / a["finalAssetPath"]
        if not path.exists():
            problems.append(f"{a['assetId']}: fichier absent {a['finalAssetPath']}")
            continue
        if a["sourceId"] not in sources:
            problems.append(f"{a['assetId']}: source sans provenance {a['sourceId']}")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest in hashes:
            problems.append(f"{a['assetId']}: doublon exact de {hashes[digest]}")
        hashes[digest] = a["assetId"]
        if Image:
            with Image.open(path) as im:
                if im.size != (prof["width"], prof["height"]) or im.format != "JPEG":
                    problems.append(f"{a['assetId']}: {im.format} {im.size}, attendu JPEG {prof['width']}×{prof['height']}")
    # Every asset folder of the Photos group belongs to the manifest (no orphan, no dead reference).
    listed = {a["assetId"] for a in manifest.get("assets", [])}
    if PHOTOS_XCASSETS.exists():
        for d in PHOTOS_XCASSETS.glob("*.imageset"):
            if d.name[:-len(".imageset")] not in listed:
                problems.append(f"{d.name}: image sans entrée dans le manifeste")
    # No API key committed anywhere.
    for path in ROOT.rglob("*"):
        if path.is_file() and path.suffix in (".json", ".py", ".sh", ".yml", ".yaml", ".md", ".swift", ".xcconfig", ".plist", ".txt", ".env") \
                and ".git" not in path.parts and "cache" not in path.parts and ".build" not in path.parts:
            try:
                if KEY_PATTERN.search(path.read_text(encoding="utf-8", errors="ignore")):
                    problems.append(f"{path.relative_to(ROOT)}: clé d'API en clair")
            except OSError:
                pass
    stats["validated"] = len(manifest.get("assets", [])) if not problems else 0
    for p in problems:
        log(f"  ✗ {p}")
    log(f"validate: {'OK' if not problems else f'{len(problems)} problème(s)'}")
    return problems


def credits_payload(manifest: dict) -> dict:
    used = {}
    for a in manifest.get("assets", []):
        used.setdefault(a["sourceId"], []).append(a["assetId"])
    items = []
    for e in manifest.get("sources", []):
        if e.get("status") != "fetched" or e["sourceId"] not in used:
            continue
        items.append({
            "provider": e["provider"], "photographer": e.get("photographer", ""),
            "photographerUrl": e.get("photographerUrl", ""), "sourceUrl": e.get("sourceUrl", ""),
            "license": ("Pexels License" if e["provider"] == "pexels" else f"{e.get('license', '').upper()} {e.get('licenseVersion', '')}".strip()),
            "licenseUrl": e.get("licenseUrl", ""), "title": e.get("title", ""), "attribution": e.get("attributionText", ""),
            "cases": sorted({a.split("_photo_")[0].replace("case", "") for a in used[e["sourceId"]]}),
        })
    items.sort(key=lambda i: (i["provider"], i["photographer"].lower()))
    return {"about": "Generated by scripts/photos/pipeline.py (report). Shown in Paramètres › À propos › Crédits photos.",
            "pexels": any(i["provider"] == "pexels" for i in items), "items": items}


def compliance_lines(catalog: dict, manifest: dict) -> list[str]:
    """REAL PHOTO COMPLIANCE: what the phones show, photo by photo category."""
    photos = catalog["photos"]
    shipped = {a["assetId"] for a in manifest.get("assets", [])}
    sources = {e["sourceId"]: e for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    by_provider: dict[str, int] = {}
    for a in manifest.get("assets", []):
        prov = sources.get(a["sourceId"], {}).get("provider", "?")
        by_provider[prov] = by_provider.get(prov, 0) + 1
    real = [p for p in photos if p["assetId"] in shipped]
    waiting = [p for p in photos if p["decision"] == "REPLACE_REAL" and p["assetId"] not in shipped]
    custom = [p for p in photos if p["decision"] == "CUSTOM_REAL"]
    procedural = [p for p in photos if p["decision"] == "PROCEDURAL"]
    removed = catalog.get("removedImages", [])
    lines = ["## REAL PHOTO COMPLIANCE", "",
             "Règle du studio : aucune image générée par IA dans les téléphones et les galeries ; toute photo montrée comme une "
             "photographie est une vraie photographie (bibliothèque libre documentée, ou prise par nous).", "",
             "| | |", "|---|---|",
             f"| Photos des téléphones (toutes affaires) | {len(photos)} |",
             f"| Vraies photos livrées (photographies réelles) | **{len(real)}** |",
             f"| — dont externes : " + " · ".join(f"{k} {v}" for k, v in sorted(by_provider.items())) + f" | {len(real)} |",
             f"| Vraies photos prises par le studio (CUSTOM_REAL livrées) | 0 |",
             f"| Vraies photos encore à récupérer (REPLACE_REAL sans image acceptable pour l'instant) | {len(waiting)} |",
             f"| Vraies photos à prendre nous-mêmes (CUSTOM_REAL) | {len(custom)} |",
             f"| Rendus du jeu voulus (captures d'écran, documents, tickets — pas des photographies) | {len(procedural)} |",
             f"| Images IA supprimées | {len(removed)} |",
             f"| Images IA restantes dans les zones photo | 0 |", ""]
    if removed:
        lines += ["Images IA supprimées :", ""] + [f"- `{r['name']}` — {r['what']} ({r['why']})" for r in removed] + [""]
    lines += ["Tant qu'une vraie photo n'est pas livrée, le téléphone montre un rendu dessiné par le jeu, stylisé, qui ne se "
              "fait pas passer pour une photographie réelle (aucune image IA n'est jamais utilisée).", ""]
    exceptions = custom + waiting
    if exceptions:
        lines += ["Exceptions (photo réelle pas encore livrée) :", "", "| Photo | Décision | Justification |", "|---|---|---|"]
        for p in exceptions:
            lines.append(f"| `{p['assetId']}` — {str(p.get('caption', '')).replace('|', '/')} | {p['decision']} | {p['reason'].replace('|', '/')} |")
        lines.append("")
    return lines


def write_audit_doc(catalog: dict, manifest: dict | None = None) -> None:
    photos = catalog["photos"]
    manifest = manifest if manifest is not None else (load_json(MANIFEST, {}) or {})
    lines = ["# Audit des photos du jeu", "",
             "Généré par `./scripts/photos.sh audit` à partir des affaires (`ScreenshotKit/Sources/CaseLibrary/Resources/Cases`, "
             "mode principal et ALIBI) et des fiches `config/photo_queries/case_NNN.json`.",
             "Ne pas éditer à la main : modifier les fiches de requêtes ou `config/photo_pipeline.json`, ou marquer une entrée "
             "`\"manual\": true` dans `config/photo_catalog.json`, puis relancer.",
             "", "## Synthèse", "", "| Affaire | Photos | KEEP_REAL | REPLACE_REAL | CUSTOM_REAL | PROCEDURAL | REMOVE | Sources |", "|---|---|---|---|---|---|---|---|"]
    by_case = {}
    for p in photos:
        by_case.setdefault((p["case"], p["caseTitle"]), []).append(p)
    for (case, title), ps in sorted(by_case.items()):
        c = {d: sum(1 for p in ps if p["decision"] == d) for d in DECISIONS}
        n_src = sum(1 for s in catalog["sources"] if s["case"] == case)
        label = f"ALIBI #{int(case) - 100:03d}" if int(case) > 100 else f"#{case}"
        lines.append(f"| {label} {title} | {len(ps)} | {c['KEEP_REAL']} | {c['REPLACE_REAL']} | {c['CUSTOM_REAL']} | {c['PROCEDURAL']} | {c['REMOVE']} | {n_src} |")
    tot = {d: sum(1 for p in photos if p["decision"] == d) for d in DECISIONS}
    lines.append(f"| **Total** | **{len(photos)}** | **{tot['KEEP_REAL']}** | **{tot['REPLACE_REAL']}** | **{tot['CUSTOM_REAL']}** | **{tot['PROCEDURAL']}** | **{tot['REMOVE']}** | **{len(catalog['sources'])}** |")
    lines += ["", "Décisions :", "",
              "- **KEEP_REAL** — vraie photographie déjà livrée, provenance documentée, conservée.",
              "- **REPLACE_REAL** — vraie photographie d'une bibliothèque libre (Wikimedia Commons, Pexels, Openverse), choisie par la "
              "fiche de requêtes de l'affaire, vérifiée (sujet, lieu, nuit/jour, licence, pas d'IA) et recadrée. Une preuve n'y a droit "
              "que si sa fiche le dit (ce qu'elle prouve tient à son heure, son lieu ou son sujet) ; deux photos de la même chose partagent "
              "la même photographie (deux cadrages).",
              "- **CUSTOM_REAL** — vraie photo à prendre nous-mêmes (aucune photo libre ne peut montrer ce que l'affaire décrit).",
              "- **PROCEDURAL** — capture d'écran, document, ticket, photo ratée : un rendu du téléphone, pas une photographie.",
              "- **REMOVE** — image à supprimer (IA, provisoire, inutilisée).",
              ""]
    lines += compliance_lines(catalog, manifest)
    for (case, title), ps in sorted(by_case.items()):
        label = f"ALIBI #{int(case) - 100:03d}" if int(case) > 100 else f"#{case}"
        lines += [f"## {label} {title}", "", "| ID | Écran | Fonction | Preuve | Décision | Raison | Remplacement |", "|---|---|---|---|---|---|---|"]
        for p in ps:
            fonction = f"{p['scene']}{' · nuit' if p['night'] else ''} — {p['caption']}".replace("|", "/")
            lines.append(f"| `{p['photoId']}` | {', '.join(p['screens'])} | {fonction} | {'oui' if p['isEvidence'] else 'non'} | **{p['decision']}** | {p['reason'].replace('|', '/')} | {p.get('replacement', '')} |")
        lines.append("")
    DOCS.mkdir(parents=True, exist_ok=True)
    (DOCS / "PHOTO_AUDIT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def cmd_report(args, cfg, catalog, manifest, stats) -> None:
    fetched = [e for e in manifest.get("sources", []) if e.get("status") == "fetched"]
    missing = [e for e in manifest.get("sources", []) if e.get("status") == "missing"]
    pending = [s for s in catalog["sources"] if s["id"] not in {e["sourceId"] for e in manifest.get("sources", [])}]
    used = {}
    for a in manifest.get("assets", []):
        used.setdefault(a["sourceId"], []).append(a["photoId"])
    lines = ["# Provenance des photos externes", "",
             "Généré par `./scripts/photos.sh report` à partir de `config/photo_sources.json` (manifeste complet, machine-lisible).",
             "Crédits visibles dans le jeu : Paramètres › À propos › Crédits photos (`ScreenshotUI/Resources/PhotoCredits.json`).", "",
             f"- Sources récupérées : **{len(fetched)}** (Wikimedia Commons : {sum(1 for e in fetched if e['provider'] == 'wikimedia')}, Pexels : {sum(1 for e in fetched if e['provider'] == 'pexels')}, Openverse : {sum(1 for e in fetched if e['provider'] == 'openverse')})",
             f"- Images du jeu produites : **{len(manifest.get('assets', []))}**",
             f"- Sources sans image acceptable (MISSING → rendu procédural conservé) : **{len(missing)}**",
             f"- Sources pas encore recherchées : **{len(pending)}**", ""]
    if fetched:
        lines += ["| Source | Fournisseur | ID | Auteur | Licence | Page source | Requête | Récupérée le | Photos du jeu |", "|---|---|---|---|---|---|---|---|---|"]
        for e in fetched:
            lic = f"[{e.get('license', '').upper()} {e.get('licenseVersion', '')}]({e.get('licenseUrl')})".replace("  ", " ")
            author = f"[{e.get('photographer') or '?'}]({e.get('photographerUrl')})" if e.get("photographerUrl") else (e.get("photographer") or "?")
            lines.append(f"| `{e['sourceId']}` | {e['provider']}{' · ' + e['origin'] if e.get('origin') and e['provider'] == 'openverse' else ''} | {e['providerPhotoId']} | {author} | {lic} | [lien]({e.get('sourceUrl')}) | « {e.get('queryUsed')} » | {e.get('dateFetched', '')[:10]} | {', '.join(f'`{x}`' for x in used.get(e['sourceId'], []))} |")
        lines.append("")
    lines += compliance_lines(catalog, manifest)
    if missing:
        lines += ["## Sans image acceptable", ""] + [f"- `{e['sourceId']}` : {e.get('reason', '')}" for e in missing] + [""]
    if pending:
        lines += ["## Pas encore recherchées", ""] + [f"- `{s['id']}` « {s['query']} »" for s in pending] + [""]
    if stats.get("errors"):
        lines += ["## Incidents de la dernière exécution", ""] + [f"- {e}" for e in dict.fromkeys(stats["errors"])] + [""]
    if not args.dry_run:
        DOCS.mkdir(parents=True, exist_ok=True)
        (DOCS / "PHOTO_SOURCES.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        write_json(CREDITS_JSON, credits_payload(manifest))
    else:
        REPORTS.mkdir(exist_ok=True)
        (REPORTS / "photo_pipeline_dry_run.md").write_text(
            "# Photo pipeline — dry run\n\n" + "\n".join(stats.get("plan", [])) + "\n\n" + "\n".join(lines) + "\n", encoding="utf-8")
        log(f"report: dry-run report in {REPORTS / 'photo_pipeline_dry_run.md'}")


def status_counts(catalog: dict, manifest: dict, stats: dict) -> dict:
    fetched = [e for e in manifest.get("sources", []) if e.get("status") == "fetched"]
    return {
        "photos": len(catalog["photos"]),
        "sourcesToFetch": len(catalog["sources"]),
        "sourcesFetched": len(fetched),
        "sourcesMissing": sum(1 for e in manifest.get("sources", []) if e.get("status") == "missing"),
        "assetsReady": len(manifest.get("assets", [])),
        "assetsExpected": sum(1 for p in catalog["photos"] if p.get("source")),
        "customRequired": sum(1 for p in catalog["photos"] if p["decision"] == "CUSTOM_REAL"),
        "procedural": sum(1 for p in catalog["photos"] if p["decision"] == "PROCEDURAL"),
        "rejectedCandidates": stats.get("rejected", 0) + manifest.get("stats", {}).get("rejected", 0),
        "apiRequests": {k: v + manifest.get("stats", {}).get("requests", {}).get(k, 0) for k, v in {**{"wikimedia": 0, "pexels": 0, "openverse": 0}, **stats.get("requests", {})}.items()},
        "bytes": sum(a.get("bytes", 0) for a in manifest.get("assets", [])),
    }


def cmd_status(args, cfg, catalog, manifest, stats) -> None:
    c = status_counts(catalog, manifest, stats)
    log("photo-pipeline status")
    log(f"  photos du jeu ............ {c['photos']}")
    log(f"  sources à récupérer ...... {c['sourcesToFetch']}")
    log(f"  sources récupérées ....... {c['sourcesFetched']}   (sans candidat : {c['sourcesMissing']})")
    log(f"  images prêtes / attendues  {c['assetsReady']} / {c['assetsExpected']}   ({c['bytes'] / 1e6:.1f} Mo)")
    log(f"  validées ................. {c['assetsReady'] if not cmd_validate_quiet(cfg, catalog, manifest) else 0}")
    log(f"  candidats rejetés ........ {c['rejectedCandidates']}")
    log(f"  vraie photo à prendre .... {c['customRequired']}   (procédural voulu : {c['procedural']})")
    log(f"  requêtes API ............. wikimedia {c['apiRequests'].get('wikimedia', 0)} · pexels {c['apiRequests'].get('pexels', 0)} · openverse {c['apiRequests'].get('openverse', 0)}")
    key = "présente" if os.environ.get(cfg["providers"]["pexels"]["apiKeyEnv"]) else "absente (Pexels ignoré)"
    log(f"  clé Pexels ............... {key}")


def cmd_validate_quiet(cfg, catalog, manifest) -> list[str]:
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()):
        return cmd_validate(argparse.Namespace(dry_run=True), cfg, catalog, manifest, {"errors": []})


# ─────────────────────────────────────────────────────────── main

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["audit", "search", "download", "process", "validate", "report", "status", "all"])
    ap.add_argument("--dry-run", action="store_true", help="show searches and choices, write nothing but a report in reports/")
    ap.add_argument("--offline", action="store_true", help="never call the network (cache only)")
    args = ap.parse_args(argv)
    cfg = load_json(CONFIG)
    stats = {"requests": {}, "rejected": 0, "errors": []}
    if args.command == "audit":
        cmd_audit(args, cfg)
        return 0
    catalog = cmd_audit(args, cfg) if args.command == "all" else load_json(CATALOG)
    if catalog is None:
        log("Pas de catalogue : lancer d'abord `audit`.")
        return 1
    manifest = load_json(MANIFEST, {}) or {}
    manifest.setdefault("sources", [])
    manifest.setdefault("assets", [])
    steps = {"search": [cmd_search], "download": [cmd_download], "process": [cmd_process],
             "validate": [], "report": [cmd_report], "status": [cmd_status],
             "all": [cmd_search, cmd_download, cmd_process, cmd_report]}[args.command]
    for step in steps:
        step(args, cfg, catalog, manifest, stats)
        if not args.dry_run and step in (cmd_download, cmd_process):
            prev = manifest.get("stats", {})
            manifest["stats"] = {"requests": {k: prev.get("requests", {}).get(k, 0) + v for k, v in stats["requests"].items()} or prev.get("requests", {}),
                                 "rejected": prev.get("rejected", 0) + stats["rejected"], "lastRun": now_iso()}
            stats["requests"], stats["rejected"] = {}, 0
            manifest["about"] = "Provenance of every external photo (generated by scripts/photos/pipeline.py). One `sources` entry per downloaded image, one `assets` entry per image shipped in the game."
            write_json(MANIFEST, manifest)
    if args.command in ("validate", "all"):
        problems = cmd_validate(args, cfg, catalog, manifest, stats)
        if args.command == "all":
            cmd_status(args, cfg, catalog, manifest, stats)
        return 1 if problems else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
