"""Configuration loading."""

import json


def load_config(config_file):
    with open(config_file) as f:
        return json.load(f)


def get_discord_webhook(config):
    webhook_file = config.get("discordWebhookFile")
    if webhook_file:
        try:
            with open(webhook_file) as f:
                return f.read().strip()
        except FileNotFoundError:
            pass
    return None
