import 'dart:html' as html;

const String _sessionStorageKey = 'secura_session_payload_v1';

void saveSessionPayload(String payload) {
  html.window.localStorage[_sessionStorageKey] = payload;
}

String? readSessionPayload() {
  return html.window.localStorage[_sessionStorageKey];
}

void clearSessionPayload() {
  html.window.localStorage.remove(_sessionStorageKey);
}
