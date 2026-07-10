import 'package:web/web.dart' as web;

/// Triggers a browser download of [csv].
void downloadCsvFile(String csv, {String filename = 'climber_session.csv'}) {
  final href = 'data:text/csv;charset=utf-8,${Uri.encodeComponent(csv)}';
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = href
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
