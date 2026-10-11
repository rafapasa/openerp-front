import 'launch_url_stub.dart' if (dart.library.js_interop) 'launch_url_web.dart' as impl;

void openExternalUrl(String url) => impl.openExternalUrl(url);

void printHtml(String html) => impl.printHtml(html);
