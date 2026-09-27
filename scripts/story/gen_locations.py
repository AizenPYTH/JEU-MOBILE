# Generates ScreenshotKit/Sources/StoryLibrary/Resources/Story/locations.json (ENVIRONMENTS.md).
# Units: metres; x right, z towards the front, y up. facing 0 = towards +z.
import json, sys
OUT = sys.argv[1]
WALL = "#6B6F73"; LINO = "#3A3C3E"; WOOD = "#5A4330"; METAL = "#8C9096"; BENBLUE = "#6F7A86"

def cam(id, x, y, z, lx, ly, lz, focal):
    return {"id": id, "x": x, "y": y, "z": z, "lookX": lx, "lookY": ly, "lookZ": lz, "focal": focal}
def anc(id, x, z, facing, seated=None):
    d = {"id": id, "x": x, "z": z, "facing": facing}
    if seated: d["seated"] = True
    return d
def prop(id, kind, x, z, **k):
    d = {"id": id, "kind": kind, "x": x, "z": z}; d.update(k); return d

locations = []

# ENV_BEN_CORRIDOR — 3rd floor, 24 m, glass partitions left, doors 301–318 right.
props = []
for i in range(18):
    z = round(10.2 - i * 1.2, 2)
    props.append(prop(f"door_{301+i}", "door", 1.08, z, rotation=-90, label=f"{301+i}", color="#4A4E53" if i != 11 else "#6F5A44"))
for i in range(7):
    props.append(prop(f"partition_{i}", "partition", -1.08, round(9.5 - i * 3.2, 2), rotation=90, size=[3.0, 0.05, 2.6]))
for i in range(10):
    props.append(prop(f"neon_{i}", "neon", 0, round(11 - i * 2.4, 2), y=2.57, flicker=True if i == 6 else None))
props += [
    prop("fountain", "fountain", -0.8, 7.4),
    prop("cart", "cart", 0.7, 5.2, rotation=10),
    prop("sign_ben", "sign", 0, -11.9, y=1.75, label="BEN · 3ᵉ ÉTAGE · BUREAUX 301 – 318"),
    prop("window_far_l", "window", -0.55, -11.92, y=0.95, size=[0.8, 0.05, 1.2]),
    prop("window_far_r", "window", 0.55, -11.92, y=0.95, size=[0.8, 0.05, 1.2]),
    prop("radiator_far", "radiator", 0, -11.85),
    prop("poster_safety", "poster", -1.02, 1.0, y=1.3, rotation=90, label="CONSIGNES DE SÉCURITÉ"),
]
for p in props:
    if p.get("flicker") is None: p.pop("flicker", None)
locations.append({
    "id": "ENV_BEN_CORRIDOR", "name": "Couloir, 3ᵉ étage", "size": [2.2, 24.0, 2.6],
    "wallColor": WALL, "floorColor": LINO, "accentColor": BENBLUE, "lighting": "corridor", "ambience": "ben_hvac",
    "anchors": [anc("entry", 0.1, 10.5, 180), anc("hall", 0.0, 8.8, 180), anc("mid", 0.1, 3.0, 180), anc("hero", 0.05, 4.2, 180),
                anc("door312", 0.5, -3.0, 90), anc("far", 0.0, -9.5, 180), anc("wait", -0.6, 6.2, 90)],
    "cameras": [cam("cam_corr_wide", 0.25, 1.7, 11.85, 0.0, 1.2, 1.0, 28),
                cam("cam_corr_follow", 0.3, 1.5, 6.9, 0.0, 1.35, 2.5, 50),
                cam("cam_corr_door312", -0.85, 1.45, -0.6, 0.9, 1.2, -3.0, 35),
                cam("cam_corr_hero", 0.62, 1.45, 6.6, -0.05, 1.3, 3.9, 50),
                cam("cam_corr_cu", -0.55, 1.55, 1.9, 0.05, 1.55, 3.0, 85)],
    "props": props,
})

