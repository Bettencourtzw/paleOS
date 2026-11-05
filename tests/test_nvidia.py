import os
import pathlib
import shlex
import subprocess
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class NvidiaInstallerTests(unittest.TestCase):
    def run_installer(self, packages, kernels, *, multilib=False, versions=None):
        versions = versions or {}
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            modules = root / "modules"
            for index, kernel in enumerate(kernels):
                module = modules / str(index)
                module.mkdir(parents=True)
                (module / "pkgbase").write_text(kernel + "\n")

            package_text = "\n".join(packages)
            version_cases = "\n".join(
                f"{shlex.quote(package)}) echo {shlex.quote(package + ' ' + version)} ;;"
                for package, version in versions.items()
            )
            pacman = root / "pacman"
            pacman.write_text(
                "#!/bin/sh\n"
                "case \"$1\" in\n"
                f"  -Qq) printf '%s\\n' {shlex.quote(package_text)} ;;\n"
                f"  -T) printf '%s\\n' {shlex.quote(package_text)} | grep -Eq '^nvidia-utils(-beta)?$|^nvidia-[0-9]+xx-utils$' ;;\n"
                "  -Q) case \"$2\" in\n"
                f"    {version_cases}\n"
                "    *) exit 1 ;;\n"
                "  esac ;;\n"
                "esac\n"
            )
            pacman.chmod(0o755)

            lspci = root / "lspci"
            lspci.write_text("#!/bin/sh\necho '01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD104 [GeForce RTX 4070] [10de:2786]'\n")
            lspci.chmod(0o755)

            pacman_conf = root / "pacman.conf"
            pacman_conf.write_text("[multilib]\n" if multilib else "[core]\n")
            env = {
                **os.environ,
                "PATH": str(root) + ":" + os.environ["PATH"],
                "PALEOS_NVIDIA_DRYRUN": "1",
                "PALEOS_MODULES_DIR": str(modules),
                "PALEOS_PACMAN_CONF": str(pacman_conf),
            }
            return subprocess.run(
                ["bash", ROOT / "install/nvidia.sh"],
                env=env,
                capture_output=True,
                text=True,
            )

    def test_existing_prebuilt_driver_refuses_uncovered_nonstock_kernel(self):
        result = self.run_installer(["linux", "linux-zen", "nvidia-open", "nvidia-utils"], ["linux", "linux-zen"])

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not cover kernel(s): linux-zen", result.stderr)
        self.assertNotIn("would run: pacman -S", result.stdout)

    def test_existing_open_driver_adds_matching_lts_module(self):
        result = self.run_installer(["linux", "linux-lts", "nvidia-open", "nvidia-utils"], ["linux", "linux-lts"])

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: pacman -S --needed --noconfirm libva-nvidia-driver nvidia-open-lts", result.stdout)

    def test_existing_dkms_driver_installs_headers_for_every_kernel(self):
        result = self.run_installer(["linux", "linux-zen", "nvidia-open-dkms", "nvidia-utils"], ["linux", "linux-zen"])

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("linux-headers linux-zen-headers", result.stdout)
        self.assertNotIn("nvidia-open-dkms linux-headers", result.stdout)

    def test_unknown_kernel_stops_before_package_changes(self):
        result = self.run_installer(["linux-cachyos", "nvidia-open-dkms", "nvidia-utils"], ["linux-cachyos"])

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot verify NVIDIA module coverage for kernel(s): linux-cachyos", result.stderr)
        self.assertNotIn("would run: pacman -S", result.stdout)

    def test_preserved_beta_driver_requires_matching_lib32_variant(self):
        result = self.run_installer(
            ["linux", "nvidia-open-beta-dkms", "nvidia-utils-beta"],
            ["linux"],
            multilib=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("matching lib32-nvidia-utils-beta package is not", result.stderr)
        self.assertNotIn("would run: pacman -S", result.stdout)

    def test_preserved_variant_rejects_mismatched_lib32_version(self):
        result = self.run_installer(
            ["linux", "nvidia-open-beta-dkms", "nvidia-utils-beta", "lib32-nvidia-utils-beta"],
            ["linux"],
            multilib=True,
            versions={"nvidia-utils-beta": "590.1-1", "lib32-nvidia-utils-beta": "590.0-1"},
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must have the same version", result.stderr)
        self.assertNotIn("would run: pacman -S", result.stdout)

    def test_preserved_legacy_driver_names_its_matching_lib32_variant(self):
        result = self.run_installer(
            ["linux", "nvidia-580xx-dkms", "nvidia-580xx-utils"],
            ["linux"],
            multilib=True,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("matching lib32-nvidia-580xx-utils package is not", result.stderr)
        self.assertNotIn("would run: pacman -S", result.stdout)

    def test_matching_preserved_variant_is_kept(self):
        result = self.run_installer(
            ["linux", "nvidia-open-beta-dkms", "nvidia-utils-beta", "lib32-nvidia-utils-beta"],
            ["linux"],
            multilib=True,
            versions={"nvidia-utils-beta": "590.1-2", "lib32-nvidia-utils-beta": "590.1-1"},
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would run: pacman -S --needed --noconfirm libva-nvidia-driver linux-headers", result.stdout)
        self.assertNotIn("lib32-nvidia-utils ", result.stdout)


if __name__ == "__main__":
    unittest.main()
