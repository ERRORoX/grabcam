/**
 * Карточка захвата экрана.
 */
import { state } from "../state.js";
import { API, LIMITS, POLL_IDS, POLL_INTERVALS } from "../config.js";
import { formatPhotoDate, renderMediaItem, setListError } from "../utils.js";

export async function loadScreen(container) {
  const listEl = container.querySelector("#gc-screen-list");
  if (!listEl) return;
  try {
    const res = await fetch(API.screen + "?limit=" + LIMITS.screen);
    const data = await res.json();
    const items = data.items || [];
    listEl.classList.remove("gc-screen-loading");
    const screenKey = items.length + "|" + (items[0]?.url || "") + "|" + (items[items.length - 1]?.url || "");
    if (screenKey !== state.lastScreenKey) {
      state.lastScreenKey = screenKey;
      if (items.length === 0) {
        listEl.innerHTML = "<span class=\"gc-screen-empty\">Нет захватов экрана.</span>";
        listEl.className = "gc-screen-list gc-screen-empty";
      } else {
        listEl.className = "gc-screen-list";
        listEl.innerHTML = items.map((p) => {
          const ip = (p.ip || "").replace(/_/g, ".");
          const meta = [ip, formatPhotoDate(p.mtime)].filter(Boolean).join(" · ");
          return renderMediaItem(p.url, meta);
        }).join("");
      }
    }
  } catch (_) {
    listEl.classList.remove("gc-screen-loading");
    listEl.className = "gc-screen-list gc-screen-error";
    setListError(container, listEl, "Ошибка загрузки.", "gc-screen-retry", () => { listEl.textContent = "Обновление…"; loadScreen(container); }, "gc-screen-empty");
  }
}

export function initScreen(container) {
  container.querySelector("#gc-btn-screen")?.addEventListener("click", () => {
    const el = container.querySelector("#gc-screen-list");
    if (el) { el.textContent = "Обновление…"; el.className = "gc-screen-list gc-screen-loading"; }
    loadScreen(container);
  });
  loadScreen(container);
  POLL_IDS.screen = setInterval(() => loadScreen(container), POLL_INTERVALS.screen);
}