# ENV_BEN_OFFICE_LACAZE — office 312, 4 × 5 m.
locations.append({
    "id": "ENV_BEN_OFFICE_LACAZE", "name": "Bureau 312", "size": [4.0, 5.0, 2.6],
    "wallColor": "#62666A", "floorColor": LINO, "accentColor": WOOD, "lighting": "office_night", "ambience": "ben_office_night",
    "anchors": [anc("lac_desk", 0.0, -1.78, 0, True), anc("lac_stand", -0.55, -1.55, 30), anc("lac_window", 0.9, -2.0, 200),
                anc("visitor", -0.42, -0.28, 180, True), anc("visitor_b", 0.48, -0.28, 180, True),
                anc("door_in", 1.35, 2.05, 180), anc("before_desk", -0.2, 0.35, 180), anc("side", 1.35, -0.6, 250)],
    "cameras": [cam("cam_lac_wide", -1.72, 1.55, 2.3, 0.25, 1.0, -1.3, 28),
                cam("cam_lac_door", 1.2, 1.5, 2.3, 0.3, 1.2, -1.6, 35),
                cam("cam_lac_ms", 0.5, 1.2, 0.25, 0.0, 1.1, -1.78, 50),
                cam("cam_lac_cu", 0.28, 1.22, -0.5, 0.0, 1.24, -1.78, 85),
                cam("cam_lac_os", -1.05, 1.5, 0.7, 0.0, 1.25, -1.78, 50),
                cam("cam_lac_rev", 0.42, 1.3, -1.95, -0.42, 1.12, -0.28, 50),
                cam("cam_lac_player_cu", 0.1, 1.2, -1.35, -0.42, 1.2, -0.28, 85),
                cam("cam_lac_desk_top", 0.32, 1.22, -0.5, 0.1, 0.78, -0.98, 100)],
    "props": [
        prop("desk", "desk", 0.0, -1.2, color=WOOD, size=[1.6, 0.8, 0.75]),
        prop("chair_lacaze", "chair", 0.0, -1.85, color="#2B2520"),
        prop("chair_visitor_a", "chair", -0.42, -0.3, rotation=180),
        prop("chair_visitor_b", "chair", 0.48, -0.3, rotation=180),
        prop("lamp_green", "lamp", -0.58, -1.38, y=0.75, color="#24452F"),
        prop("files_pile", "files", 0.52, -1.42, y=0.75),
        prop("desk_phone", "desk_phone", 0.62, -1.02, y=0.75),
        prop("frame_down", "frame_down", -0.2, -1.5, y=0.75),
        prop("mug", "mug", 0.3, -1.55, y=0.75),
        prop("agent_folder", "folder", -0.12, -1.0, y=0.755, color=BENBLUE, hidden=True, label="DOSSIER D'AGENT"),
        prop("case_folder", "folder", 0.1, -0.98, y=0.755, hidden=True, label="N° 001"),
        prop("case_folder_c02", "folder", 0.1, -0.98, y=0.755, hidden=True, label="N° C02-A"),
        prop("evidence_bag", "evidence_bag", 0.14, -0.96, y=0.78, rotation=12, hidden=True),
        prop("ben_card", "card", 0.08, -0.92, y=0.758, hidden=True, label="{player.LASTNAME} · {player.service}"),
        prop("cabinet", "cabinet", -1.78, -1.4, rotation=90, size=[1.2, 0.45, 1.9]),
        prop("shelf_files", "shelf", 1.75, -1.0, rotation=-90, size=[1.4, 0.35, 2.0]),
        prop("window", "window", 0.85, -2.47, y=0.9, size=[1.4, 0.05, 1.3]),
        prop("blinds", "blinds", 0.85, -2.43, y=0.9, size=[1.4, 0.05, 1.3]),
        prop("radiator", "radiator", 0.85, -2.4),
        prop("door", "door", 1.35, 2.47, rotation=180, color="#8A9097", label="312"),
        prop("neon_off", "neon", 0, 0, y=2.57),
        prop("coat_rack", "coat_rack", -1.7, 2.1),
    ],
})

