#!/usr/bin/env python3

import importlib
import json
import pathlib
import sys
import tempfile
import types
import unittest


class AlertingDigestTest(unittest.TestCase):
    def setUp(self):
        fake_click = types.ModuleType("click")
        fake_click.echo = lambda *args, **kwargs: None
        fake_click.ClickException = Exception
        sys.modules["click"] = fake_click

        # Make digest.py importable from the sibling discord package.
        self.discord_dir = str(pathlib.Path(__file__).resolve().parent.parent / "discord")
        if self.discord_dir not in sys.path:
            sys.path.insert(0, self.discord_dir)

        self.tmp = tempfile.TemporaryDirectory()
        self.state_file = pathlib.Path(self.tmp.name) / "pending.json"
        self.webhook_file = pathlib.Path(self.tmp.name) / "webhook"
        self.webhook_file.write_text("https://discord.example/webhook\n")

        sys.modules.pop("digest", None)
        sys.modules.pop("alerting", None)
        self.digest = importlib.import_module("digest")
        self.alerting = importlib.import_module("alerting")
        self.alerting.configure_alerts(
            webhook_file=str(self.webhook_file),
            state_file=str(self.state_file),
        )

    def tearDown(self):
        for mod in ("alerting", "digest", "click"):
            sys.modules.pop(mod, None)
        if self.discord_dir in sys.path:
            sys.path.remove(self.discord_dir)
        self.tmp.cleanup()

    def _pending(self):
        if not self.state_file.exists():
            return {}
        return json.loads(self.state_file.read_text()).get("pending", {})

    def test_failure_is_recorded_not_sent(self):
        self.alerting.alert("ignored", "`repo`: fetch failed — detail")
        self.assertEqual(len(self._pending()), 1)

    def test_same_failure_collapses_to_one_entry(self):
        self.alerting.alert("x", "`repo`: fetch failed — first detail")
        self.alerting.alert("x", "`repo`: fetch failed — second detail")
        self.assertEqual(len(self._pending()), 1)

    def test_success_clears_pending_for_that_repo_only(self):
        self.alerting.alert("x", "`repo-a`: failed")
        self.alerting.alert("x", "`repo-b`: failed")
        self.assertEqual(len(self._pending()), 2)

        self.alerting.clear_alerts_for_repo("repo-a")
        pending = self._pending()
        self.assertEqual(len(pending), 1)
        self.assertTrue(
            any("`repo-b`" in v["message"] for v in pending.values())
        )

    def test_flush_posts_and_clears(self):
        self.alerting.alert("x", "`repo-a`: failed")
        sent = []
        self.digest.flush(
            lambda url, content: sent.append((url, content)) or True,
            state_file=str(self.state_file),
        )
        self.assertEqual(len(sent), 1)
        self.assertEqual(sent[0][0], "https://discord.example/webhook")
        self.assertEqual(self._pending(), {})


if __name__ == "__main__":
    unittest.main()
