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

## WhatsApp Bridge (mautrix-whatsapp)

### Authentication

**Method 1: QR Code** (if using Matrix client on different device)
1. Start chat with: `@whatsappbot:matrix.${externalDomain}`
2. Send: `login qr`
3. Scan QR code with WhatsApp on phone

**Method 2: Phone Pairing Code** (if using Matrix client on same phone as WhatsApp)
1. Start chat with: `@whatsappbot:matrix.${externalDomain}`
2. Send: `login phone`
3. On your phone:
   - Open WhatsApp → Menu/Settings → Linked devices
   - Tap "Link a device"
   - Select "Link with phone number instead"
   - Enter the pairing code shown by the bot
4. Bridge creates portal rooms automatically with 50 message backfill

Reference: https://docs.mau.fi/bridges/go/whatsapp/authentication.html

### Important Notes

- Phone must be online for WhatsApp Web API
- Devices disconnect after 2 weeks of phone being offline
- Bridge warns if no data received in 12+ days
- To logout: send `logout` to bot

### Troubleshooting

**Config format migration errors after updating:**

```console
sudo systemctl stop mautrix-whatsapp.service matrix-synapse.service
sudo rm -rf /var/lib/mautrix-whatsapp
sudo systemctl start matrix-synapse.service mautrix-whatsapp.service
```

Rebuild will regenerate config with new format and fresh registration tokens.

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
