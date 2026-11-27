/**
 * Карточка аудио.
 */
import { state } from "../state.js";
import { API, LIMITS, POLL_IDS, POLL_INTERVALS } from "../config.js";
import { escapeHtml, formatPhotoDate, setListError } from "../utils.js";

export async function loadAudio(container) {
  const listEl = container.querySelector("#gc-audio-list");
  if (!listEl) return;
  try {
    const res = await fetch(API.audio + "?limit=" + LIMITS.audio);
    const data = await res.json();
    const items = data.items || [];
    listEl.classList.remove("gc-audio-loading");
    const audioKey = items.length + "|" + (items[0]?.url || "") + "|" + (items[items.length - 1]?.url || "");
    if (audioKey !== state.lastAudioKey) {
      state.lastAudioKey = audioKey;
      if (items.length === 0) {
        listEl.innerHTML = "<span class=\"gc-audio-empty\">Нет аудиозаписей.</span>";
        listEl.className = "gc-audio-list gc-audio-empty";
      } else {
        listEl.className = "gc-audio-list";
        listEl.innerHTML = items.map((p) => {
          const ip = (p.ip || "").replace(/_/g, ".");
          const dateStr = formatPhotoDate(p.mtime);
          return `<div class="gc-audio-item"><audio src="${escapeHtml(p.url)}" controls preload="metadata"></audio><span class="gc-audio-meta">${escapeHtml(ip)} · ${escapeHtml(dateStr)}</span></div>`;
        }).join("");
      }
    }
  } catch (_) {
    listEl.classList.remove("gc-audio-loading");
    listEl.className = "gc-audio-list gc-audio-error";
    setListError(container, listEl, "Ошибка загрузки.", "gc-audio-retry", () => { listEl.textContent = "Обновление…"; loadAudio(container); }, "gc-audio-empty");
  }
}

export function initAudio(container) {
  container.querySelector("#gc-btn-audio")?.addEventListener("click", () => {
    const el = container.querySelector("#gc-audio-list");
    if (el) { el.textContent = "Обновление…"; el.className = "gc-audio-list gc-audio-loading"; }
    loadAudio(container);
  });
  loadAudio(container);
  POLL_IDS.audio = setInterval(() => loadAudio(container), POLL_INTERVALS.audio);
}