# ENV_BEN_OFFICE_PLAYER — the player's office, 4 levels (hotspots per level).
def hs(label, name, camera, provenance=None):
    d = {"label": label, "name": name, "camera": camera}
    if provenance: d["provenance"] = provenance
    return d
locations.append({
    "id": "ENV_BEN_OFFICE_PLAYER", "name": "Mon bureau", "size": [3.5, 4.0, 2.6],
    "wallColor": WALL, "floorColor": LINO, "accentColor": BENBLUE, "lighting": "office_night", "ambience": "ben_hvac",
    "anchors": [anc("po_desk", 0.0, -1.35, 0, True), anc("po_entry", 0.6, 0.3, 200), anc("po_stand", 0.35, -0.55, 170),
                anc("po_window", -0.6, -1.5, 180)],
    "cameras": [cam("cam_po_wide", 1.5, 1.8, 1.75, -0.25, 0.85, -1.15, 28),
                cam("cam_po_ms", 0.7, 1.35, 0.3, 0.0, 1.1, -1.35, 50),
                cam("cam_po_obj_phone", 0.75, 1.15, -0.6, 0.5, 0.78, -1.1, 100),
                cam("cam_po_obj_computer", 0.35, 1.3, -0.35, 0.08, 1.0, -1.5, 85),
                cam("cam_po_obj_files", -0.1, 1.2, -0.45, -0.32, 0.78, -1.02, 100),
                cam("cam_po_obj_card", 0.55, 1.15, -0.45, 0.32, 0.78, -0.92, 100),
                cam("cam_po_obj_archives", 0.2, 1.4, -0.3, -1.55, 1.0, -1.1, 50),
                cam("cam_po_obj_rewards", -0.2, 1.4, -0.2, 1.55, 1.1, -0.9, 50),
                cam("cam_po_obj_board", 0.4, 1.5, 0.3, 0.2, 1.5, -1.95, 50),
                cam("cam_po_obj_safe", 0.3, 1.1, 0.4, -1.45, 0.4, 0.6, 50)],
    "props": [
        prop("desk_metal", "desk", 0.0, -1.3, color="#7E8388", size=[1.4, 0.7, 0.75], maxLevel=2),
        prop("desk_wood", "desk", 0.0, -1.3, color=WOOD, size=[1.6, 0.8, 0.75], level=3),
        prop("chair", "chair", 0.0, -1.85),
        prop("computer", "computer", 0.08, -1.48, y=0.75,
             hotspot=hs("ORDINATEUR", "Poste BEN, session {player.service}", "cam_po_obj_computer", "Service informatique du BEN")),
        prop("computer_2", "computer", -0.52, -1.45, y=0.75, rotation=15, level=3),
        prop("lamp_arm", "lamp", -0.55, -1.4, y=0.75, color="#2E3238", maxLevel=2),
        prop("lamp_brass", "lamp", 0.62, -1.5, y=0.75, color="#8C7440", level=3),
        prop("desk_phone", "desk_phone", 0.5, -1.1, y=0.75,
             hotspot=hs("TÉLÉPHONE", "Ligne directe, poste 3127", "cam_po_obj_phone", "Standard du BEN")),
        prop("files", "files", -0.32, -1.05, y=0.75,
             hotspot=hs("DOSSIERS", "Dossiers en cours", "cam_po_obj_files", "Archives du BEN")),
        prop("card", "card", 0.32, -0.95, y=0.752, requires="office_card", label="{player.LASTNAME} · {player.service}",
             hotspot=hs("CARTE BEN", "Carte BEN · {player.service}", "cam_po_obj_card", "Remise par le Cdt. Lacaze")),
        prop("window", "window", -0.8, -1.97, y=0.95, size=[1.2, 0.05, 1.2]),
        prop("blinds", "blinds", -0.8, -1.93, y=0.95, size=[1.2, 0.05, 1.2], level=4),
        prop("neon", "neon", 0, -0.2, y=2.57),
        prop("cabinet", "cabinet", -1.55, -1.1, rotation=90, size=[1.0, 0.45, 1.4], level=2,
             hotspot=hs("ARCHIVES", "Armoire d'archives", "cam_po_obj_archives", "Mobilier du BEN")),
        prop("frame_first", "frame", -1.72, 0.2, y=1.45, rotation=90, level=2, requires="office_frame"),
        prop("mug", "mug", 0.25, -1.55, y=0.75, level=2),
        prop("plant", "plant", 1.45, 1.45, level=2),
        prop("rewards_shelf", "shelf", 1.6, -0.9, rotation=-90, size=[1.2, 0.3, 1.6], level=2,
             hotspot=hs("RÉCOMPENSES", "Étagère des récompenses", "cam_po_obj_rewards")),
        prop("corkboard", "corkboard", 0.2, -1.97, y=1.2, size=[1.4, 0.04, 0.9], level=3,
             hotspot=hs("TABLEAU", "Tableau en liège", "cam_po_obj_board")),
        prop("safe", "safe", -1.45, 0.6, rotation=90, level=4,
             hotspot=hs("COFFRE", "Coffre à dossiers sensibles", "cam_po_obj_safe")),
        prop("distinctions", "trophy", 1.72, 0.4, y=1.5, rotation=-90, level=4),
        prop("armchair", "armchair", 1.2, 0.6, rotation=-120, level=4),
        prop("door", "door", 1.2, 1.97, rotation=180, color="#8A9097", level=4, label="{player.LASTNAME}"),
    ],
})

