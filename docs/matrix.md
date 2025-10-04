# Matrix Setup

## Configuration

Synapse homeserver runs on bee (192.168.50.3:8008).

Server name: `matrix.${config.secrets.externalDomain}`

Registration enabled without verification.

## Accessing Matrix

Homeserver URL: `https://matrix.${config.secrets.externalDomain}`

Request flow:
1. Client → matrix.${externalDomain} (wildcard DNS)
2. Caddy (mini or bee) → Synapse at bee (192.168.50.3:8008)

Note: Both mini and bee run Caddy with identical config and can proxy to Synapse.
Both machines also run local DNS resolvers.

## Registration

Use Element or any Matrix client:
1. Set homeserver: `https://matrix.${externalDomain}`
2. Register with username and password
3. User ID format: `@username:matrix.${externalDomain}`

## Telegram Bridge (mautrix-telegram)

### Authentication

1. Start chat with: `@telegrambot:matrix.${externalDomain}`
2. Send: `login`
3. Follow authentication flow (phone number, verification code, 2FA if enabled)

Reference: https://docs.mau.fi/bridges/python/telegram/authentication.html

### Troubleshooting

**Token mismatch errors after config changes:**

```console
sudo systemctl stop mautrix-telegram.service matrix-synapse.service
sudo rm -rf /var/lib/mautrix-telegram
```

Rebuild will regenerate registration with fresh tokens.

**Changing server_name after initial setup:**

Cannot change `server_name` after users exist. To reset:

```console
sudo systemctl stop matrix-synapse.service mautrix-telegram.service
sudo -u postgres psql -c "DROP DATABASE \"matrix-synapse\";"
sudo -u postgres psql -c "CREATE DATABASE \"matrix-synapse\" OWNER \"matrix-synapse\";"
```

All users and data will be lost. Rebuild to recreate with new server_name.
