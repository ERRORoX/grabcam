/**
 * Сводка сессии: длительность, цели, уник. IP.
 */
import { state } from "../state.js";
import { API } from "../config.js";
import { POLL_IDS, POLL_INTERVALS } from "../config.js";

export function updateSessionMetrics(container) {
  const durationEl = container.querySelector("#gc-duration");
  const targetsEl = container.querySelector("#gc-targets");
  const uniqueEl = container.querySelector("#gc-unique-ips");
  if (durationEl && state.sessionStartTime > 0) {
    const min = Math.floor((Date.now() - state.sessionStartTime) / 60000);
    const h = Math.floor(min / 60);
    const str = (h > 0 ? h + "ч " : "0ч ") + (min % 60) + "м";
    if (durationEl.textContent !== str) durationEl.textContent = str;
  } else if (durationEl && state.sessionStartTime === 0) {
    if (durationEl.textContent !== "0ч 0м") durationEl.textContent = "0ч 0м";
  }
  if (targetsEl && targetsEl.textContent !== String(state.lastTargets)) targetsEl.textContent = String(state.lastTargets);
  if (uniqueEl && uniqueEl.textContent !== String(state.lastUniqueIPs)) uniqueEl.textContent = String(state.lastUniqueIPs);
}

export async function loadSessionStats(container = null) {
  try {
    const res = await fetch(API.sessionStats);
    const data = await res.json();
    const targets = data.targets != null ? data.targets : 0;
    const unique = data.unique_ips != null ? data.unique_ips : 0;
    if (targets !== state.lastTargets || unique !== state.lastUniqueIPs) {
      state.lastTargets = targets;
      state.lastUniqueIPs = unique;
    }
    if (container) updateSessionMetrics(container);
  } catch (_) {}
}

export function initSession(container) {
  POLL_IDS.sessionStats = setInterval(() => loadSessionStats(container), POLL_INTERVALS.sessionStats);
  return { updateSessionMetrics, loadSessionStats };
}