# ENV_BEN_OPENSPACE — 12 × 18 m, 16 desks, columns.
props = []
for r in range(4):
    for c in range(4):
        x = -4.2 + c * 2.8; z = -6.0 + r * 3.6
        props.append(prop(f"desk_{r}{c}", "desk", x, z, color="#7E8388", size=[1.4, 0.7, 0.75]))
        props.append(prop(f"screen_{r}{c}", "computer", x, z - 0.15, y=0.75))
        props.append(prop(f"chair_{r}{c}", "chair", x, z - 0.6))
for i, (x, z) in enumerate([(-2.8, -3.0), (2.8, -3.0), (-2.8, 4.2), (2.8, 4.2)]):
    props.append(prop(f"column_{i}", "column", x, z))
for i in range(6):
    props.append(prop(f"neon_{i}", "neon", -3 + (i % 2) * 6, -6 + (i // 2) * 6, y=2.57))
props.append(prop("ines_desk_phone", "desk_phone", -1.6, -2.55, y=0.75))
# Chapter 2: the printed alarm log Inès puts down (label readable from her side and cam_os_log).
props.append(prop("alarm_log", "folder", -0.98, -2.5, y=0.755, rotation=158, color="#EFEBE3", hidden=True, label="22:31 · CODE 03"))
locations.append({
    "id": "ENV_BEN_OPENSPACE", "name": "Open space", "size": [12.0, 18.0, 2.6],
    "wallColor": WALL, "floorColor": LINO, "accentColor": BENBLUE, "lighting": "openspace", "ambience": "ben_openspace",
    "anchors": [anc("ines_desk", -1.4, -3.0, 0, True), anc("ines_side", -0.55, -2.2, 250), anc("entry", 5.0, 8.0, 225),
                anc("aisle", 0.2, 0.3, 180), anc("aubrac_desk", 1.4, 0.6, 0, True), anc("aubrac_lean", 2.2, 1.2, 250)],
    "cameras": [cam("cam_os_wide", 5.4, 1.9, 8.6, -0.8, 0.9, -2.0, 28),
                cam("cam_os_ines", -0.2, 1.3, -1.2, -1.4, 1.15, -3.0, 50),
                cam("cam_os_ines_cu", -0.75, 1.22, -1.75, -1.4, 1.22, -3.0, 85),
                cam("cam_os_player", -1.35, 1.45, -1.5, -0.55, 1.5, -2.2, 50),
                cam("cam_os_aubrac", 1.6, 1.45, 3.0, 2.0, 1.4, 1.1, 50),
                cam("cam_os_desk_top", -1.25, 1.25, -2.45, -1.55, 0.78, -2.7, 100),
                # Chapter 2: Aubrac seated at his desk (aubrac_desk), then turned towards ines_side.
                cam("cam_os_aubrac_desk", 0.55, 1.35, 2.0, 1.4, 1.12, 0.6, 50),
                cam("cam_os_aubrac_turn", 0.2, 1.3, -0.45, 1.4, 1.12, 0.6, 50),
                cam("cam_os_aubrac_cu", 0.8, 1.2, 0.0, 1.4, 1.18, 0.6, 85),
                cam("cam_os_ots_aubrac", -0.69, 1.62, -3.02, 1.4, 1.12, 0.6, 50),
                cam("cam_os_log", -0.8, 1.25, -2.95, -0.98, 0.76, -2.5, 100)],
    "props": props,
})

# ENV_BEN_ARCHIVES — basement, aisles of 2.4 m shelves, low ceiling.
props = []
for i in range(4):
    for side in (-1, 1):
        props.append(prop(f"shelf_{i}_{'l' if side < 0 else 'r'}", "shelf", side * 1.35, -3.6 + i * 1.9, rotation=90 * -side,
                          size=[1.7, 0.45, 2.2], color="#4E4A45"))
for i in range(3):
    props.append(prop(f"neon_{i}", "neon", 0, -3 + i * 3, y=2.27))
props += [prop("reading_table", "table", 0, 3.3, size=[1.6, 0.8, 0.75], color="#4B3A2C"),
          prop("reading_lamp", "lamp", -0.5, 3.1, y=0.75, color="#24452F"),
          prop("box_114", "archive_box", 0.25, 3.25, y=0.75, rotation=180, label="BEN-2019-114", hidden=True),
          prop("mail_print", "folder", -1.45, 3.95, y=0.755, rotation=128, color="#EFEBE3", hidden=True, label="BEN-2019-114 — TÉMOIN"),
          prop("ladder", "ladder", 0.7, -2.0, rotation=20),
          prop("colette_desk", "desk", -1.5, 4.2, color="#4B3A2C", size=[1.2, 0.6, 0.75], rotation=90)]
locations.append({
    "id": "ENV_BEN_ARCHIVES", "name": "Archives, sous-sol", "size": [5.0, 10.0, 2.3],
    "wallColor": "#5E6064", "floorColor": "#34363A", "accentColor": "#4E4A45", "lighting": "archive", "ambience": "ben_archives",
    "anchors": [anc("entry", 1.8, 4.5, 225), anc("aisle", 0.0, -1.0, 180), anc("aisle_deep", 0.0, -3.4, 0), anc("table", -0.3, 2.7, 0),
                anc("table_other", 0.45, 3.95, 180), anc("colette_desk", -1.05, 4.2, 270, True)],
    "cameras": [cam("cam_arc_aisle", 0.4, 1.6, 4.8, 0.0, 1.1, -3.0, 28),
                cam("cam_arc_table", 1.4, 1.5, 2.2, -0.1, 1.0, 3.3, 35),
                cam("cam_arc_ms", 0.55, 1.35, 1.6, -0.3, 1.25, 2.7, 50),
                cam("cam_arc_cu", -0.9, 1.35, 1.9, -0.3, 1.45, 2.7, 85),
                cam("cam_arc_colette", 0.3, 1.3, 3.1, -1.05, 1.15, 4.2, 50),
                cam("cam_arc_box", 0.5, 1.2, 2.7, 0.25, 0.85, 3.25, 100),
                # Chapter 2: over the player's shoulder (table_other) to Colette at her desk, her desk top,
                # and both sides of the reading table (Colette at « table », the player at « table_other »).
                cam("cam_arc_os_desk", 1.25, 1.6, 4.17, -1.05, 1.15, 4.2, 50),
                cam("cam_arc_desk_top", -0.95, 1.25, 3.55, -1.45, 0.76, 3.95, 100),
                cam("cam_arc_os_table", 1.13, 1.6, 4.42, -0.3, 1.52, 2.7, 50),
                cam("cam_arc_colette_cu", 0.2, 1.5, 3.45, -0.3, 1.55, 2.7, 85),
                cam("cam_arc_player", 0.4, 1.45, 2.3, 0.45, 1.55, 3.95, 50)],
    "props": props,
})

# ENV_BEN_INTERROGATION — 3 × 4 m, one-way mirror, hard ceiling light, red recording light.
locations.append({
    "id": "ENV_BEN_INTERROGATION", "name": "Salle d'audition", "size": [3.0, 4.0, 2.6],
    "wallColor": "#595D61", "floorColor": "#2F3134", "accentColor": "#3E4246", "lighting": "interrogation", "ambience": "ben_interrogation",
    "anchors": [anc("suspect", 0.0, -1.0, 0, True), anc("investigator", -0.2, 0.75, 180, True), anc("investigator_b", 0.55, 0.75, 180, True),
                anc("door_in", 1.05, 1.6, 200), anc("mirror_side", -1.1, 0.2, 90)],
    "cameras": [cam("cam_int_wide", 1.3, 1.9, 1.8, -0.2, 0.8, -0.8, 28),
                cam("cam_int_os_suspect", -0.55, 1.3, 1.25, 0.0, 1.15, -1.0, 50),
                cam("cam_int_cu", 0.25, 1.2, -0.1, 0.0, 1.22, -1.0, 85),
                cam("cam_int_mirror", -1.35, 1.5, -1.6, 0.0, 1.1, 0.5, 35),
                cam("cam_int_table", 0.4, 1.2, 0.5, 0.1, 0.78, -0.1, 100),
                # Chapter 2: the suspect's chair at 50 mm, Inès standing at mirror_side.
                cam("cam_int_ms", 0.6, 1.35, 0.55, 0.0, 1.12, -1.0, 50),
                cam("cam_int_ines", 0.9, 1.5, 0.5, -1.1, 1.52, 0.2, 50),
                cam("cam_int_ines_cu", -0.35, 1.55, 0.0, -1.1, 1.58, 0.2, 85)],
    "props": [prop("table", "table", 0, -0.1, size=[1.4, 0.8, 0.75], color="#6C6F72"),
              prop("chair_suspect", "chair", 0, -1.05), prop("chair_a", "chair", -0.2, 0.8, rotation=180),
              prop("chair_b", "chair", 0.55, 0.8, rotation=180),
              prop("mirror", "mirror", -1.47, 0.0, y=0.9, rotation=90, size=[2.2, 0.05, 1.1]),
              prop("mic", "mic", 0.05, -0.2, y=0.75), prop("cup", "mug", -0.35, -0.3, y=0.75),
              prop("pv_bellec", "folder", 0.15, 0.0, y=0.755, color="#D9D4C8", hidden=True, label="PV · T. BELLEC"),
              prop("red_light", "red_light", 1.2, -1.98, y=2.2),
              prop("ceiling", "neon", 0, 0, y=2.57),
              prop("door", "door", 1.05, 1.97, rotation=180, color="#6C6F72")],
})

# ENV_BEN_BRIEFING — meeting room, wall screen, long table.
props = [prop("table", "table", 0, 0.2, size=[1.2, 4.2, 0.75], color="#6C6F72"),
         prop("wall_screen", "wall_screen", 0, -3.95, y=1.0, size=[2.4, 0.05, 1.35]),
         prop("whiteboard", "whiteboard", 2.95, -1.0, y=0.9, rotation=-90, size=[1.8, 0.04, 1.1]),
         prop("door", "door", -2.2, 3.97, rotation=180, color="#8A9097"),
         prop("neon_a", "neon", 0, -1.5, y=2.57), prop("neon_b", "neon", 0, 1.5, y=2.57)]
for i in range(5):
    props.append(prop(f"chair_l{i}", "chair", -0.85, -1.4 + i * 0.8, rotation=90))
    props.append(prop(f"chair_r{i}", "chair", 0.85, -1.4 + i * 0.8, rotation=-90))
locations.append({
    "id": "ENV_BEN_BRIEFING", "name": "Salle de réunion", "size": [6.0, 8.0, 2.6],
    "wallColor": WALL, "floorColor": LINO, "accentColor": BENBLUE, "lighting": "briefing", "ambience": "ben_hvac",
    "anchors": [anc("screen_side", 1.2, -3.3, 200), anc("seat_l1", -0.85, -0.6, 90, True), anc("seat_l2", -0.85, 0.2, 90, True),
                anc("seat_r1", 0.85, -0.6, 270, True), anc("seat_r2", 0.85, 0.2, 270, True), anc("door_in", -2.2, 3.4, 180)],
    "cameras": [cam("cam_brf_wide", 2.4, 1.85, 3.6, -0.2, 0.9, -1.8, 28),
                cam("cam_brf_screen", -1.4, 1.5, 1.5, 0.2, 1.5, -3.9, 35),
                cam("cam_brf_ms", -0.1, 1.35, 1.6, 1.0, 1.35, -3.2, 50)],
    "props": props,
})


# Framing pass (CI captures of the first build): CLOSE = shoulders to head, so an 85 mm camera stands
# about 1.9 m from its target (as far as the room allows, 15 cm from the walls).
def _push_close_cameras(locations, want=1.9):
    import math
    for l in locations:
        w, d, h = l["size"]
        for c in l["cameras"]:
            if c.get("focal") != 85:
                continue
            vx, vy, vz = c["x"] - c["lookX"], c["y"] - c["lookY"], c["z"] - c["lookZ"]
            n = math.sqrt(vx * vx + vy * vy + vz * vz)
            if n >= want:
                continue
            t = want
            while t > n:
                x, y, z = c["lookX"] + vx / n * t, c["lookY"] + vy / n * t, c["lookZ"] + vz / n * t
                if abs(x) < w / 2 - 0.15 and abs(z) < d / 2 - 0.15 and 0.2 < y < h - 0.1:
                    break
                t -= 0.05
            c["x"], c["y"], c["z"] = (round(c["lookX"] + vx / n * t, 3), round(c["lookY"] + vy / n * t, 3),
                                      round(c["lookZ"] + vz / n * t, 3))

_push_close_cameras(locations)

# Over-the-shoulder cameras fitted so the player's shoulder sits at the frame's edge (scripts/story/
# fit_over_shoulder.py): position and target.
_OVER_SHOULDER = {
    "cam_os_ots_aubrac": (-0.850, 1.691, -2.975, 1.400, 1.203, 0.600),
    "cam_int_os_suspect": (-0.500, 1.333, 1.475, 0.000, 1.203, -1.000),
    "cam_arc_os_desk": (1.250, 1.751, 4.050, -1.050, 1.082, 4.200),
    "cam_arc_os_table": (1.075, 1.751, 4.500, -0.300, 1.459, 2.700),
}
for _l in locations:
    for _c in _l["cameras"]:
        if _c["id"] in _OVER_SHOULDER:
            _c["x"], _c["y"], _c["z"], _c["lookX"], _c["lookY"], _c["lookZ"] = _OVER_SHOULDER[_c["id"]]
    if _l["id"] == "ENV_BEN_INTERROGATION":
        for _a in _l["anchors"]:
            if _a["id"] == "door_in":
                _a["x"], _a["z"] = 0.6, 0.9

json.dump({"locations": locations}, open(OUT, "w"), ensure_ascii=False, indent=2)
print(len(locations), "locations")
