import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('currentUserPrivilegeSet returns privilege names', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await request.drain();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:x="http://example.com/ns">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:current-user-privilege-set>
          <d:privilege><d:read/></d:privilege>
          <d:privilege><d:write/></d:privilege>
          <d:privilege><x:custom/></d:privilege>
        </d:current-user-privilege-set>
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

    final privileges = await client.currentUserPrivilegeSet(path: '/file.txt');

    expect(privileges, contains('d:read'));
    expect(privileges, contains('d:write'));
    expect(privileges, contains('x:custom'));
  });
}
