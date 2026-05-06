import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('supportedLocks parses lockentry scope and type pairs', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await request.drain();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:supportedlock>
          <d:lockentry>
            <d:lockscope><d:exclusive/></d:lockscope>
            <d:locktype><d:write/></d:locktype>
          </d:lockentry>
          <d:lockentry>
            <d:lockscope><d:shared/></d:lockscope>
            <d:locktype><d:write/></d:locktype>
          </d:lockentry>
        </d:supportedlock>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final supported = await client.supportedLocks('/file.txt');

    expect(supported, contains(('exclusive', 'write')));
    expect(supported, contains(('shared', 'write')));
  });
}
