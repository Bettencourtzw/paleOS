import json
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class Regressions(unittest.TestCase):
    def test_display_lists_low_refresh_modes(self):
        monitor = {"width": 1920, "height": 1080, "availableModes": ["3840x2160@30.00Hz", "1920x1080@60.00Hz", "1920x1080@50.00Hz"]}
        with tempfile.TemporaryDirectory() as tmp:
            hyprctl = pathlib.Path(tmp) / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            result = subprocess.run([ROOT / "bin/display", "modes"], env={**os.environ, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            rates = subprocess.run([ROOT / "bin/display", "rates"], env={**os.environ, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(result.stdout)[0], {"resolution": "3840x2160", "rates": [30]})
        self.assertEqual(rates.stdout, "60\n50\n")

    def test_display_preserves_monitor_position_and_other_settings(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            config.write_text('hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "1920x0", scale = 1, vrr = 0, mirror = "DP-2" })\n')
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            self.assertEqual(config.read_text(), 'hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "1920x0", scale = 1.25, vrr = 0, mirror = "DP-2" })\n')

    def test_display_adds_a_missing_setting_to_a_custom_monitor(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            config.write_text('hl.monitor({ output = "DP-1", position = "1920x0", })\n')
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            self.assertEqual(config.read_text(), 'hl.monitor({ scale = 1.25, output = "DP-1", position = "1920x0", })\n')

    def test_display_adds_a_setting_without_breaking_comments_or_spaced_closing(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        examples = ['hl.monitor({\n output = "DP-1",\n mode = "preferred", -- default mode\n})\n',
                    'hl.monitor({ output = "DP-1", position = "0x0" } )\n']
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            for example in examples:
                with self.subTest(example=example):
                    config.write_text(example)
                    subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
                    self.assertEqual(config.read_text().count('hl.monitor('), 1)
                    self.assertIn('scale = 1.25', config.read_text())
                    subprocess.run(["luac", "-p", config], capture_output=True, text=True, check=True)

    def test_display_updates_multiline_monitor_without_moving_it(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            config.write_text('hl.monitor({\n    output = "DP-1",\n    position = "1920x0",\n    scale = 1,\n})\n')
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            self.assertEqual(config.read_text(), 'hl.monitor({\n    output = "DP-1",\n    position = "1920x0",\n    scale = 1.25,\n})\n')

    def test_display_ignores_commented_monitor_fields(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        content = 'hl.monitor({\n -- output = "DP-1",\n output = "DP-2",\n scale = 1,\n})\nhl.monitor({\n output = "DP-1",\n -- previous scale = 1,\n scale = 2,\n})\n'
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            config.write_text(content)
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            self.assertEqual(config.read_text(), content.replace('scale = 2,', 'scale = 1.25,'))

    def test_display_does_not_corrupt_lua_expressions(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            for expression in ("math.max(1, 1.5)", "1 + 0.5"):
                with self.subTest(expression=expression):
                    original = f'hl.monitor({{ output = "DP-1", scale = {expression} }})\n'
                    config.write_text(original)
                    result = subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(config.read_text(), original)

    def test_display_does_not_override_monitor_with_variable_output(self):
        monitor = {"name": "DP-1", "width": 1920, "height": 1080, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            home = pathlib.Path(tmp)
            config = home / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            hyprctl = home / "hyprctl"
            hyprctl.write_text("#!/bin/sh\nprintf '%s' '" + json.dumps([monitor]) + "'\n")
            hyprctl.chmod(0o755)
            for original in ('local screen = "DP-1"; hl.monitor({ output = screen, position = "1920x0", scale = 1 })\n',
                             'local monitor = { output = "DP-1", position = "1920x0" }; hl.monitor(monitor)\n'):
                with self.subTest(original=original):
                    config.write_text(original)
                    result = subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(config.read_text(), original)

    def test_iso_build_preserves_existing_work_directory(self):
        source = (ROOT / "iso/build.sh").read_text()
        setup = source.split("REPO=$(cd", 1)[1].split('cp -r /usr/share/archiso', 1)[0]
        setup = setup.split("\n", 1)[1]
        with tempfile.TemporaryDirectory() as tmp:
            marker = pathlib.Path(tmp) / "keep.txt"
            marker.write_text("important")
            subprocess.run(["bash", "-c", "set -e\n" + setup], env={**os.environ, "REPO": str(ROOT), "WORK": tmp}, capture_output=True, text=True, check=True)
            self.assertTrue(marker.exists(), "ISO build removed existing files")
            self.assertEqual(marker.read_text(), "important")

    def test_iso_build_rejects_work_directory_inside_source(self):
        source = (ROOT / "iso/build.sh").read_text()
        setup = source.split("REPO=$(cd", 1)[1].split('cp -r /usr/share/archiso', 1)[0]
        setup = setup.split("\n", 1)[1]
        with tempfile.TemporaryDirectory(dir=ROOT) as tmp:
            result = subprocess.run(["bash", "-c", "set -e\n" + setup], env={**os.environ, "REPO": str(ROOT), "WORK": tmp}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)

    def test_btrfs_setup_stops_after_first_subvolume_failure(self):
        source = (ROOT / "iso/airootfs/usr/local/bin/paleos-setup").read_text()
        command = next(line for line in source.splitlines() if 'run "Creating btrfs"' in line)
        script = '''
            rootdev=/dev/test MNT=/mnt/test
            mkfs.btrfs() { :; }
            mount() { :; }
            umount() { :; }
            btrfs() { [[ $3 != /mnt/test/@ ]]; }
            export -f mkfs.btrfs mount umount btrfs
            run() { bash -c "$2"; }
        ''' + command
        result = subprocess.run(["bash", "-c", script], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)

    def test_steam_install_upgrades_the_system(self):
        with tempfile.TemporaryDirectory() as tmp:
            launcher = pathlib.Path(tmp) / "setsid"
            launcher.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$CAPTURE"\n')
            launcher.chmod(0o755)
            capture = pathlib.Path(tmp) / "command"
            subprocess.run([ROOT / "bin/menu", "install-gaming", "Steam"], env={**os.environ, "PATH": tmp + ":" + os.environ["PATH"], "CAPTURE": str(capture)}, capture_output=True, text=True, check=True)
            self.assertIn("pacman -Syu --needed steam", capture.read_text())

    def test_erased_disk_finds_reused_partition_numbers(self):
        source = (ROOT / "iso/airootfs/usr/local/bin/paleos-setup").read_text()
        disk_code = source.split("part() {", 1)[1].split("[[ -b $esp", 1)[0]
        script = '''
            disk=/dev/test mode='Erase the whole disk'
            lsblk() {
                case "$*" in
                    *NAME,PARTN*) printf '/dev/test1 1\\n/dev/test2 2\\n' ;;
                    *) printf '1\\n2\\n' ;;
                esac
            }
            run() { :; }
            part() {'''+ disk_code + '''
            printf '%s %s' "$esp" "$rootp"
        '''
        result = subprocess.run(["bash", "-c", script], capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout, "/dev/test1 /dev/test2")

    def test_erase_stops_if_wipe_fails(self):
        source = (ROOT / "iso/airootfs/usr/local/bin/paleos-setup").read_text()
        disk_code = source.split("part() {", 1)[1].split("[[ -b $esp", 1)[0]
        script = '''
            set -e
            disk=/dev/test mode='Erase the whole disk'
            lsblk() { printf '1\\n2\\n'; }
            wipefs() { return 1; }
            sgdisk() { return 0; }
            export -f wipefs sgdisk
            run() { if [[ $1 == Creating* ]]; then touch "$1.marker"; return 1; fi; bash -c "$2"; }
            part() {'''+ disk_code
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(["bash", "-c", script], cwd=tmp, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((pathlib.Path(tmp) / "Creating partitions.marker").exists())


    def _fake(self, tmp, name, script):
        f = pathlib.Path(tmp) / name
        f.write_text("#!/bin/sh\n" + script + "\n")
        f.chmod(0o755)

    def test_display_scales_are_every_whole_pixel_scale(self):
        monitor = {"name": "DP-1", "width": 3440, "height": 1440, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            self._fake(tmp, "hyprctl", "printf '%s' '" + json.dumps([monitor]) + "'")
            out = subprocess.run([ROOT / "bin/display", "scales"], env={**os.environ, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True).stdout
        scales = [float(x) for x in out.split()]
        self.assertEqual(scales, [1.0, 1.0667, 1.25, 1.3333, 1.6, 1.6667, 2.0])
        for s in scales:   # 4 decimals is close enough for Hyprland to pick this exact scale
            k = round(s * 120)
            self.assertEqual((120 * 3440 % k, 120 * 1440 % k), (0, 0))

    def test_display_adds_first_monitor_to_default_file(self):
        monitor = {"name": "DP-1", "width": 2560, "height": 1440, "refreshRate": 59.95, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            config = pathlib.Path(tmp) / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            config.write_text((ROOT / "config/hypr/monitors.lua").read_text())
            self._fake(tmp, "hyprctl", "printf '%s' '" + json.dumps([monitor]) + "'")
            subprocess.run([ROOT / "bin/display", "set", "scale", "1.25"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            text = config.read_text()
        self.assertIn('hl.monitor({ output = "DP-1", position = "auto", vrr = 0, mode = "2560x1440@60", scale = 1.25 })', text)
        self.assertEqual(text.count("\nhl.monitor("), 1)

    def test_nvidia_step_skips_pcs_without_nvidia_and_old_cards(self):
        cases = {"01:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [1002:744c]": "",
                 "01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP104 [GeForce GTX 1080] [10de:1b80]": "legacy driver"}
        for line, expect in cases.items():
            with self.subTest(line=line), tempfile.TemporaryDirectory() as tmp:
                self._fake(tmp, "lspci", f"echo '{line}'")
                self._fake(tmp, "pacman", "echo SHOULD-NOT-RUN; exit 1")
                r = subprocess.run(["bash", ROOT / "install/nvidia.sh"], env={**os.environ, "PALEOS_NVIDIA_DRYRUN": "1", "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True)
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertNotIn("would run", r.stdout)
                self.assertIn(expect, r.stdout)

    def test_nvidia_step_installs_open_driver_for_stock_kernel(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fake(tmp, "lspci", "echo '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD104 [GeForce RTX 4070] [10de:2786]'")
            self._fake(tmp, "pacman", 'case "$*" in "-Qq") echo base; echo linux ;; "-Qq linux"*) echo linux ;; esac')
            r = subprocess.run(["bash", ROOT / "install/nvidia.sh"], env={**os.environ, "PALEOS_NVIDIA_DRYRUN": "1", "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
        self.assertIn("would run: pacman -S --needed --noconfirm nvidia-utils libva-nvidia-driver nvidia-open", r.stdout)
        self.assertIn("nvidia-suspend.service", r.stdout)

    def test_display_edits_the_line_saved_for_a_new_monitor(self):
        # hyprland.lua saves this line the first time a monitor is connected; the Display panel must edit it in place
        monitor = {"name": "DP-2", "width": 3440, "height": 1440, "refreshRate": 60, "scale": 1}
        with tempfile.TemporaryDirectory() as tmp:
            config = pathlib.Path(tmp) / ".config/hypr/monitors.lua"
            config.parent.mkdir(parents=True)
            config.write_text((ROOT / "config/hypr/monitors.lua").read_text()
                              + 'hl.monitor({ output = "DP-2", position = "auto", vrr = 0, mode = "3440x1440@60", scale = 1 })\n')
            self._fake(tmp, "hyprctl", "printf '%s' '" + json.dumps([monitor]) + "'")
            subprocess.run([ROOT / "bin/display", "set", "mode", "3440x1440@240"], env={**os.environ, "HOME": tmp, "PATH": tmp + ":" + os.environ["PATH"]}, capture_output=True, text=True, check=True)
            text = config.read_text()
        self.assertTrue(text.endswith('hl.monitor({ output = "DP-2", position = "auto", vrr = 0, mode = "3440x1440@240", scale = 1 })\n'))
        self.assertEqual(text.count("\nhl.monitor("), 1)

if __name__ == "__main__":
    unittest.main()
