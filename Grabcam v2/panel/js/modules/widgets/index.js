/**
 * Сборка HTML всех виджетов Grabcam (каждый виджет — отдельный модуль).
 * Автор инструмента: ERRORoX
 */
import { html as control } from "./control.js";
import { html as summary } from "./summary.js";
import { html as link } from "./link.js";
import { html as map } from "./map.js";
import { html as photos } from "./photos.js";
import { html as locations } from "./locations.js";
import { html as forms } from "./forms.js";
import { html as screen } from "./screen.js";
import { html as audio } from "./audio.js";
import { html as summaryText } from "./summary-text.js";

export function getWidgetHTMLMap() {
  return {
    control,
    summary,
    link,
    map,
    photos,
    locations,
    forms,
    screen,
    audio,
    "summary-text": summaryText,
  };
}
