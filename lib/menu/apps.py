#!/usr/bin/env python3
# Prints installed apps as rofi rows and saves matching desktop IDs (same order) to $1.
import configparser, glob, html, os, sys
dirs = [os.path.expanduser("~/.local/share/applications"), "/usr/share/applications"]
seen, rows = set(), []
for d in dirs:
    for f in sorted(glob.glob(d + "/*.desktop")):
        did = os.path.basename(f)
        if did in seen: continue
        seen.add(did)
        c = configparser.RawConfigParser(strict=False, interpolation=None)
        try: c.read(f, encoding="utf-8")
        except Exception: continue
        if "Desktop Entry" not in c: continue
        e = c["Desktop Entry"]
        if e.get("Type") != "Application" or e.get("NoDisplay", "").lower() == "true" or e.get("Hidden", "").lower() == "true":
            continue
        rows.append((e.get("Name", did), e.get("Icon", "application-x-executable"), did, e.get("Keywords", "")))
rows.sort(key=lambda r: r[0].lower())
with open(sys.argv[1], "w") as ids:
    for name, icon, did, kw in rows:
        ids.write(did + "\n")
        sys.stdout.write(f"{html.escape(name, quote=False)}\0icon\x1f{icon}\x1fmeta\x1f{kw}\n")
