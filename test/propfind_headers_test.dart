import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('readProps forwards caller supplied PROPFIND headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;

    server.listen((request) async {
      custom = request.headers.value('X-Propfind-Test');
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop><d:getetag>"etag"</d:getetag></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final file = await client.readProps(
      '/file.txt',
      headers: const {'X-Propfind-Test': 'yes'},
    );

    expect(custom, 'yes');
    expect(file, isNotNull);
  });
}
