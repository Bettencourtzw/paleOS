//! pale-apps — lists installed apps for the paleOS menu.
//! Usage: pale-apps <ids-file>
//! Prints one rofi row per app ("Name\0icon\x1f<icon>\x1fmeta\x1f<keywords>") and
//! writes the desktop file path to start each app, in the same order, to <ids-file>.
//! GLib launches desktop entries with their quoting, field codes and terminal semantics.
use std::collections::HashSet;
use std::env;
use std::fs;
use std::io::{self, BufWriter, Write};
use std::path::{Path, PathBuf};

/// Developer / test tools that only clutter the menu.
const HIDE: &[&str] = &[
    "qv4l2", "qvidcap", "rofi", "rofi-theme-selector", "avahi-discover", "bssh", "bvnc", "lstopo",
    "foot-server", "footclient", "uuctl", "jshell", "jconsole", "nvim", "kitty-open", "xgps",
    "xgpsspeed", "org.freedesktop.IBus.Setup", "cmake-gui", "electron",
];

struct App { name: String, icon: String, cmd: String, keywords: String }

/// Same places every desktop looks (XDG spec), plus Flatpak's exports.
fn data_dirs(home: &Path) -> Vec<PathBuf> {
    let data_home = env::var_os("XDG_DATA_HOME").map(PathBuf::from).unwrap_or_else(|| home.join(".local/share"));
    let mut dirs = vec![data_home, home.join(".local/share/flatpak/exports/share"), PathBuf::from("/var/lib/flatpak/exports/share")];
    let sys = env::var("XDG_DATA_DIRS").unwrap_or_else(|_| "/usr/local/share:/usr/share".into());
    dirs.extend(sys.split(':').filter(|d| !d.is_empty()).map(PathBuf::from));
    let mut seen = HashSet::new();
    dirs.retain(|d| seen.insert(d.clone()));
    dirs
}

/// Flatpak icons live outside the icon theme search path; resolve them to a file.
fn icon_path(name: &str, home: &Path) -> String {
    if name.starts_with('/') { return name.to_string(); }
    let bases = [home.join(".local/share/flatpak/exports/share/icons/hicolor"), PathBuf::from("/var/lib/flatpak/exports/share/icons/hicolor")];
    for base in &bases {
        for size in ["scalable", "512x512", "256x256", "128x128", "64x64", "48x48"] {
            for ext in ["svg", "png"] {
                let f = base.join(size).join("apps").join(format!("{name}.{ext}"));
                if f.exists() { return f.to_string_lossy().into_owned(); }
            }
        }
    }
    name.to_string()
}

/// Reads the [Desktop Entry] group; None if the app should not be shown.
fn parse(path: &Path, id: &str, home: &Path) -> Option<App> {
    let text = fs::read_to_string(path).ok()?;
    let (mut in_entry, mut name, mut icon, mut kw, mut kind) = (false, None, None, String::new(), "");
    let mut exec = String::new();
    for line in text.lines() {
        let line = line.trim();
        if line.starts_with('[') { if in_entry { break; } in_entry = line == "[Desktop Entry]"; continue; }
        if !in_entry { continue; }
        let Some((k, v)) = line.split_once('=') else { continue };
        match k.trim() {
            "Name" => name = Some(v.trim().to_string()),
            "Icon" => icon = Some(v.trim().to_string()),
            "Keywords" => kw = v.trim().to_string(),
            "Exec" => exec = v.trim().to_string(),
            "Type" => kind = if v.trim() == "Application" { "app" } else { "other" },
            "NoDisplay" | "Hidden" if v.trim().eq_ignore_ascii_case("true") => return None,
            _ => {}
        }
    }
    if kind != "app" || exec.is_empty() { return None; }
    let cmd = path.to_string_lossy().into_owned();
    Some(App {
        name: name.unwrap_or_else(|| id.to_string()),
        icon: icon_path(icon.as_deref().unwrap_or("application-x-executable"), home),
        cmd,
        keywords: kw,
    })
}

fn escape(s: &str) -> String { s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;") }

fn main() -> io::Result<()> {
    let ids_file = env::args().nth(1).unwrap_or_else(|| "/dev/null".into());
    let home = PathBuf::from(env::var_os("HOME").unwrap_or_default());
    let (mut seen, mut apps) = (HashSet::new(), Vec::new());
    for dir in data_dirs(&home) {
        let Ok(rd) = fs::read_dir(dir.join("applications")) else { continue };
        let mut entries: Vec<_> = rd.flatten().map(|e| e.path()).filter(|p| p.extension().is_some_and(|e| e == "desktop")).collect();
        entries.sort();
        for path in entries {
            let id = path.file_name().unwrap().to_string_lossy().into_owned();
            let stem = id.trim_end_matches(".desktop");
            if HIDE.contains(&stem) || !seen.insert(id.clone()) { continue; }
            if let Some(app) = parse(&path, &id, &home) { apps.push(app); }
        }
    }
    apps.sort_by_key(|a| a.name.to_lowercase());
    let (mut out, mut ids) = (BufWriter::new(io::stdout().lock()), BufWriter::new(fs::File::create(&ids_file)?));
    for a in &apps {
        writeln!(ids, "{}", a.cmd)?;
        write!(out, "{}\0icon\x1f{}\x1fmeta\x1f{}\n", escape(&a.name), a.icon, a.keywords)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn keeps_desktop_identity_instead_of_reinterpreting_exec() {
        let dir = env::temp_dir().join(format!("pale-apps-test-{}", std::process::id()));
        fs::create_dir_all(&dir).unwrap();
        let path = dir.join("quoted.desktop");
        fs::write(&path, "[Desktop Entry]\nType=Application\nName=Quoted App\nExec=tool \\\"two  spaces\\\" %c %k %%\nTerminal=true\n").unwrap();
        let app = parse(&path, "quoted.desktop", &dir).unwrap();
        assert_eq!(app.cmd, path.to_string_lossy());
        fs::remove_dir_all(dir).unwrap();
    }
}
