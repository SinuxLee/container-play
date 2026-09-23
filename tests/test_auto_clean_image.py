import importlib.util
import io
import json
import pathlib
import unittest
from unittest import mock


SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "combo/registry-updater/auto_clean_image.py"
SPEC = importlib.util.spec_from_file_location("auto_clean_image", SCRIPT)
cleaner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(cleaner)


class RegistryCleanerTests(unittest.TestCase):
    def test_reads_all_tag_pages(self):
        class Response(io.BytesIO):
            def __init__(self, tags, link=""):
                super().__init__(json.dumps({"tags": tags}).encode())
                self.headers = {"Link": link}

        client = cleaner.RegistryClient("http://registry:5000", "demo/app")
        client.open = mock.Mock(side_effect=[
            Response(["1.0"], '</v2/demo/app/tags/list?n=1&last=1.0>; rel="next"'),
            Response(["2.0"]),
        ])
        self.assertEqual(client.tags(), ["1.0", "2.0"])
        self.assertEqual(client.open.call_count, 2)

    def test_deletes_only_old_unique_manifests(self):
        digests = {"1.0": "sha256:old", "2.0": "sha256:new"}
        self.assertEqual(
            cleaner.plan_deletions(list(digests), 1, digests.__getitem__),
            ["sha256:old"],
        )

    def test_kept_numeric_tag_protects_shared_manifest(self):
        digests = {"1.0": "sha256:shared", "2.0": "sha256:shared"}
        self.assertEqual(cleaner.plan_deletions(list(digests), 1, digests.__getitem__), [])

    def test_nonnumeric_tag_protects_shared_manifest(self):
        digests = {"1.0": "sha256:shared", "2.0": "sha256:new", "latest": "sha256:shared"}
        self.assertEqual(cleaner.plan_deletions(list(digests), 1, digests.__getitem__), [])

    def test_default_is_dry_run(self):
        with mock.patch.object(cleaner, "RegistryClient") as client_type:
            client = client_type.return_value
            client.tags.return_value = ["1.0", "2.0"]
            client.digest.side_effect = {"1.0": "sha256:old", "2.0": "sha256:new"}.__getitem__
            self.assertEqual(cleaner.main(["--repo", "demo/app", "--keep", "1"]), 0)
            client.delete.assert_not_called()


if __name__ == "__main__":
    unittest.main()
