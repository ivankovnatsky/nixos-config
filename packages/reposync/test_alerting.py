#!/usr/bin/env python3

import importlib
import pathlib
import sys
import tempfile
import types
import unittest


class AlertingTest(unittest.TestCase):
    def setUp(self):
        fake_click = types.ModuleType("click")
        fake_click.echo = lambda *args, **kwargs: None
        fake_click.ClickException = Exception
        sys.modules["click"] = fake_click

        fake_discord = types.ModuleType("discord")
        fake_discord.send_discord = lambda *args, **kwargs: True
        sys.modules["discord"] = fake_discord

        self.tmp = tempfile.TemporaryDirectory()
        self.state_file = pathlib.Path(self.tmp.name) / "alerts.json"
        self.sent = []
        self.now = 1000

        sys.modules.pop("alerting", None)
        self.alerting = importlib.import_module("alerting")
        self.alerting.configure_alerts(60, self.state_file)
        self.alerting._send_discord = self.send_discord
        self.original_time = self.alerting.time.time
        self.alerting.time.time = lambda: self.now

    def tearDown(self):
        self.alerting.time.time = self.original_time
        sys.modules.pop("alerting", None)
        sys.modules.pop("click", None)
        sys.modules.pop("discord", None)
        self.tmp.cleanup()

    def send_discord(self, webhook_url, message, **kwargs):
        self.sent.append((webhook_url, message, kwargs))
        return True

    def test_suppresses_repeated_alert_until_repeat_window_expires(self):
        self.alerting.alert("https://discord.example/webhook", "same failure")
        self.alerting.alert("https://discord.example/webhook", "same failure")

        self.assertEqual(len(self.sent), 1)

        self.now += 61
        self.alerting.alert("https://discord.example/webhook", "same failure")

        self.assertEqual(len(self.sent), 2)

    def test_suppresses_same_failure_with_different_details(self):
        webhook = "https://discord.example/webhook"
        self.alerting.alert(webhook, "`repo`: fetch failed — first detail")
        self.alerting.alert(webhook, "`repo`: fetch failed — second detail")

        self.assertEqual(len(self.sent), 1)

    def test_clear_alert_state_allows_immediate_repeat_after_success(self):
        self.alerting.alert("https://discord.example/webhook", "same failure")
        self.alerting.clear_alert_state()
        self.alerting.alert("https://discord.example/webhook", "same failure")

        self.assertEqual(len(self.sent), 2)


if __name__ == "__main__":
    unittest.main()
