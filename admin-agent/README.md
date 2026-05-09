# Sawitku Admin Agent

Admin agent untuk aplikasi Sawitku, powered by **OpenClaw** + **Claude API**, terhubung ke Telegram. Owner aplikasi terima daily report otomatis, alert real-time, dan bisa chat-back untuk query data.

## 🦞 Apa itu OpenClaw?

[OpenClaw](https://openclaw.ai) adalah open-source AI agent yang run lokal. Dia bukan LLM sendiri — dia layer orchestration yang ngasih "tangan" ke Claude/GPT untuk eksekusi task, baca/tulis file, panggil API, dan interact via messaging platform (Telegram, WhatsApp, Discord, Signal).

**Kenapa OpenClaw + Sawitku:**
- Pakai Claude API kamu yang sudah ada (no extra LLM cost)
- Telegram gratis (vs WhatsApp Business API yang berbayar)
- Local-first — data tetap di server kamu
- Setup 1-2 hari (vs build native bot 3-4 minggu)

## 🏗️ Architecture

```
   📱 Owner (Kamu)
        │
        │ Telegram chat
        ▼
   ┌──────────────────┐
   │  🦞 OpenClaw      │  ← run di VPS murah ($5/bulan)
   │  + sawitku-admin │
   │    skill          │
   └────────┬─────────┘
            │ HTTPS + X-Admin-Agent-Key
            ▼
   ┌──────────────────────────┐
   │  Sawitku Backend         │
   │  /api/admin/agent/*      │
   │  (read-only endpoints)   │
   └──────────────────────────┘
```

## 📋 Prerequisites

Sebelum mulai, pastikan kamu punya:

- [ ] **VPS** Linux (Ubuntu 22.04 LTS recommended) — DigitalOcean / Vultr / Hetzner ~$5/bulan
- [ ] **Domain atau public URL** Sawitku backend (HTTPS) — agent perlu reach API
- [ ] **Claude API key** (Anthropic) — pakai existing
- [ ] **Telegram account** untuk chat dengan bot
- [ ] **30 menit** untuk setup full

## 🚀 Setup Guide

### Step 1: Buat Telegram Bot (5 menit)

1. Buka Telegram, search **@BotFather** → `/newbot`
2. Kasih nama: `Sawitku Admin Bot`
3. Kasih username: `sawitku_admin_bot` (harus end with `_bot`, harus unique)
4. **Simpan token** yang dikasih BotFather, format: `1234567890:ABC...`

### Step 2: Dapatkan Chat ID Kamu (2 menit)

1. Search **@userinfobot** di Telegram
2. Kirim `/start` → bot reply dengan ID kamu, format: `Id: 123456789`
3. **Simpan ID** itu — nanti dipakai untuk whitelist

### Step 3: Generate Sawitku Agent API Key (1 menit)

Generate random secret untuk autentikasi agent ke backend:

```bash
openssl rand -hex 32
# Output: a3f1...
```

**Simpan output**, ini API key untuk Sawitku.

### Step 4: Configure Sawitku Backend (5 menit)

Set environment variables di backend Sawitku:

```bash
# Backend .env or env config
ADMIN_AGENT_API_KEY=a3f1...your_generated_key
ADMIN_EMAILS=admin@sawitku.id,owner@sawitku.id
```

Restart backend. Verify endpoint accessible:

```bash
curl -H "X-Admin-Agent-Key: a3f1..." https://api.sawitku.id/api/admin/agent/health
# Expected: {"status":"ok","timestamp":"..."}
```

### Step 5: Setup VPS (10 menit)

SSH ke VPS:

```bash
ssh root@your-vps-ip
```

Install Node.js 22+ dan dependencies:

```bash
# Update + install Node 22 (via nodesource)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt install -y nodejs git build-essential

# Verify
node --version  # should be v22.x
npm --version
```

### Step 6: Install OpenClaw (5 menit)

```bash
# Clone OpenClaw
cd /opt
git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install

# Atau via npm registry (kalau available)
# npm install -g @openclaw/cli
```

### Step 7: Install Sawitku Admin Skill (3 menit)

```bash
# Dari repo Sawitku, copy skill folder ke OpenClaw skills directory
cd /opt/openclaw

# Option A: Clone Sawitku repo dan symlink
git clone https://github.com/your-org/sawitku.git /opt/sawitku
ln -s /opt/sawitku/admin-agent/openclaw-skill/sawitku-admin ./skills/

# Option B: Copy hanya skill folder (kalau gak mau full repo)
mkdir -p ./skills/sawitku-admin
scp -r local-machine:/path/to/sawit_app/admin-agent/openclaw-skill/sawitku-admin/* ./skills/sawitku-admin/
```

### Step 8: Configure OpenClaw (5 menit)

Edit `/opt/openclaw/.env`:

```bash
# Anthropic Claude API
ANTHROPIC_API_KEY=sk-ant-...your_existing_key

# Telegram Bot
TELEGRAM_BOT_TOKEN=1234567890:ABC...

# Sawitku Backend
SAWITKU_API_BASE=https://api.sawitku.id
SAWITKU_AGENT_KEY=a3f1...generated_in_step_3

# OpenClaw config
OPENCLAW_LOG_LEVEL=info
OPENCLAW_DATA_DIR=/var/lib/openclaw
```

Edit skill config — copy dari example:

```bash
cd /opt/openclaw/skills/sawitku-admin
cp config.example.json config.json
nano config.json  # Edit chat_ids, schedules, dll
```

Set `admin_chat_ids` array dengan chat ID kamu dari Step 2.

### Step 9: Test (5 menit)

Run OpenClaw foreground untuk test:

```bash
cd /opt/openclaw
npm start
# Expected output:
# [openclaw] Starting...
# [openclaw] Loaded skill: sawitku-admin
# [openclaw] Connected to Telegram (bot @sawitku_admin_bot)
# [openclaw] Ready
```

Buka Telegram, chat ke bot kamu, kirim `/help`. Bot harusnya respond dengan list commands.

Test commands:
- `/health` → bot reply "✅ API responsive"
- `/today` → bot kirim daily summary
- "Berapa user aktif minggu ini?" → bot reply dengan angka

Kalau berhasil, lanjut ke production.

### Step 10: Run as Service (production)

Buat systemd service supaya auto-start:

```bash
nano /etc/systemd/system/openclaw.service
```

Isi:

```ini
[Unit]
Description=OpenClaw Admin Agent for Sawitku
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openclaw
EnvironmentFile=/opt/openclaw/.env
ExecStart=/usr/bin/node /opt/openclaw/index.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable + start:

```bash
systemctl daemon-reload
systemctl enable openclaw
systemctl start openclaw

# Check status
systemctl status openclaw
journalctl -u openclaw -f
```

## ✅ Done

Bot sekarang:
- 🌅 Kirim daily report jam **08:00 WIB** setiap hari
- 📅 Kirim weekly report **Senin 08:00 WIB**
- 🚨 Alert real-time setiap **15 menit** kalau ada issue
- 💬 Respond ke slash commands: `/today`, `/cost`, `/users`, `/anomaly`, `/alert`, `/health`, `/help`
- 🤖 Jawab free-text queries via Claude (cap 50/bulan untuk cost saving)

## 🛠️ Troubleshooting

### Bot tidak respond
```bash
# Cek service running
systemctl status openclaw

# Cek log
journalctl -u openclaw -n 100

# Common issues:
# - Telegram token salah → re-verify dari BotFather
# - Chat ID tidak whitelisted → cek config.json
# - Claude API key invalid → cek ANTHROPIC_API_KEY env
```

### "API auth gagal" muncul di chat
→ `SAWITKU_AGENT_KEY` di OpenClaw env tidak match dengan `ADMIN_AGENT_API_KEY` di backend Sawitku. Verify keduanya sama persis.

### Daily report tidak terkirim
```bash
# Cek timezone container/VPS
date  # should be UTC or set TZ=Asia/Jakarta
timedatectl set-timezone Asia/Jakarta

# Cek schedule loaded
journalctl -u openclaw | grep schedule
```

### Free-text query bilang "Kuota chat tercapai"
Default cap 50/bulan per chat. Edit `config.json` `chat_budget.max_queries_per_month` untuk raise.

## 💰 Cost Estimate

Monthly:
- VPS: ~$5 (DigitalOcean basic / Vultr / Hetzner CX11)
- Telegram: **FREE** (no limit)
- Claude AI:
  - Daily report (Haiku): ~$0.015
  - Weekly report (Sonnet): ~$0.020
  - Alerts (no AI, template only): $0
  - Chat queries (Haiku, capped 50): ~$0.150
  - **Total AI: ~$0.20/bulan**
- **Grand total: ~$5.20/bulan** untuk full admin agent

## 🔒 Security Notes

- `SAWITKU_AGENT_KEY` adalah secret — backup secure, rotate kalau bocor (re-deploy backend dengan key baru, update OpenClaw env)
- Hanya chat ID di `admin_chat_ids` yang bisa interact dengan bot
- Telegram bot tidak bisa add ke group secara default — kalau perlu, set di BotFather
- API endpoints `/api/admin/agent/*` rate-limited 60 req/min per IP di backend
- VPS firewall: hanya allow SSH (22) + outbound HTTPS (443). Tidak perlu inbound port lain.

## 🔄 Update Skill

Kalau update logic skill (mis. tambah command baru):

```bash
cd /opt/sawitku  # atau dimanapun symlink-nya
git pull
systemctl restart openclaw
```

OpenClaw akan reload skill secara otomatis (atau setelah restart).

## ❓ Need Help

Kalau stuck di salah satu step, kasih tau saya step mana + error output. Saya bantu debug.

---

**Skill version:** 1.0.0  
**OpenClaw min version:** 1.0+  
**Node min version:** 22.x
