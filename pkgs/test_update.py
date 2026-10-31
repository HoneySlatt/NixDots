import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("updater", Path(__file__).with_name("update.py"))
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)
HASH = "sha256-" + "A" * 43 + "="


class UpdateTests(unittest.TestCase):
    def test_github_skips_prereleases_and_non_linux_releases(self):
        releases = [
            ("nym-vpn-v9.0", True, "nym-vpn-core-v9.0_linux_x86_64.tar.gz"),
            ("nym-vpn-v8.0", False, "android.apk"),
            ("nym-vpn-v7.0", False, "nym-vpn-core-v7.0_linux_x86_64.tar.gz"),
        ]
        data = [dict(tag_name=tag, prerelease=pre, draft=False, assets=[dict(name=asset)])
                for tag, pre, asset in releases]
        with patch.object(updater, "fetch", return_value=json.dumps(data)):
            self.assertEqual(updater.latest_pin("nym-vpnd"), ("7.0", None))

    def test_nuvio_preserves_alpha_version(self):
        release = dict(tag_name="1.0-alpha", prerelease=False, draft=False,
                       assets=[dict(name="Nuvio-Linux-x86_64-1.0-alpha.AppImage")])
        with patch.object(updater, "fetch", return_value=json.dumps([release])):
            self.assertEqual(updater.latest_pin("nuvio"), ("1.0-alpha", None))

    def test_missing_linux_release_is_an_error(self):
        with patch.object(updater, "fetch", return_value="[]"):
            with self.assertRaises(ValueError):
                updater.latest_pin("rqbit-desktop")

    def test_kimi_desktop_manifest_and_official_fallback(self):
        with patch.object(updater, "fetch", side_effect=[
            subprocess.CalledProcessError(22, "curl"), "version: 1.2.3\nfiles:\n",
        ]) as fetch:
            self.assertEqual(updater.latest_pin("kimi-code-desktop"), ("1.2.3", None))
            self.assertIn("code.kimi.com", fetch.call_args.args[0])

    def test_zcode_uses_highest_linux_version(self):
        page = " ".join(f"https://cdn-zcode.z.ai/zcode/electron/releases/{v}/{arch}/file"
                        for v, arch in [("3.9.0", "linux-x64"), ("3.10.0", "linux-x64"),
                                        ("4.0.0", "macos-arm64")])
        with patch.object(updater, "fetch", return_value=page):
            self.assertEqual(updater.latest_pin("zcode"), ("3.10.0", None))

    def test_prefetch_uses_versioned_url_and_recursive_git_hash(self):
        text = '    url = "https://example.com/${version}/app.tar.gz";\n'
        with patch.object(updater, "output", return_value=json.dumps(dict(hash=HASH))) as output:
            self.assertEqual(updater.prefetch(text, "2.0", None), HASH)
            self.assertEqual(output.call_args.args[-1], "https://example.com/2.0/app.tar.gz")
            self.assertEqual(updater.prefetch(text, "2.0", "f" * 40), HASH)
            self.assertIn("--fetch-submodules", output.call_args.args)

    def test_failed_prefetch_does_not_edit_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            file = root / "pkgs/nuvio/default.nix"
            file.parent.mkdir(parents=True)
            original = '  version = "1.0";\n    hash = "old";\n'
            file.write_text(original)
            with patch.object(updater, "latest_pin", return_value=("2.0", None)), \
                 patch.object(updater, "prefetch", side_effect=subprocess.CalledProcessError(1, "nix")):
                with self.assertRaises(subprocess.CalledProcessError):
                    updater.update(root, "nuvio")
            self.assertEqual(file.read_text(), original)

    def test_all_packages_build_and_keep_unrelated_text(self):
        for package in updater.PACKAGES:
            with self.subTest(package=package), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                file = root / "pkgs" / package / "default.nix"
                file.parent.mkdir(parents=True)
                original = (Path(__file__).parent / package / "default.nix").read_text()
                original += "\n# unrelated local work\n"
                file.write_text(original)
                revision = "f" * 40 if package == "kytyps5" else None
                latest = "0-unstable-2099-01-01" if revision else "99.0.0"
                with patch.object(updater, "latest_pin", return_value=(latest, revision)), \
                     patch.object(updater, "prefetch", return_value=HASH), \
                     patch.object(updater.subprocess, "run") as build:
                    updater.update(root, package)
                expected = updater.replace_field(original, "version", latest)
                expected = updater.replace_field(expected, "hash", HASH)
                if revision:
                    expected = updater.replace_field(expected, "rev", revision)
                self.assertEqual(file.read_text(), expected)
                self.assertIn(f"path:{root}#nixosConfigurations.desktop.pkgs.{package}", build.call_args.args[0])
                self.assertIn("--no-write-lock-file", build.call_args.args[0])

    def test_no_change_skips_prefetch_and_build(self):
        current = updater.field((Path(__file__).parent / "kimi-code/default.nix").read_text(), "version")
        with patch.object(updater, "latest_pin", return_value=(current, None)), \
             patch.object(updater, "prefetch") as prefetch, \
             patch.object(updater.subprocess, "run") as build:
            updater.update(Path(__file__).resolve().parent.parent, "kimi-code")
        prefetch.assert_not_called()
        build.assert_not_called()

    def test_failed_build_restores_exact_original(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            file = root / "pkgs/nuvio/default.nix"
            file.parent.mkdir(parents=True)
            original = '  version = "1.0";\n    hash = "old";\n# local changes\n'
            file.write_text(original)
            with patch.object(updater, "latest_pin", return_value=("2.0", None)), \
                 patch.object(updater, "prefetch", return_value=HASH), \
                 patch.object(updater.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "nix")):
                with self.assertRaises(subprocess.CalledProcessError):
                    updater.update(root, "nuvio")
            self.assertEqual(file.read_text(), original)

    def test_rejects_ambiguous_fields_and_unsafe_versions(self):
        with self.assertRaises(ValueError):
            updater.replace_field('  hash = "one";\n  hash = "two";\n', "hash", HASH)
        for value in ("", "null", '1.0"; injected', "../1.0"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                updater.version(value)

    def test_all_updates_every_package(self):
        with patch.object(updater.sys, "argv", ["update.py", "all"]), \
             patch.object(updater, "update") as update:
            self.assertEqual(updater.main(), 0)
        self.assertEqual([call.args[1] for call in update.call_args_list], list(updater.PACKAGES))

    def test_all_continues_after_failure_and_returns_error(self):
        failures = [ValueError("upstream unavailable")] + [None] * (len(updater.PACKAGES) - 1)
        with patch.object(updater.sys, "argv", ["update.py", "all"]), \
             patch.object(updater, "update", side_effect=failures) as update, \
             patch.object(updater.sys, "stderr") as stderr:
            self.assertEqual(updater.main(), 1)
        self.assertEqual([call.args[1] for call in update.call_args_list], list(updater.PACKAGES))
        self.assertIn("Failed packages: nym-vpnd", "".join(call.args[0] for call in stderr.write.call_args_list))

    def test_single_package_still_updates_only_that_package(self):
        with patch.object(updater.sys, "argv", ["update.py", "nuvio"]), \
             patch.object(updater, "update") as update:
            self.assertEqual(updater.main(), 0)
        update.assert_called_once_with(Path(updater.__file__).resolve().parent.parent, "nuvio")


if __name__ == "__main__":
    unittest.main()
