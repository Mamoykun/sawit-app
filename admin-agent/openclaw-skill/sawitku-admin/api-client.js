// api-client.js — HTTP client helpers untuk Sawitku Admin Agent API.
//
// Loaded by SKILL.md. Each exported function returns a normalized JSON object.
// All requests authenticate via X-Admin-Agent-Key header.
//
// Env vars required:
//   SAWITKU_API_BASE  — e.g. "https://api.sawitku.id"
//   SAWITKU_AGENT_KEY — secret API key matching backend ADMIN_AGENT_API_KEY

const BASE = process.env.SAWITKU_API_BASE;
const KEY = process.env.SAWITKU_AGENT_KEY;

if (!BASE || !KEY) {
  console.error('[sawitku-admin] Missing SAWITKU_API_BASE or SAWITKU_AGENT_KEY env var.');
}

/** Generic GET with auth + retry. */
async function get(path, { retries = 1, timeout = 10_000 } = {}) {
  const url = `${BASE}/api/admin/agent${path}`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout);

  try {
    const res = await fetch(url, {
      method: 'GET',
      headers: { 'X-Admin-Agent-Key': KEY, 'Accept': 'application/json' },
      signal: controller.signal,
    });
    clearTimeout(timer);

    if (res.status === 401) throw new Error('Auth gagal — cek SAWITKU_AGENT_KEY.');
    if (res.status === 429) throw new Error('Rate limit — coba lagi nanti.');
    if (res.status === 503) throw new Error('Agent API disabled di backend.');
    if (!res.ok) throw new Error(`API error ${res.status}: ${await res.text()}`);

    return await res.json();
  } catch (err) {
    clearTimeout(timer);
    if (retries > 0 && (err.name === 'AbortError' || /5\d\d/.test(err.message))) {
      await new Promise(r => setTimeout(r, 5_000));
      return get(path, { retries: retries - 1, timeout });
    }
    throw err;
  }
}

/** Health check — verify API reachable + auth valid. */
export async function fetchHealth() {
  return get('/health');
}

/** Summary for a period. period = 'today' | 'week' | 'month' */
export async function fetchSummary(period = 'today') {
  return get(`/summary?period=${encodeURIComponent(period)}`);
}

/** Active alerts (severity: critical | warning | info). */
export async function fetchAlerts() {
  return get('/alerts/active');
}

/** Recent audit events. limit max 200. */
export async function fetchAuditRecent(limit = 50) {
  return get(`/audit/recent?limit=${limit}`);
}

/** User stats (total, active today/week, new today). */
export async function fetchUsersStats() {
  return get('/users/stats');
}

/** Compact bundle for free-text chat queries. */
export async function fetchChatContext() {
  return get('/chat-context');
}

// ─── Formatters (Telegram Markdown V2) ───────────────────────────────────────

/** Escape Telegram MarkdownV2 special chars. */
export function escapeMd(s) {
  return String(s ?? '').replace(/([_*\[\]()~`>#+=|{}.!\-])/g, '\\$1');
}

/** Format dollars from cents, e.g. 420 → "$4.20" */
export function dollars(cents) {
  return `$${(Number(cents || 0) / 100).toFixed(2)}`;
}

/** Format Indonesian short date, e.g. "9 Mei 2026" */
export function formatDateID(date = new Date()) {
  const months = ['Januari','Februari','Maret','April','Mei','Juni',
                  'Juli','Agustus','September','Oktober','November','Desember'];
  const d = new Date(date);
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
}

/** Build /today summary message. */
export function formatTodaySummary(summary) {
  const u = summary.users || {};
  const a = summary.ai || {};
  const date = formatDateID();
  return `📊 *Sawitku — Hari Ini ${escapeMd(date)}*

🌾 *Aktivitas*
• ${summary.panen?.count ?? 0} panen baru
• ${summary.biaya?.count ?? 0} biaya tercatat
• ${summary.lahan?.count ?? 0} kebun terdaftar \\(total\\)

👥 *Engagement*
• ${u.active ?? 0} user aktif hari ini \\(dari ${u.total ?? 0} total\\)

💰 *AI Cost*
• ${escapeMd(dollars(a.totalCostCents))} bulan ini
• ${a.activeUsers ?? 0} user pakai AI

✅ Sistem operasional`;
}

/** Build /alerts message. */
export function formatAlerts(alertsResp) {
  const alerts = alertsResp.alerts || [];
  if (alerts.length === 0) return '✅ Tidak ada alert aktif. Sistem normal.';

  const grouped = { critical: [], warning: [], info: [] };
  for (const a of alerts) {
    (grouped[a.severity] ?? grouped.info).push(a);
  }

  const lines = ['🚨 *Active Alerts*\n'];
  if (grouped.critical.length) {
    lines.push('\n*Critical:*');
    for (const a of grouped.critical) lines.push(`🔴 ${escapeMd(a.message)}`);
  }
  if (grouped.warning.length) {
    lines.push('\n*Warning:*');
    for (const a of grouped.warning) lines.push(`🟡 ${escapeMd(a.message)}`);
  }
  if (grouped.info.length) {
    lines.push('\n*Info:*');
    for (const a of grouped.info) lines.push(`🔵 ${escapeMd(a.message)}`);
  }
  return lines.join('\n');
}

/** Build /users stats message. */
export function formatUsersStats(stats) {
  return `👥 *Statistik User*

• Total: *${stats.total ?? 0}*
• Aktif hari ini: *${stats.activeToday ?? 0}*
• Aktif minggu ini: *${stats.activeWeek ?? 0}*
• Baru hari ini: *${stats.newUsersToday ?? 0}*`;
}

/** Build /cost AI message. */
export function formatAiCost(summary) {
  const a = summary.ai || {};
  const lines = [
    `💰 *AI Cost Bulan Ini*\n`,
    `Total: *${escapeMd(dollars(a.totalCostCents))}*`,
    `Active users pakai AI: ${a.activeUsers ?? 0}`,
  ];
  if (Array.isArray(a.modelBreakdown) && a.modelBreakdown.length) {
    lines.push('\n*Model Breakdown:*');
    for (const m of a.modelBreakdown) {
      lines.push(`• ${escapeMd(m.model)}: ${m.callCount} calls — ${escapeMd(dollars(m.totalCostCents))}`);
    }
  }
  if (Array.isArray(a.topSpenders) && a.topSpenders.length) {
    lines.push('\n*Top Spenders:*');
    for (let i = 0; i < Math.min(5, a.topSpenders.length); i++) {
      const t = a.topSpenders[i];
      lines.push(`${i + 1}\\. ${escapeMd(t.userEmail)} — ${escapeMd(dollars(t.costCents))}`);
    }
  }
  return lines.join('\n');
}
