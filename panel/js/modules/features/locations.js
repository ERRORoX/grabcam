/**
 * Карточка местоположений: загрузка списка, кнопка «На карте».
 */
import { state } from "../state.js";
import { API, POLL_IDS, POLL_INTERVALS } from "../config.js";
import { escapeHtml, setListError } from "../utils.js";
import { loadSessionStats } from "./session.js";
import { showLocationOnMap } from "./map.js";

export async function loadLocations(container) {
  const listEl = container.querySelector("#gc-locations-list");
  if (!listEl) return;
  try {
    const res = await fetch(API.locations);
    const data = await res.json();
    const locations = data.locations || [];
    loadSessionStats();
    listEl.classList.remove("gc-locations-loading");
    const locsKey = locations.length + "|" + locations.map((l) => (l.lat || "") + "," + (l.lon || "")).join(";");
    if (locsKey !== state.lastLocationsKey) {
      state.lastLocationsKey = locsKey;
      if (locations.length === 0) {
        listEl.innerHTML = "<span class=\"gc-locations-empty\">Нет данных о местоположении.</span>";
        listEl.className = "gc-locations-list gc-locations-empty";
      } else {
        listEl.className = "gc-locations-list";
        listEl.innerHTML = locations.map((loc) => {
          const lat = (loc.lat && loc.lat !== "0") ? loc.lat : null;
          const lon = (loc.lon && loc.lon !== "0") ? loc.lon : null;
          const hasCoords = lat != null && lon != null && parseFloat(lat) && parseFloat(lon);
          const place = [loc.country, loc.region, loc.city].filter(Boolean).join(", ") || "—";
          const mapUrl = hasCoords ? `https://www.openstreetmap.org/?mlat=${encodeURIComponent(lat)}&mlon=${encodeURIComponent(lon)}&zoom=12` : null;
          const label = (loc.device_id || loc.ip || "—").replace(/_/g, ".");
          const onMapBtn = hasCoords ? `<button type="button" class="gc-locations-btn-map" data-lat="${escapeHtml(String(lat))}" data-lon="${escapeHtml(String(lon))}" data-label="${escapeHtml(label + " — " + place)}" data-ip="${escapeHtml(label)}" title="Показать на карте">На карте</button>` : "";
          return `<div class="gc-locations-item">
            <div class="gc-locations-row"><strong>${escapeHtml((loc.device_id || loc.ip || "—").replace(/_/g, "."))}</strong></div>
            <div class="gc-locations-row gc-locations-muted">IP: ${escapeHtml(loc.ip || "—")}</div>
            <div class="gc-locations-row gc-locations-muted">${escapeHtml(place)}</div>
            ${loc.isp ? `<div class="gc-locations-row gc-locations-muted">${escapeHtml(loc.isp)}</div>` : ""}
            ${loc.last_update ? `<div class="gc-locations-time">${escapeHtml(loc.last_update)}</div>` : ""}
            <div class="gc-locations-actions">${onMapBtn}${mapUrl ? `<a href="${mapUrl}" target="_blank" rel="noopener" class="gc-locations-link">Открыть OSM</a>` : ""}</div>
          </div>`;
        }).join("");
        listEl.querySelectorAll(".gc-locations-btn-map").forEach((btn) => {
          btn.addEventListener("click", () => {
            const lat = parseFloat(btn.getAttribute("data-lat"));
            const lon = parseFloat(btn.getAttribute("data-lon"));
            const label = btn.getAttribute("data-label") || "";
            const ip = btn.getAttribute("data-ip") || "";
            if (!isNaN(lat) && !isNaN(lon)) showLocationOnMap(container, lat, lon, label, ip);
          });
        });
      }
    }
  } catch (_) {
    listEl.classList.remove("gc-locations-loading");
    listEl.className = "gc-locations-list gc-locations-error";
    setListError(container, listEl, "Ошибка загрузки.", "gc-locations-retry", () => {
      listEl.textContent = "Обновление…";
      loadLocations(container);
    }, "gc-locations-empty");
  }
}

export function initLocations(container) {
  container.querySelector("#gc-btn-locations")?.addEventListener("click", () => {
    const listEl = container.querySelector("#gc-locations-list");
    if (listEl) {
      listEl.textContent = "Обновление…";
      listEl.className = "gc-locations-list gc-locations-loading";
    }
    loadLocations(container);
  });
  loadLocations(container);
  POLL_IDS.locations = setInterval(() => loadLocations(container), POLL_INTERVALS.locations);
}
