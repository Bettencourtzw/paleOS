import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]

@unittest.skipUnless(importlib.util.find_spec('gi'), 'Requires Arch python-gobject')
class DesktopLaunch(unittest.TestCase):
    def launch_fixture(self, terminal=False):
        with tempfile.TemporaryDirectory() as tmp:
            h=Path(tmp); capture=h/'capture.py'; output=h/'args.json'
            capture.write_text('import json,sys\nfrom pathlib import Path\nPath(sys.argv[1]).write_text(json.dumps(sys.argv[2:]))\n')
            desktop=h/'fresh.desktop'
            desktop.write_text('[Desktop Entry]\nType=Application\nName=Fresh App\nDBusActivatable=true\nExec=/usr/bin/python '+str(capture)+' '+str(output)+' "two  spaces" %c %k %% "$HOME"\nTerminal='+str(terminal).lower()+'\n')
            run=subprocess.run([ROOT/'bin/paleos-launch',desktop],capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stderr)
            deadline=time.monotonic()+5
            while not output.exists() and time.monotonic()<deadline: time.sleep(.05)
            self.assertTrue(output.exists(),run.stderr)
            self.assertEqual(json.loads(output.read_text()),['two  spaces','Fresh App',str(desktop),'%','$HOME'])

    def test_fresh_dbus_entry_quoted_fields_and_literal_shell_text(self):
        self.launch_fixture()

    @unittest.skipUnless(os.environ.get('WAYLAND_DISPLAY'), 'Requires desktop session for Terminal=true')
    def test_terminal_entry_launches(self):
        self.launch_fixture(terminal=True)

if __name__ == '__main__': unittest.main()
