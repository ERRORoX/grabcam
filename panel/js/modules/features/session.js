/**
 * Сводка состояния приложения: время работы и локальные серверные ошибки.
 * Не собирает и не отображает IP-адреса или данные посетителей.
 */
import { state } from "../state.js";
import { API, POLL_IDS, POLL_INTERVALS } from "../config.js";

export function updateSessionMetrics(container) {
  const durationEl = container.querySelector("#gc-duration");
  if (durationEl) {
    const elapsed = state.sessionStartTime > 0 ? Math.max(0, Date.now() - state.sessionStartTime) : 0;
    const min = Math.floor(elapsed / 60000);
    const value = Math.floor(min / 60) + "ч " + (min % 60) + "м";
    if (durationEl.textContent !== value) durationEl.textContent = value;
  }
}

export async function loadSessionStats(container = null) {
  if (!container) return;
  const set = (id, value) => {
    const el = container.querySelector("#" + id);
    if (el) el.textContent = String(value);
  };
  try {
    const response = await fetch(API.diagnostics, { cache: "no-store" });
    if (!response.ok) throw new Error("Диагностика недоступна");
    const data = await response.json();
    set("gc-health-state", "Работает");
    set("gc-health-24h", data.server_errors_24h ?? 0);
    set("gc-health-7d", data.server_errors_7d ?? 0);
    set("gc-health-total", data.server_errors_total ?? 0);
    const latest = Array.isArray(data.recent_errors) ? data.recent_errors[0] : null;
    set("gc-health-latest", latest ? "Последняя ошибка: HTTP " + latest.status_code + " · " + latest.occurred_at : "Ошибок сервера пока нет");
    const updated = container.querySelector("#gc-health-updated");
    if (updated) updated.textContent = new Date().toLocaleTimeString("ru-RU");
    const uptime = Math.max(0, Number(data.uptime_seconds) || 0);
    state.sessionStartTime = Date.now() - uptime * 1000;
    updateSessionMetrics(container);
  } catch (_) {
    set("gc-health-state", "Недоступен");
    set("gc-health-latest", "Не удалось получить локальную диагностику");
  }
}

export function initSession(container) {
  loadSessionStats(container);
  POLL_IDS.sessionStats = setInterval(() => loadSessionStats(container), POLL_INTERVALS.sessionStats);
  return { updateSessionMetrics, loadSessionStats };
}
