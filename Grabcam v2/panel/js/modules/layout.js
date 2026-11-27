/**
 * Grabcam — модуль макета (сетка, разметка панели).
 * Автор инструмента: ERRORoX
 */
import { GRABCAM_LAYOUT } from "../grabcam-layout.config.js";
import { getWidgetHTMLMap } from "./widgets/index.js";
import { escapeHtml } from "./utils.js";
import { LAYOUT_STORAGE_KEY, MIN_SPAN, MAX_SPAN } from "./config.js";

export function getLayout() {
  try {
    const raw = localStorage.getItem(LAYOUT_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.gridWidgets)) {
        const widgets = parsed.gridWidgets.map((w) => ({
          id: w.id,
          col: w.col,
          row: w.row,
          colSpan: Math.max(MIN_SPAN, Math.min(MAX_SPAN, Number(w.colSpan) || 1)),
          rowSpan: Math.max(MIN_SPAN, Math.min(MAX_SPAN, Number(w.rowSpan) || 1)),
        }));
        return {
          gridColumns: Math.max(1, Number(parsed.gridColumns) || 2),
          gridWidgets: widgets,
          fullWidthWidgets: Array.isArray(parsed.fullWidthWidgets) ? parsed.fullWidthWidgets : GRABCAM_LAYOUT.fullWidthWidgets || [],
        };
      }
    }
  } catch (_) {}
  const gridWidgets = (GRABCAM_LAYOUT.gridWidgets || []).map((w) => ({
    id: w.id,
    col: w.col,
    row: w.row,
    colSpan: Math.max(MIN_SPAN, Math.min(MAX_SPAN, Number(w.colSpan) || 1)),
    rowSpan: Math.max(MIN_SPAN, Math.min(MAX_SPAN, Number(w.rowSpan) || 1)),
  }));
  return {
    gridColumns: GRABCAM_LAYOUT.gridColumns || 2,
    gridWidgets,
    fullWidthWidgets: [...(GRABCAM_LAYOUT.fullWidthWidgets || [])],
  };
}

export function gridStyleFromWidget(w) {
  const col = Number(w.col) || 1;
  const row = Number(w.row) || 1;
  const colSpan = Math.max(MIN_SPAN, Math.min(MAX_SPAN, Number(w.colSpan) || 1));
  const rowSpan = Math.max(MIN_SPAN, Math.min(MAX_SPAN, Number(w.rowSpan) || 1));
  const gridColumn = colSpan > 1 ? `${col} / span ${colSpan}` : String(col);
  const gridRow = rowSpan > 1 ? `${row} / span ${rowSpan}` : String(row);
  return `grid-column: ${gridColumn}; grid-row: ${gridRow};`;
}

export function buildPanelHTML() {
  const layout = getLayout();
  const widgetHTML = getWidgetHTMLMap();
  const cols = Math.max(1, Number(layout.gridColumns) || 2);
  const gridTemplateColumns = `repeat(${cols}, 1fr)`;
  const gridParts = (layout.gridWidgets || []).map((w) => {
    const html = widgetHTML[w.id];
    if (!html) return "";
    const style = gridStyleFromWidget(w);
    return html.replace(/^<section\s/, "<section style=\"" + style + "\" data-gc-widget-id=\"" + escapeHtml(w.id) + "\" ");
  });
  const fullWidthParts = (layout.fullWidthWidgets || []).map((id) => widgetHTML[id]).filter(Boolean);
  return `
<div class="tool-view tool-view-grabcam">
  <div class="gc-grid-widgets" style="grid-template-columns: ${gridTemplateColumns};">
    ${gridParts.join("\n    ")}
  </div>
  ${fullWidthParts.join("\n  ")}
</div>`;
}
