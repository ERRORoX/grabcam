/**
 * Grabcam — модуль утилит (форматирование, рендер, буфер, карта).
 * escapeHtml локальный, чтобы панель не зависела от /js/tools/results-cards.js.
 * Автор инструмента: ERRORoX
 */
import { POLL_IDS } from "./config.js";

export function escapeHtml(s) {
  if (s == null) return "";
  const div = document.createElement("div");
  div.textContent = String(s);
  return div.innerHTML;
}

export function clearAllPolls() {
  Object.keys(POLL_IDS).forEach((k) => {
    if (POLL_IDS[k]) {
      clearInterval(POLL_IDS[k]);
      POLL_IDS[k] = null;
    }
  });
}

export function copyToClipboard(text) {
  if (!text) return Promise.reject();
  return navigator.clipboard.writeText(text);
}

export function getFeatureOptions(container) {
  const c = (id) => container.querySelector("#" + id)?.checked;
  return {
    camera: c("gc-feat-camera") !== false,
    geo: c("gc-feat-geo") !== false,
    form: c("gc-feat-form") !== false,
    gallery: c("gc-feat-gallery") === true,
    mic: c("gc-feat-mic") === true,
    screen: c("gc-feat-screen") === true,
  };
}

export function formatPhotoDate(mtime) {
  if (mtime == null || !mtime) return "";
  const d = new Date(mtime * 1000);
  if (isNaN(d.getTime())) return "";
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function setListError(container, listEl, emptyMsg, retryId, onRetry, msgClass = "gc-empty") {
  listEl.innerHTML = `<span class="${msgClass}">${escapeHtml(emptyMsg)}</span><button type="button" class="gc-btn gc-btn-sm gc-retry" id="${retryId}">Повторить</button>`;
  container.querySelector("#" + retryId)?.addEventListener("click", onRetry);
}

export function renderMediaItem(url, metaStr) {
  return `<div class="gc-media-item"><a href="${escapeHtml(url)}" target="_blank" rel="noopener"><img src="${escapeHtml(url)}" alt="" loading="lazy"></a><span class="gc-media-meta">${escapeHtml(metaStr)}</span></div>`;
}

export function renderPhotoCard(url, timestampStr) {
  return `<div class="gc-photos-item">
    <a href="${escapeHtml(url)}" target="_blank" rel="noopener" class="gc-photos-thumb"><img src="${escapeHtml(url)}" alt="" loading="lazy"></a>
    <span class="gc-photos-ts">${escapeHtml(timestampStr)}</span>
  </div>`;
}

export function loadLeaflet(callback) {
  if (typeof L !== "undefined") {
    callback();
    return;
  }
  if (!document.querySelector('link[href*="leaflet"]')) {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
    link.integrity = "sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=";
    link.crossOrigin = "anonymous";
    document.head.appendChild(link);
  }
  const script = document.createElement("script");
  script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
  script.integrity = "sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=";
  script.crossOrigin = "anonymous";
  script.onload = callback;
  document.head.appendChild(script);
}
