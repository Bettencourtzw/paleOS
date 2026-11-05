import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class AuditFixes(unittest.TestCase):
    def fake(self, home, name, body):
        path = home / name
        path.write_text('#!/bin/bash\n' + body + '\n')
        path.chmod(0o755)

    def env(self, home):
        self.fake(home, 'systemd-run', 'exit 0')
        return {**os.environ, 'HOME': str(home), 'PATH': str(home) + ':' + os.environ['PATH']}

    def test_update_without_success_receipt_retries_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            h = Path(tmp); repo = h / 'repo'; repo.mkdir()
            (repo / '.git').mkdir()
            self.fake(h, 'git', 'case "$*" in *rev-parse*) echo abc ;; *diff*) echo install/system.sh ;; esac')
            self.fake(h, 'sudo', 'echo attempt >> "$HOME/attempts"; exit 1')
            env = {**self.env(h), 'PALEOS_DIR': str(repo)}
            for _ in range(2):
                run = subprocess.run(['bash', ROOT/'bin/paleos-update'], input='y\n', env=env, text=True, capture_output=True)
                self.assertNotEqual(run.returncode, 0)
                self.assertNotIn('up to date', run.stdout)
            self.assertEqual((h/'attempts').read_text(), 'attempt\nattempt\n')
            self.assertFalse((h/'.local/state/paleos/applied').exists())

    def test_background_only_apply_does_not_reload_hyprland(self):
        with tempfile.TemporaryDirectory() as tmp:
            h = Path(tmp)
            for cmd in ('hyprctl', 'systemctl'):
                self.fake(h, cmd, 'echo "$0 $*" >> "$HOME/calls"')
            subprocess.run([ROOT/'bin/paleos-apply'], env=self.env(h), check=True)
            (h/'calls').write_text('')
            settings = h/'.config/paleos/settings.json'; settings.parent.mkdir()
            settings.write_text('{"background":"Aurora"}')
            subprocess.run([ROOT/'bin/paleos-apply'], env=self.env(h), check=True)
            self.assertEqual((h/'calls').read_text(), '')

    def test_steam_explicit_amd_and_intel_vulkan(self):
        for vendor, driver in [('1002', 'radeon'), ('8086', 'intel')]:
            with self.subTest(vendor=vendor), tempfile.TemporaryDirectory() as tmp:
                h = Path(tmp)
                self.fake(h, 'lspci', f'echo "VGA controller [{vendor}:1234]"')
                run = subprocess.run(['bash', ROOT/'bin/paleos-gaming'], env={**self.env(h), 'PALEOS_GAMING_DRYRUN':'1'}, text=True, capture_output=True, check=True)
                self.assertIn('vulkan-' + driver, run.stdout.splitlines())
                self.assertIn('lib32-vulkan-' + driver, run.stdout.splitlines())

    def test_display_description_rule_preview_and_revert(self):
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); config=h/'.config/hypr/monitors.lua'; config.parent.mkdir(parents=True)
            original='hl.monitor({ output = "desc:Acme Monitor", position = "1920x0", vrr = 2, scale = 1 })\n'
            config.write_text(original)
            mon={'name':'DP-1','description':'Acme Monitor 123','width':1920,'height':1080,'refreshRate':60,'scale':1}
            self.fake(h, 'hyprctl', "printf '%s' '" + json.dumps([mon]) + "'")
            def run(*args):
                return subprocess.run([ROOT/'bin/display', *args], env=self.env(h), text=True, capture_output=True)
            self.assertEqual(run('set','scale','1.25').returncode, 0)
            self.assertEqual(config.read_text().count('hl.monitor'),1)
            self.assertIn('vrr = 2', config.read_text())
            self.assertGreater(json.loads(run('info').stdout)['confirmSeconds'], 0)
            self.assertEqual(run('revert').returncode,0)
            self.assertEqual(config.read_text(),original)
            self.assertNotEqual(run('set','hdr','on').returncode,0)
            self.assertEqual(config.read_text(),original)
            self.assertEqual(run('set','scale','1.5').returncode,0)
            self.assertEqual(run('confirm').returncode,0)
            self.assertFalse(Path(str(config)+'.pending').exists())
            self.assertIn('scale = 1.5',config.read_text())

    def test_display_expired_preview_restores_after_watchdog_loss(self):
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); config=h/'.config/hypr/monitors.lua'; config.parent.mkdir(parents=True)
            config.write_text('candidate')
            Path(str(config)+'.pending').write_text(json.dumps({'token':'test','deadline':0,'original':'original','candidate':'candidate'}))
            self.fake(h,'hyprctl','exit 0')
            subprocess.run([ROOT/'bin/display','confirm'],env=self.env(h),check=True)
            self.assertEqual(config.read_text(),'original')

    def test_user_install_backs_up_helpers_and_preserves_xkb_variant(self):
        if sys.platform != "linux": self.skipTest("Arch installer uses GNU tools")
        if os.geteuid() == 0: self.skipTest("user installer requires a non-root account")
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); (h/'.local/bin').mkdir(parents=True)
            (h/'.local/bin/menu').write_text('my custom menu')
            env={**self.env(h), 'PALEOS_XKB_LAYOUT':'us', 'PALEOS_XKB_VARIANT':'dvorak'}
            run=subprocess.run(['bash', ROOT/'install/user.sh'],env=env,text=True,capture_output=True)
            self.assertEqual(run.returncode,0,run.stderr)
            backups=list((h/'.config').glob('paleos-backup-*/bin/menu'))
            self.assertEqual(len(backups),1)
            self.assertEqual(backups[0].read_text(),'my custom menu')
            config=(h/'.config/hypr/hyprland.lua').read_text()
            self.assertIn('kb_layout = "us",',config)
            self.assertIn('kb_variant = "dvorak",',config)

    def test_installer_rejects_injection_before_disk_stage(self):
        source=(ROOT/'iso/airootfs/usr/local/bin/paleos-setup').read_text()
        validation=source.split('[[ $timezone =~',1)[1].split('localectl set-keymap',1)[0]
        validation='[[ $timezone =~'+validation
        for field,value in [('timezone','UTC;touch /tmp/paleos-injected'),('locale',"en_US.UTF-8'; false; '"),('keymap','us$(false)')]:
            with self.subTest(field=field):
                env={**os.environ,'timezone':'UTC','locale':'en_US.UTF-8','keymap':'us',field:value}
                run=subprocess.run(['bash','-c','die() { exit 23; }; '+validation],env=env,capture_output=True)
                self.assertEqual(run.returncode,23)
        hostname_check=source.split('  [[ $hostname =~',1)[1].split(' && break',1)[0]
        for hostname,valid in [('paleos',True),('my-pc',True),('my"pc',False),('-pc',False),('a'*64,False)]:
            run=subprocess.run(['bash','-c','[[ $hostname =~'+hostname_check],env={**os.environ,'hostname':hostname})
            self.assertEqual(run.returncode==0,valid)

    def test_chroot_does_not_activate_host_firewall_or_sysctl(self):
        source=(ROOT/'install/system.sh').read_text()
        block=source.split('chroot=${PALEOS_CHROOT:-0}',1)[1].split('findmnt -n /etc/resolv.conf',1)[0]
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp)
            for cmd in ['systemctl','sysctl','ufw','sed']:
                self.fake(h,cmd,'echo "'+cmd+' $*" >> "$HOME/calls"')
            self.fake(h,'systemd-detect-virt','exit 0')
            subprocess.run(['bash','-c','set -e; chroot=1; '+block],env=self.env(h),check=True)
            calls=(h/'calls').read_text()
            self.assertNotIn('ufw --force enable',calls)
            self.assertNotIn('sysctl ',calls)
            self.assertIn('systemctl enable systemd-resolved ufw',calls)

    def test_update_does_not_enable_login_screen_after_opt_out(self):
        source=(ROOT/'install/system.sh').read_text()
        block=source.split('choice=/var/lib/paleos/login-screen',1)[1].split('if [[ $login == y ]]; then',1)[0]
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); choice=h/'choice'; choice.write_text('n\n')
            block=block.replace('mkdir -p /var/lib/paleos','true')
            self.fake(h,'systemctl','echo unexpected-systemctl; exit 99')
            run=subprocess.run(['bash','-c','set -e; choice="$HOME/choice"; '+block+'test "$login" = n'],env={**self.env(h),'PALEOS_REAPPLY':'1','PALEOS_YES':'1'},capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stderr)
            self.assertNotIn('unexpected',run.stdout)
            self.assertEqual(choice.read_text(),'n\n')

    def test_pending_preview_from_previous_boot_restores_without_hyprctl(self):
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); config=h/'.config/hypr/monitors.lua'; config.parent.mkdir(parents=True)
            config.write_text('candidate')
            Path(str(config)+'.pending').write_text(json.dumps({'token':'test','deadline':9999999999,'boot':'previous-boot','original':'original','candidate':'candidate'}))
            self.fake(h,'hyprctl','echo unexpected; exit 99')
            run=subprocess.run([ROOT/'bin/display','recover-boot'],env=self.env(h),capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stderr)
            self.assertEqual(config.read_text(),'original')
            self.assertNotIn('unexpected',run.stdout)
        lua=(ROOT/'config/hypr/hyprland.lua').read_text()
        self.assertLess(lua.index('recover-boot'),lua.index('load(monitors_file)'))
        self.assertLess(lua.index('.pending'),lua.index('recover-boot'))   # Python only starts when needed

    def test_recover_boot_never_waits_for_a_live_preview_lock(self):
        # Hyprland runs recover-boot while `display set` holds the lock and waits on `hyprctl reload`
        import fcntl
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); config=h/'.config/hypr/monitors.lua'; config.parent.mkdir(parents=True)
            config.write_text('candidate')
            Path(str(config)+'.pending').write_text(json.dumps({'token':'test','deadline':0,'boot':'previous-boot','original':'original','candidate':'candidate'}))
            with open(str(config)+'.lock','w') as held:
                fcntl.flock(held, fcntl.LOCK_EX)
                run=subprocess.run([ROOT/'bin/display','recover-boot'],env=self.env(h),capture_output=True,text=True,timeout=5)
            self.assertEqual(run.returncode,0,run.stderr)
            self.assertEqual(config.read_text(),'candidate')

    def test_watcher_waits_for_a_deadline_extended_by_a_later_change(self):
        import time
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); config=h/'.config/hypr/monitors.lua'; config.parent.mkdir(parents=True)
            config.write_text('candidate'); pend=Path(str(config)+'.pending')
            pend.write_text(json.dumps({'token':'t','deadline':time.time()+1,'original':'original','candidate':'candidate'}))
            self.fake(h,'hyprctl','exit 0')
            w=subprocess.Popen([ROOT/'bin/display','watch','t'],env=self.env(h))
            time.sleep(0.5)
            pend.write_text(json.dumps({'token':'t','deadline':time.time()+1.5,'original':'original','candidate':'candidate'}))
            time.sleep(1)
            self.assertEqual(config.read_text(),'candidate')    # first deadline passed, but it was extended
            w.wait(timeout=5)
            self.assertEqual(config.read_text(),'original')

    def test_ssh_install_enables_firewall_after_allowing_management_peer(self):
        source=(ROOT/'install/system.sh').read_text()
        block=source.split('chroot=${PALEOS_CHROOT:-0}',1)[1].split('findmnt -n /etc/resolv.conf',1)[0]
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp)
            for cmd in ['systemctl','sysctl','ufw','sed']:
                self.fake(h,cmd,'echo "'+cmd+' $*" >> "$HOME/calls"')
            self.fake(h,'systemd-detect-virt','exit 1')
            subprocess.run(['bash','-c','set -e; chroot=0; '+block],env={**self.env(h),'SSH_CONNECTION':'10.0.2.2 12345 10.0.2.15 22'},check=True)
            calls=(h/'calls').read_text()
            self.assertLess(calls.index('ufw allow from 10.0.2.2 to any port 22 proto tcp'),calls.index('ufw --force enable'))

    def test_iso_installs_gpu_detection_before_gaming_helper(self):
        source=(ROOT/'iso/airootfs/usr/local/bin/paleos-setup').read_text()
        base=next(line for line in source.splitlines() if line.startswith('pkgs="base '))
        self.assertIn('pciutils',base)
        self.assertLess(source.index('pacstrap -K'),source.index('bash /root/paleos-gaming'))

    def test_legacy_nvidia_defers_steam_without_aborting_iso_install(self):
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp)
            self.fake(h,'lspci','echo "VGA NVIDIA GP104 [10de:1b80]"')
            self.fake(h,'pacman','exit 0')
            run=subprocess.run(['bash',ROOT/'bin/paleos-gaming'],env={**self.env(h),'PALEOS_GAMING_DRYRUN':'1'},capture_output=True,text=True)
            self.assertEqual(run.returncode,2,run.stderr)
        source=(ROOT/'iso/airootfs/usr/local/bin/paleos-setup').read_text()
        block=source.split('  if arch-chroot "$MNT" bash /root/paleos-gaming;',1)[1].split('  rm -f "$MNT/root/paleos-gaming"',1)[0]
        script='MNT=/unused; arch-chroot() { return 2; }; die() { exit 99; }; if arch-chroot "$MNT" bash /root/paleos-gaming;'+block
        run=subprocess.run(['bash','-c',script],capture_output=True,text=True)
        self.assertEqual(run.returncode,0,run.stderr)
        self.assertIn('Steam deferred',run.stdout)

    def test_steam_accepts_matching_legacy_variant_and_hybrid_integrated_gpu(self):
        cases=[('VGA NVIDIA GP104 [10de:1b80]', 'nvidia-580xx-utils', '580.1-1', '580.1-2', 0),
               ('VGA NVIDIA GP104 [10de:1b80]', 'nvidia-580xx-utils', '580.1-1', '580.2-1', 2),
               ('VGA NVIDIA AD104 [10de:1234]', 'nvidia-utils-beta', '600.1-1', '600.1-1', 0),
               ('VGA Intel [8086:1234]\n3D NVIDIA GP104 [10de:1b80]', '', '', '', 0)]
        for gpu,utils,version,version32,expected in cases:
            with self.subTest(gpu=gpu,utils=utils,version32=version32), tempfile.TemporaryDirectory() as tmp:
                h=Path(tmp)
                self.fake(h,'lspci',"printf '%s\\n' '"+gpu+"'")
                self.fake(h,'pacman',f'case "$*" in "-Qq") echo "{utils}" ;; "-Q {utils}") echo "{utils} {version}" ;; "-Q lib32-{utils}") echo "lib32-{utils} {version32}" ;; esac')
                run=subprocess.run(['bash',ROOT/'bin/paleos-gaming'],env={**self.env(h),'PALEOS_GAMING_DRYRUN':'1'},capture_output=True,text=True)
                self.assertEqual(run.returncode,expected,run.stderr+run.stdout)
                if expected==0:
                    self.assertIn('steam',run.stdout.splitlines())
                    self.assertNotIn('nvidia-utils',run.stdout.splitlines())
                    self.assertNotIn('lib32-nvidia-utils',run.stdout.splitlines())

if __name__ == '__main__': unittest.main()
