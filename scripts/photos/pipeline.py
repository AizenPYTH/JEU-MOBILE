#!/usr/bin/env python3
"""CONCLUDE : ENQUÊTES — photo asset pipeline.

Turns the photos of the case files into real, credited, offline images:

    case JSON ──audit──▶ config/photo_catalog.json (one decision per photo, a few shared sources)
              ──search──▶ Pexels / Openverse candidates (cached), scored, best picked
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

DECISIONS = ["KEEP", "REPLACE_BY_API", "CUSTOM_REQUIRED", "PROCEDURAL", "DUPLICATE", "UNUSED"]


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
    for path in sorted(CASES_DIR.glob("case_*.json")):
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
        return "CUSTOM_REQUIRED", f"Preuve ({', '.join(ev_index[pid])}) : le cadrage, l'heure ou le contenu sert le raisonnement ; jamais de photo de banque d'images."
    if forced:
        return "CUSTOM_REQUIRED", f"Détail utile à l'enquête (règle manuelle) : {forced}"
    if scene in rules["proceduralScenes"] or style in rules["proceduralStyles"] or photo.get("lines"):
        return "PROCEDURAL", "Texte lisible exact ou photo ratée : le rendu du jeu (texte généré, flou) reste la bonne source."
    if scene in rules["peopleScenes"] or style in rules["peopleStyles"]:
        return "CUSTOM_REQUIRED", "Personnes de l'affaire à l'image (selfie, groupe, miroir) : une photo générique montrerait des inconnus."
    for name in names:
        if re.search(r"(?<![\wÀ-ÿ])" + re.escape(name) + r"(?![\wÀ-ÿ])", text):
            return "CUSTOM_REQUIRED", f"Personne nommée à l'image ({name}) : une photo générique montrerait un inconnu."
    for word in rules["personWords"]:
        if re.search(r"(?<![a-z])" + re.escape(fold(word)) + r"(?![a-z])", folded):
            return "CUSTOM_REQUIRED", f"Personne reconnaissable décrite (« {word} ») : une photo générique la contredirait."
    for pattern in rules["readableTextPatterns"]:
        if pattern in text or fold(pattern) in folded:
            return "CUSTOM_REQUIRED", f"Texte, écran ou marque précis décrit dans la photo (« {pattern} ») : une photo générique le contredirait."
    key = (scene, fold(photo.get("caption", "")))
    if key in seen:
        return "DUPLICATE", f"Même scène et même légende que {seen[key]} : réutilise sa source avec un autre cadrage."
    seen[key] = pid
    return "REPLACE_BY_API", "Photo d'ambiance sans rôle dans le raisonnement : source externe recadrée."


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
        seen: dict = {}
        for dev in case["devices"]:
            for photo in dev["photos"]:
                aid = asset_name(case_key, photo["id"])
                if aid in manual:
                    photos.append(manual[aid])
                    continue
                decision, reason = classify(photo, case, ev_index, names, cfg, seen)
                night = is_night(photo, cfg["audit"])
                entry = {
                    "assetId": aid, "case": case_key, "caseTitle": case["title"], "photoId": photo["id"],
                    "screens": ["Photos"] + usage.get(photo["id"], []), "scene": photo["scene"],
                    "style": photo.get("style") or "standard", "takenAt": photo.get("takenAt"),
                    "caption": photo.get("caption"), "isEvidence": photo["id"] in ev_index,
                    "decision": decision, "reason": reason, "night": night, "required": decision == "REPLACE_BY_API",
                    "currentSource": "procédural (GeneratedPhoto, scène « %s »)" % photo["scene"],
                }
                if decision in ("REPLACE_BY_API", "DUPLICATE"):
                    query, fallbacks = build_queries(case_key, photo, cfg)
                    gkey = (case_key, query, night)
                    groups.setdefault(gkey, {"query": query, "fallbacks": fallbacks, "night": night, "case": case_key,
                                             "scene": photo["scene"], "photos": []})
                    groups[gkey]["photos"].append(aid)
                photos.append(entry)
    # Sources: a group of photos with the same query shares 1 source per `photosPerSource` photos.
    per_source = cfg["selection"]["photosPerSource"]
    sources = []
    assignment = {}
    for (case_key, query, night), g in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][1], kv[0][2])):
        slug = re.sub(r"[^a-z0-9]+", "_", fold(query)).strip("_")[:40]
        count = math.ceil(len(g["photos"]) / per_source)
        for i in range(count):
            sid = f"case{case_key}_src_{slug}{'_night' if night and 'night' not in slug else ''}_{i + 1:02d}"
            members = g["photos"][i * per_source:(i + 1) * per_source]
            outdoor_dark = night and g["scene"] in cfg["audit"]["outdoorScenes"] + ["club", "concert"]
            sources.append({
                "id": sid, "case": case_key, "type": "ambient", "usage": "phone-photo", "scene": g["scene"],
                "query": query, "fallbackQueries": g["fallbacks"], "orientation": "landscape", "ratio": "4:3",
                "minWidth": cfg["selection"]["minSourceWidth"], "minHeight": cfg["selection"]["minSourceHeight"],
                "priority": 1 if len(members) > 1 else 2, "providers": cfg["providers"]["order"],
                "sensitivity": "no-identifiable-people, no-brands", "isEvidence": False,
                "night": night, "requireDark": outdoor_dark, "variants": len(members), "photos": members,
                "transform": {"profile": "phone-photo", "crop": "smart", "variantCrops": ["best", "left", "right"][:len(members)]},
            })
            for v, aid in enumerate(members):
                assignment[aid] = (sid, v)
    for p in photos:
        if p["assetId"] in assignment:
            p["source"], p["variant"] = assignment[p["assetId"]]
            p["replacement"] = f"{p['source']} (variante {p['variant'] + 1})"
        elif p["decision"] == "CUSTOM_REQUIRED":
            p["replacement"] = "image sur mesure à produire ; le rendu procédural reste en attendant"
        elif p["decision"] == "PROCEDURAL":
            p["replacement"] = "aucun : rendu procédural conservé"
    catalog = {
        "about": "Generated by `scripts/photos.sh audit` from the case files, then editable: set \"manual\": true on a photo entry to keep your edits. One entry per photo of the game; ambient photos share `sources`.",
        "version": 1, "sources": sources, "photos": photos,
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
    data = http.get_json("pexels", url, {"Authorization": key}, pcfg["minIntervalSeconds"]) or {}
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
    data = http.get_json("openverse", url, {}, ocfg["minIntervalSeconds"]) or {}
    results = []
    for r in data.get("results", []):
        results.append({
            "provider": "openverse", "providerPhotoId": r.get("id", ""), "width": r.get("width") or 0,
            "height": r.get("height") or 0, "title": r.get("title") or "",
            "tags": [t.get("name", "") for t in (r.get("tags") or [])], "photographer": r.get("creator") or "",
            "photographerUrl": r.get("creator_url") or "", "sourceUrl": r.get("foreign_landing_url") or "",
            "downloadUrl": r.get("url") or "", "license": (r.get("license") or "").lower(),
            "licenseVersion": r.get("license_version") or "", "licenseUrl": r.get("license_url") or "",
            "licenseCode": (r.get("license") or "").lower(), "origin": r.get("source") or r.get("provider") or "",
            "attribution": r.get("attribution") or "", "mature": bool(r.get("mature")),
        })
    write_json(cpath, results)
    return results


def hex_luminance(hex_color: str | None) -> float | None:
    if not hex_color or not re.match(r"^#?[0-9a-fA-F]{6}$", hex_color):
        return None
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def licence_ok(c: dict, cfg: dict) -> tuple[bool, str]:
    if c["provider"] == "pexels":
        return True, ""
    ocfg = cfg["providers"]["openverse"]
    code = c.get("licenseCode", "")
    if code not in ocfg["allowedLicenses"]:
        return False, f"licence « {code or '?'} » non autorisée (usage commercial + modification requis)"
    if not c.get("licenseUrl") or not c.get("sourceUrl"):
        return False, "licence ou page source manquante"
    if code in ocfg["attributionRequiredFor"] and not c.get("photographer"):
        return False, "auteur inconnu pour une licence qui exige l'attribution"
    return True, ""


def score(c: dict, source: dict, cfg: dict) -> tuple[float, str]:
    """Score of a candidate for a source; (−inf, reason) when rejected."""
    sel = cfg["selection"]
    words = tokens(c.get("title", "") + " " + " ".join(c.get("tags", [])))
    ok, why = licence_ok(c, cfg)
    if not ok:
        return -math.inf, why
    if c.get("mature"):
        return -math.inf, "contenu signalé sensible"
    if not c.get("downloadUrl"):
        return -math.inf, "pas d'URL de téléchargement"
    if any(w in words for w in sel["rejectWords"]):
        return -math.inf, "mot exclu dans le titre ou les tags"
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
    return s, ""


# ─────────────────────────────────────────────────────────── search / download

def cmd_search(args, cfg, catalog, manifest, stats) -> None:
    """Chooses candidates for every source that has none yet (the manifest is the lock file)."""
    http = Http(cfg, stats)
    locked = {e["sourceId"] for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    used = {(e["provider"], e["providerPhotoId"]) for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    selection = load_json(CACHE / "selection.json", {}) or {}
    plan_lines = []
    for src in catalog["sources"]:
        if src["id"] in locked:
            continue
        ranked, rejected = [], 0
        for query in [src["query"]] + src["fallbackQueries"]:
            for provider in src["providers"]:
                try:
                    results = pexels_search(http, cfg, query, args.offline) if provider == "pexels" else openverse_search(http, cfg, query, args.offline)
                except RateLimited as e:
                    stats["errors"].append(f"{provider}: {e}")
                    results = []
                except Exception as e:  # noqa: BLE001
                    stats["errors"].append(f"{provider} « {query} »: {e}")
                    results = []
                for c in results:
                    if (c["provider"], c["providerPhotoId"]) in used:
                        continue
                    sc, why = score(c, src, cfg)
                    if sc == -math.inf or sc < cfg["selection"]["minScore"]:
                        rejected += 1
                        continue
                    ranked.append({**c, "score": round(sc, 2), "queryUsed": query})
            if len(ranked) >= cfg["selection"]["candidatesToTry"]:
                break
        ranked.sort(key=lambda c: -c["score"])
        ranked = ranked[:cfg["selection"]["candidatesToTry"]]
        stats["rejected"] += rejected
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
    for src in catalog["sources"]:
        current = entries.get(src["id"])
        if current and current.get("status") == "fetched" and (CACHE / "originals" / current["file"]).exists():
            continue
        if current and current.get("status") == "fetched" and args.offline:
            continue
        tried = 0
        for cand in selection.get(src["id"], []):
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
                "title": cand.get("title", ""), "queryUsed": cand.get("queryUsed", src["query"]),
                "dateFetched": now_iso(), "width": cand.get("width"), "height": cand.get("height"),
                "score": cand.get("score"), "luminance": round(lum, 1), "file": fname,
                "sha256": hashlib.sha256(dest.read_bytes()).hexdigest(),
                "attributionRequired": cand["provider"] == "openverse" and cand.get("licenseCode") in cfg["providers"]["openverse"]["attributionRequiredFor"],
                "attributionText": attribution_text(cand),
                "evidence": False,
            }
            break
        else:
            if not args.dry_run and (src["id"] not in entries or entries[src["id"]].get("status") != "fetched"):
                entries[src["id"]] = {"sourceId": src["id"], "status": "missing", "case": src["case"],
                                      "reason": "aucun candidat acceptable" if not selection.get(src["id"]) else f"{tried} téléchargement(s) échoué(s) ou rejeté(s)"}
    manifest["sources"] = [entries[s["id"]] for s in catalog["sources"] if s["id"] in entries]
    fetched = sum(1 for e in manifest["sources"] if e.get("status") == "fetched")
    log(f"download: {fetched}/{len(catalog['sources'])} sources fetched")


def attribution_text(c: dict) -> str:
    who = c.get("photographer") or "auteur inconnu"
    if c["provider"] == "pexels":
        return f"Photo by {who} on Pexels"
    lic = (c.get("licenseCode") or "").upper()
    if lic in ("CC0", "PDM"):
        return f"« {c.get('title') or 'Sans titre'} » — {who} ({lic})"
    return f"« {c.get('title') or 'Sans titre'} » by {who}, CC {lic} {c.get('licenseVersion', '')}".strip()


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
            "evidence": False, "finalAssetPath": str(out_file.relative_to(ROOT)), "transformation": transform,
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
        if p["isEvidence"] and p["decision"] in ("REPLACE_BY_API", "DUPLICATE"):
            problems.append(f"{p['assetId']}: une preuve ne peut pas venir d'une banque d'images")
    for s in catalog["sources"]:
        if not s["query"].strip():
            problems.append(f"{s['id']}: source sans requête")
    sources = {e["sourceId"]: e for e in manifest.get("sources", []) if e.get("status") == "fetched"}
    for e in sources.values():
        for field in ("provider", "providerPhotoId", "sourceUrl", "license", "licenseUrl", "queryUsed", "dateFetched", "attributionText"):
            if not e.get(field):
                problems.append(f"{e['sourceId']}: provenance incomplète ({field})")
        if e["provider"] == "openverse" and e.get("license") not in cfg["providers"]["openverse"]["allowedLicenses"]:
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


def write_audit_doc(catalog: dict) -> None:
    photos = catalog["photos"]
    lines = ["# Audit des photos du jeu", "",
             "Généré par `./scripts/photos.sh audit` à partir des 5 affaires (`ScreenshotKit/Sources/CaseLibrary/Resources/Cases`).",
             "Ne pas éditer à la main : modifier `config/photo_pipeline.json` (règles, requêtes) ou marquer une entrée `\"manual\": true` dans `config/photo_catalog.json`, puis relancer.",
             "", "## Synthèse", "", "| Affaire | Photos | REPLACE_BY_API | DUPLICATE | CUSTOM_REQUIRED | PROCEDURAL | KEEP | UNUSED | Sources |", "|---|---|---|---|---|---|---|---|---|"]
    by_case = {}
    for p in photos:
        by_case.setdefault((p["case"], p["caseTitle"]), []).append(p)
    for (case, title), ps in sorted(by_case.items()):
        c = {d: sum(1 for p in ps if p["decision"] == d) for d in DECISIONS}
        n_src = sum(1 for s in catalog["sources"] if s["case"] == case)
        lines.append(f"| #{case} {title} | {len(ps)} | {c['REPLACE_BY_API']} | {c['DUPLICATE']} | {c['CUSTOM_REQUIRED']} | {c['PROCEDURAL']} | {c['KEEP']} | {c['UNUSED']} | {n_src} |")
    tot = {d: sum(1 for p in photos if p["decision"] == d) for d in DECISIONS}
    lines.append(f"| **Total** | **{len(photos)}** | **{tot['REPLACE_BY_API']}** | **{tot['DUPLICATE']}** | **{tot['CUSTOM_REQUIRED']}** | **{tot['PROCEDURAL']}** | **{tot['KEEP']}** | **{tot['UNUSED']}** | **{len(catalog['sources'])}** |")
    lines += ["", "Décisions :", "",
              "- **REPLACE_BY_API** — photo d'ambiance : image externe (Pexels, sinon Openverse sous licence libre) recadrée, une source servant jusqu'à 3 photos.",
              "- **DUPLICATE** — même scène et même légende qu'une autre photo de l'affaire : même source, autre cadrage.",
              "- **CUSTOM_REQUIRED** — preuve, personne de l'affaire, ou texte/écran précis décrit : une image générique trahirait l'enquête. Le rendu procédural reste en attendant une image sur mesure.",
              "- **PROCEDURAL** — capture d'écran, document, ticket (texte exact généré par le jeu) ou photo ratée (poche, plafond) : le rendu du jeu est la bonne source.",
              "- **KEEP** — image existante conservée (aucune photo réelle n'existait avant le pipeline). **UNUSED** — photo jamais affichée (aucune : toutes sont dans la galerie).",
              ""]
    for (case, title), ps in sorted(by_case.items()):
        lines += [f"## #{case} {title}", "", "| ID | Écran | Fonction | Preuve | Source actuelle | Décision | Raison | Remplacement |", "|---|---|---|---|---|---|---|---|"]
        for p in ps:
            fonction = f"{p['scene']}{' · nuit' if p['night'] else ''} — {p['caption']}".replace("|", "/")
            lines.append(f"| `{p['photoId']}` | {', '.join(p['screens'])} | {fonction} | {'oui' if p['isEvidence'] else 'non'} | {p['currentSource']} | **{p['decision']}** | {p['reason']} | {p.get('replacement', '')} |")
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
             f"- Sources récupérées : **{len(fetched)}** (Pexels : {sum(1 for e in fetched if e['provider'] == 'pexels')}, Openverse : {sum(1 for e in fetched if e['provider'] == 'openverse')})",
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
        "customRequired": sum(1 for p in catalog["photos"] if p["decision"] == "CUSTOM_REQUIRED"),
        "procedural": sum(1 for p in catalog["photos"] if p["decision"] == "PROCEDURAL"),
        "rejectedCandidates": stats.get("rejected", 0) + manifest.get("stats", {}).get("rejected", 0),
        "apiRequests": {k: v + manifest.get("stats", {}).get("requests", {}).get(k, 0) for k, v in {**{"pexels": 0, "openverse": 0}, **stats.get("requests", {})}.items()},
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
    log(f"  image sur mesure requise . {c['customRequired']}   (procédural conservé : {c['procedural']})")
    log(f"  requêtes API ............. pexels {c['apiRequests'].get('pexels', 0)} · openverse {c['apiRequests'].get('openverse', 0)}")
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
