/**
 * Заглушка для автономного запуска Grabcam: только escapeHtml.
 */
export function escapeHtml(str) {
  if (str == null) return "";
  const s = String(str);
  const div = document.createElement("div");
  div.textContent = s;
  return div.innerHTML;
}
