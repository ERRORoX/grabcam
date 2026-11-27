/** Виджет: Управление. Автор: ERRORoX */
export const html = `<section class="gc-widget gc-widget-control" data-gc-module="control">
<h3 class="gc-control-title">Управление</h3>
<p class="gc-control-desc">Переключатели и метод сервера.</p>
<div class="gc-control-inner">
<div class="gc-control-toggles">
<label class="gc-control-toggle"><span class="gc-control-toggle-icon gc-icon-check"></span><input type="checkbox" id="gc-feat-status" disabled checked><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Статус</span></label>
<label class="gc-control-toggle"><span class="gc-control-toggle-icon gc-icon-rec"></span><input type="checkbox" id="gc-feat-camera" name="camera" checked><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Камера</span></label>
<label class="gc-control-toggle"><span class="gc-control-toggle-icon gc-icon-cloud">C</span><input type="checkbox" id="gc-feat-geo" name="geo" checked><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Геолокация</span></label>
<label class="gc-control-toggle"><span class="gc-control-toggle-icon gc-icon-cloud">C</span><input type="checkbox" id="gc-feat-gallery" name="gallery"><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Галерея</span></label>
<label class="gc-control-toggle"><span class="gc-control-toggle-icon gc-icon-eye"></span><input type="checkbox" id="gc-feat-form" name="form" checked><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Формы</span></label>
<label class="gc-control-toggle"><span class="gc-control-toggle-icon gc-icon-gear">G</span><input type="checkbox" id="gc-feat-screen" name="screen"><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Экран</span></label>
<label class="gc-control-toggle gc-control-toggle--extra"><input type="checkbox" id="gc-feat-mic" name="mic"><span class="gc-control-toggle-slider"></span><span class="gc-control-toggle-label">Микрофон</span></label>
</div>
<form id="gc-form" class="gc-control-form">
<label class="gc-control-form-label" for="gc-method">Метод сервера</label>
<select name="method" id="gc-method" class="gc-control-select" aria-label="Метод сервера">
<option value="php_only">Локальный сервер</option>
<option value="localhost_run">localhost.run</option>
<option value="cloudflared">Cloudflare Proxy</option>
<option value="serveo">Serveo</option>
</select>
<button type="submit" class="gc-control-btn-start" id="gc-btn-start">СТАРТ</button>
<button type="button" class="gc-control-btn-stop" id="gc-btn-stop" style="display:none">ОСТАНОВИТЬ СЕССИЮ</button>
</form>
</div>
<p id="gc-method-hint" class="gc-control-hint" aria-live="polite"></p>
</section>`;
