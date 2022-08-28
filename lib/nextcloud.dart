import 'dart:io';

Future<HttpClientResponse> nextcloudSend(
  String command,
  String url, {
  Map<String, String>? localHeaders,
  Stream<List<int>>? data,
}) async {
  var httpClient = HttpClient();
  final request = await httpClient.openUrl(command, Uri.parse(url))
    ..followRedirects = false
    ..persistentConnection = true;

  for (final header in {
    HttpHeaders.contentTypeHeader: 'application/xml',
    if (localHeaders != null) ...localHeaders,
  }.entries) {
    request.headers.add(header.key, header.value);
  }

  //var props = '<?xml version="1.0" encoding="UTF-8"?>'
  //    '<d:propfind xmlns:d="DAV:">'
  //    ' <d:prop xmlns:oc="http://owncloud.org/ns">'
  //    '   <d:getlastmodified/>'
  //    '   <d:getcontentlength/>'
  //    '   <d:getcontenttype/>'
  //    '   <oc:permissions/>'
  //    '   <d:resourcetype/>'
  //    '   <d:getetag/>'
  //    ' </d:prop>'
  //    '</d:propfind>';
  //var stream = Stream.value(Uint8List.fromList(utf8.encode(props)));
  if (data != null) await request.addStream(data);
  await request.flush();
  final response = await request.close();
  return response;
}
