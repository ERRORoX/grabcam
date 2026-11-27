/**
 * Макет панели Grabcam — настраивается здесь.
 *
 * Как менять:
 * - gridColumns: число колонок в сетке (1, 2, 3 и т.д.).
 * - gridWidgets: список виджетов в сетке. Порядок записей = порядок в разметке.
 *   Каждый виджет: { id, col, row, colSpan?, rowSpan? }
 *   - id: ключ виджета (control, summary, link, map, photos, locations, forms, screen, audio).
 *   - col: номер колонки (1, 2, 3 …).
 *   - row: номер строки (1, 2, 3 …).
 *   - colSpan: сколько колонок занимает (по умолчанию 1). Чтобы карточка на всю ширину: colSpan: 2 при 2 колонках.
 *   - rowSpan: сколько строк занимает (по умолчанию 1).
 * - fullWidthWidgets: id виджетов, которые выводятся под сеткой на всю ширину (порядок важен).
 *
 * Чтобы скрыть карточку: удалите её из gridWidgets и из fullWidthWidgets (если была там).
 * Доступные id: control, summary, link, map, photos, locations, forms, screen, audio, summary-text
 */
export const GRABCAM_LAYOUT = {
  gridColumns: 2,

  gridWidgets: [
    { id: "control", col: 1, row: 1 },
    { id: "summary", col: 2, row: 1 },
    { id: "map", col: 1, row: 2 },
    { id: "link", col: 2, row: 2 },
    { id: "photos", col: 1, row: 3 },
    { id: "locations", col: 2, row: 3 },
    { id: "screen", col: 1, row: 4 },
    { id: "forms", col: 2, row: 4 },
    { id: "audio", col: 2, row: 5 },
  ],

  fullWidthWidgets: ["summary-text"],
};
