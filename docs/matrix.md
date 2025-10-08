# Matrix Setup

## Current Deployment

**Status**: Matrix stack migrated to mini-vm (Oct 2025)

- **Production** (inactive): `matrix.${externalDomain}` and `element.${externalDomain}` - removed from configuration
- **Testing**: `matrix-mini.${externalDomain}` and `element-mini.${externalDomain}` - active on mini-vm

Synapse homeserver runs on mini-vm (OrbStack VM on Mac mini at 192.168.50.4:8008).

**When adding new bridges**: Check for port conflicts by searching the entire codebase:

```console
grep -r "$portnumber" .
```

Server name: `matrix-mini.${externalDomain}`

Registration enabled without verification.

## Accessing Matrix

### Web Client

Element Web: `https://element-mini.${externalDomain}`

Pre-configured with homeserver, just register or login.

### Homeserver URL

Homeserver URL: `https://matrix-mini.${externalDomain}`

Request flow:

1. Client → matrix-mini.${externalDomain} (wildcard DNS)
2. Caddy on bee (192.168.50.3) → Caddy on mini (192.168.50.4:8008)
3. Caddy on mini → mini-vm Synapse (mini-vm.orb.local:8008)

Note: Two-hop routing required due to OrbStack NAT networking. Mini-vm hostname `mini-vm.orb.local` only resolvable from mini host.

## Registration

Use Element or any Matrix client:

1. Set homeserver: `https://matrix-mini.${externalDomain}`
2. Register with username and password
3. User ID format: `@username:matrix-mini.${externalDomain}`

### Important: Set Up Security Key

After first login, immediately set up a security key:

1. Go to Settings → Security & Privacy → Secure Backup
2. Click "Set up Secure Backup"
3. Create and save your security key

This allows logging in on new devices without needing confirmation from another device.

## Telegram Bridge (mautrix-telegram)

### Authentication

1. Start chat with: `@telegrambot:matrix-mini.${externalDomain}`
2. Send: `login`
3. Follow authentication flow (phone number, verification code, 2FA if enabled)

Reference: https://docs.mau.fi/bridges/python/telegram/authentication.html

## WhatsApp Bridge (mautrix-whatsapp)

### Authentication

**Method 1: QR Code** (if using Matrix client on different device)

1. Start chat with: `@whatsappbot:matrix-mini.${externalDomain}`
2. Send: `login qr`
3. Scan QR code with WhatsApp on phone

**Method 2: Phone Pairing Code** (if using Matrix client on same phone as WhatsApp)

1. Start chat with: `@whatsappbot:matrix-mini.${externalDomain}`
2. Send: `login phone`
3. On your phone:
   - Open WhatsApp → Menu/Settings → Linked devices
   - Tap "Link a device"
   - Select "Link with phone number instead"
   - Enter the pairing code shown by the bot
4. Bridge creates portal rooms automatically with 50 message backfill

Reference: https://docs.mau.fi/bridges/go/whatsapp/authentication.html

## Discord Bridge (mautrix-discord)

### Authentication

**Method 1: QR Code** (recommended)

1. Start chat with: `@discordbot:matrix-mini.${externalDomain}`
2. Send: `login`
3. Bot sends a QR code image
4. Scan QR code with Discord mobile app:
   - If using Matrix on same device: Save QR image to Photos, open on another device to scan
   - If using Matrix on different device: Scan QR directly from screen
5. Approve login on Discord app

**Method 2: Token Login**

1. Start chat with: `@discordbot:matrix-mini.${externalDomain}`
2. Send: `login-token`
3. Follow instructions to obtain Discord token from browser/app

Reference: https://docs.mau.fi/bridges/go/discord/authentication.html

## Messenger Bridge (mautrix-meta)

### Authentication

Cookie-based authentication:

1. Start chat with: `@facebookbot:matrix-mini.${externalDomain}`
2. Send: `login`
3. Open Facebook in private browser window
4. Open DevTools → Network tab
5. Login to Facebook, find any request to `facebook.com`
6. Right-click → Copy → Copy as cURL
7. Paste the cURL command to the bot
8. Bridge extracts cookies automatically

Reference: https://docs.mau.fi/bridges/go/meta/authentication.html

## Instagram Bridge (mautrix-meta)

### Authentication

Same as Messenger bridge, but use `@instagrambot:matrix-mini.${externalDomain}` and login to `instagram.com`.

Reference: https://docs.mau.fi/bridges/go/meta/authentication.html

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
