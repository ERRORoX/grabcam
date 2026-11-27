/** Виджет: сводка состояния приложения. Автор: ERRORoX */
export const html = `<section class="gc-widget gc-widget-summary" data-gc-module="session-summary">
<h3 class="gc-widget-title gc-summary-title">Состояние приложения</h3>
<div class="gc-summary-metrics">
<div class="gc-summary-metric"><span class="gc-summary-metric-icon gc-icon-duration" aria-hidden="true">⌛</span><div class="gc-summary-metric-body"><span class="gc-summary-metric-label">Время работы</span><span id="gc-duration" class="gc-summary-metric-value">0ч 0м</span></div></div>
<div class="gc-summary-metric"><span class="gc-summary-metric-icon" aria-hidden="true">●</span><div class="gc-summary-metric-body"><span class="gc-summary-metric-label">Сервер</span><span id="gc-health-state" class="gc-summary-metric-value">Проверка…</span></div></div>
<div class="gc-summary-metric"><span class="gc-summary-metric-icon" aria-hidden="true">!</span><div class="gc-summary-metric-body"><span class="gc-summary-metric-label">Ошибки за 24 часа</span><span id="gc-health-24h" class="gc-summary-metric-value">—</span></div></div>
<div class="gc-summary-metric"><span class="gc-summary-metric-icon" aria-hidden="true">▤</span><div class="gc-summary-metric-body"><span class="gc-summary-metric-label">Ошибки за 7 дней</span><span id="gc-health-7d" class="gc-summary-metric-value">—</span></div></div>
</div>
<div class="gc-summary-metrics" style="margin-top:10px">
<div class="gc-summary-metric"><div class="gc-summary-metric-body"><span class="gc-summary-metric-label">Всего ошибок за 90 дней</span><span id="gc-health-total" class="gc-summary-metric-value">—</span></div></div>
<div class="gc-summary-metric"><div class="gc-summary-metric-body"><span class="gc-summary-metric-label">Последняя проверка</span><span id="gc-health-updated" class="gc-summary-metric-value">—</span></div></div>
</div>
<div id="gc-health-latest" class="gc-summary-metric-sub" aria-live="polite">Диагностика ещё не выполнена</div>
</section>`;