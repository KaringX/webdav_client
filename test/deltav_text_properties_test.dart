import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('creatorDisplayName and comment return trimmed text', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    var call = 0;

    server.listen((request) async {
      call++;
      await request.drain();
      final prop = call == 1
          ? '<d:creator-displayname> Alice </d:creator-displayname>'
          : '<d:comment> Initial version </d:comment>';
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/file.txt</d:href><d:propstat><d:prop>
    $prop
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    expect(await client.creatorDisplayName(path: '/file.txt'), 'Alice');
    expect(await client.comment(path: '/file.txt'), 'Initial version');
  });
}
