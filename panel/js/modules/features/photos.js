/**
 * Карточка фото: загрузка списка, обновление.
 */
import { state } from "../state.js";
import { API, LIMITS, POLL_IDS, POLL_INTERVALS } from "../config.js";
import { escapeHtml, formatPhotoDate, renderPhotoCard, setListError } from "../utils.js";
import { loadSessionStats } from "./session.js";

export async function loadPhotos(container) {
  const listEl = container.querySelector("#gc-photos-list");
  const statsEl = container.querySelector("#gc-photos-stats");
  if (!listEl) return;
  try {
    const res = await fetch(API.photos + "?limit=" + LIMITS.photos);
    const data = await res.json();
    const photos = data.photos || [];
    const total = data.total != null ? data.total : photos.length;
    const unique = data.unique_devices != null ? data.unique_devices : new Set(photos.map((p) => p.ip)).size;
    loadSessionStats();
    listEl.classList.remove("gc-photos-loading");
    const photosKey = photos.length + "|" + (photos[0]?.path || "") + "|" + (photos[photos.length - 1]?.path || "");
    if (photosKey !== state.lastPhotosKey) {
      state.lastPhotosKey = photosKey;
      if (photos.length === 0) {
        listEl.innerHTML = "<span class=\"gc-photos-empty\">Пока нет фото. Запустите сессию и откройте ссылку.</span>";
        listEl.className = "gc-photos-grid gc-photos-empty";
      } else {
        listEl.className = "gc-photos-grid";
        listEl.innerHTML = photos.map((p) => {
          const dateStr = formatPhotoDate(p.mtime);
          return renderPhotoCard(p.url, dateStr);
        }).join("");
      }
    }
    if (statsEl && total >= 0) {
      const statsStr = total > 0 ? `Всего: ${total} фото · устройств: ${unique}` : "";
      if (statsEl.textContent !== statsStr) {
        statsEl.textContent = statsStr;
        statsEl.className = total > 0 ? "gc-stats" : "gc-stats gc-stats-empty";
      }
    }
  } catch (_) {
    listEl.classList.remove("gc-photos-loading");
    listEl.className = "gc-photos-grid gc-photos-error";
    if (statsEl) statsEl.textContent = "";
    setListError(container, listEl, "Ошибка загрузки.", "gc-photos-retry", () => {
      listEl.textContent = "Обновление…";
      loadPhotos(container);
    });
  }
}

export function initPhotos(container) {
  container.querySelector("#gc-btn-photos")?.addEventListener("click", () => {
    const listEl = container.querySelector("#gc-photos-list");
    if (listEl) {
      listEl.textContent = "Обновление…";
      listEl.className = "gc-photos-grid gc-photos-loading";
    }
    loadPhotos(container);
  });
  loadPhotos(container);
  POLL_IDS.photos = setInterval(() => loadPhotos(container), POLL_INTERVALS.photos);
}
