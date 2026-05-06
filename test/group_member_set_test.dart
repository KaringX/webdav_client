import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('groupMemberSet returns group member hrefs', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await request.drain();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/principals/groups/editors/</d:href><d:propstat><d:prop>
    <d:group-member-set>
      <d:href>/principals/users/alice/</d:href>
      <d:href>/principals/users/bob/</d:href>
    </d:group-member-set>
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    expect(await client.groupMemberSet(path: '/principals/groups/editors/'), [
      '/principals/users/alice/',
      '/principals/users/bob/',
    ]);
  });
}
