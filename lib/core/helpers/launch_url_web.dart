import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void openExternalUrl(String url) {
  globalContext.callMethod('open'.toJS, url.toJS, '_blank'.toJS);
}

void printHtml(String content) {
  final opened = globalContext.callMethod('open'.toJS, ''.toJS, '_blank'.toJS, 'noopener,noreferrer'.toJS);
  if (opened == null) return;

  final window = opened as JSObject;
  final document = window.getProperty('document'.toJS);
  if (document == null) return;
  final doc = document as JSObject;

  doc.callMethod('open'.toJS);
  doc.callMethod('write'.toJS, content.toJS);
  doc.callMethod('close'.toJS);
  window.callMethod('focus'.toJS);
  window.callMethod('print'.toJS);
}
