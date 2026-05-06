import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('propPatch forwards caller supplied PROPPATCH headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;
    String? contentType;

    server.listen((request) async {
      custom = request.headers.value('X-Proppatch-Test');
      contentType = request.headers.contentType?.mimeType;
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop><d:displayname /></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.propPatch(
      '/file.txt',
      const [PropPatchOperation.set('displayname', 'name')],
      headers: const {
        'X-Proppatch-Test': 'yes',
        'Content-Type': 'application/custom+xml',
      },
    );

    expect(custom, 'yes');
    expect(contentType, 'application/custom+xml');
  });
}
