/**
 * Карточка ссылки: копирование, экспорт.
 */
import { state } from "../state.js";
import { copyToClipboard } from "../utils.js";
import { API } from "../config.js";

export function initLink(container, showCopyFeedback) {
  const resultEl = container.querySelector("#gc-result");
  const statusEl = container.querySelector("#gc-status");
  const copyBtn = container.querySelector("#gc-copy-btn");
  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      const url = copyBtn.getAttribute("data-copy") || resultEl?.querySelector("a.gc-link-url")?.href || "";
      if (url) copyToClipboard(url).then(() => showCopyFeedback("Ссылка скопирована."), () => showCopyFeedback("Не удалось скопировать."));
    });
  }
  container.querySelector("#gc-btn-export")?.addEventListener("click", async () => {
    const btn = container.querySelector("#gc-btn-export");
    if (btn) btn.disabled = true;
    try {
      const res = await fetch(API.export);
      if (!res.ok) throw new Error(res.statusText);
      const blob = await res.blob();
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "grabcam_export.zip";
      a.click();
      URL.revokeObjectURL(a.href);
      if (statusEl) statusEl.textContent = "Отчёт скачан.";
    } catch (e) {
      if (statusEl) statusEl.textContent = "Ошибка: " + (e.message || "не удалось скачать");
    }
    if (btn) btn.disabled = false;
  });
}
