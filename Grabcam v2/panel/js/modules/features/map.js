/**
 * Карта: показ точки по координатам, очистка.
 */
import { state } from "../state.js";
import { loadLeaflet } from "../utils.js";

export function showLocationOnMap(container, lat, lon, label, ip) {
  const mapEl = container?.querySelector("#gc-map");
  const tipEl = container?.querySelector("#gc-map-ip-value");
  if (!mapEl) return;
  loadLeaflet(() => {
    if (typeof L === "undefined") return;
    if (!state.mapInstance) {
      mapEl.classList.remove("gc-map-empty");
      mapEl.innerHTML = "";
      state.mapInstance = L.map(mapEl).setView([lat, lon], 13);
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "© OpenStreetMap",
      }).addTo(state.mapInstance);
    }
    state.mapInstance.setView([lat, lon], 13);
    state.mapInstance.eachLayer((layer) => {
      if (layer instanceof L.Marker) state.mapInstance.removeLayer(layer);
    });
    L.marker([lat, lon])
      .addTo(state.mapInstance)
      .bindPopup(label || `${lat}, ${lon}`);
    if (tipEl) {
      tipEl.textContent = ip || "";
      const tooltipWrap = container?.querySelector("#gc-map-ip-tooltip");
      if (tooltipWrap) tooltipWrap.style.display = ip ? "block" : "none";
    }
  });
}

export function clearMap(container) {
  if (state.mapInstance && container) {
    const mapEl = container.querySelector("#gc-map");
    if (mapEl) {
      state.mapInstance.remove();
      state.mapInstance = null;
      mapEl.innerHTML = '<span class="gc-map-placeholder">Выберите местоположение ниже или запустите сессию.</span>';
      mapEl.classList.add("gc-map-empty");
      const tooltipWrap = container.querySelector("#gc-map-ip-tooltip");
      if (tooltipWrap) tooltipWrap.style.display = "none";
    }
  }
}

export function initMap(container) {
  container?.querySelector("#gc-btn-map")?.addEventListener("click", () => clearMap(container));
}
