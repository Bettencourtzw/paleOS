#!/usr/bin/env python3
# Prints installed apps as rofi rows and saves matching desktop IDs (same order) to $1.
import configparser, glob, html, os, sys
# Same places every desktop looks (XDG spec), plus Flatpak's exports
home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
data = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
dirs = [home] + [os.path.expanduser("~/.local/share/flatpak/exports/share"), "/var/lib/flatpak/exports/share"] + data.split(":")
dirs = [d.rstrip("/") + "/applications" for d in dict.fromkeys(dirs) if d]
FLATPAK_ICONS = [os.path.expanduser("~/.local/share/flatpak/exports/share/icons/hicolor"), "/var/lib/flatpak/exports/share/icons/hicolor"]
def icon_path(name):
    """Flatpak icons live outside the normal icon theme dirs; return a file path for them."""
    if name.startswith("/"): return name
    for base in FLATPAK_ICONS:
        for size in ("scalable", "512x512", "256x256", "128x128", "64x64", "48x48"):
            for ext in ("svg", "png"):
                f = f"{base}/{size}/apps/{name}.{ext}"
                if os.path.exists(f): return f
    return name

# Developer/test tools that clutter the menu (same idea as Omarchy hiding them)
HIDE = {"qv4l2", "qvidcap", "rofi", "rofi-theme-selector", "avahi-discover", "bssh", "bvnc", "lstopo",
        "foot-server", "footclient", "uuctl", "jshell", "jconsole", "nvim", "kitty-open", "xgps", "xgpsspeed",
        "org.freedesktop.IBus.Setup", "cmake-gui", "electron", "lact"}

seen, rows = set(), []
for d in dirs:
    for f in sorted(glob.glob(d + "/*.desktop")):
        did = os.path.basename(f)
        if did in seen or did[:-8] in HIDE: continue
        seen.add(did)
        c = configparser.RawConfigParser(strict=False, interpolation=None)
        try: c.read(f, encoding="utf-8")
        except Exception: continue
        if "Desktop Entry" not in c: continue
        e = c["Desktop Entry"]
        if e.get("Type") != "Application" or e.get("NoDisplay", "").lower() == "true" or e.get("Hidden", "").lower() == "true":
            continue
        rows.append((e.get("Name", did), icon_path(e.get("Icon", "application-x-executable")), did, e.get("Keywords", "")))
rows.sort(key=lambda r: r[0].lower())
with open(sys.argv[1], "w") as ids:
    for name, icon, did, kw in rows:
        ids.write(did + "\n")
        sys.stdout.write(f"{html.escape(name, quote=False)}\0icon\x1f{icon}\x1fmeta\x1f{kw}\n")
