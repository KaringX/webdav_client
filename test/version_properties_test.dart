import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('version property helpers return DeltaV href values', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    var call = 0;

    server.listen((request) async {
      call++;
      await request.drain();
      final prop = switch (call) {
        1 => '<d:checked-in><d:href>/versions/1</d:href></d:checked-in>',
        2 => '<d:checked-out><d:href>/workspace/file</d:href></d:checked-out>',
        3 => '<d:version-history><d:href>/history/file</d:href></d:version-history>',
        4 => '''<d:predecessor-set>
          <d:href>/versions/1</d:href><d:href>/versions/2</d:href>
        </d:predecessor-set>''',
        _ => '''<d:successor-set>
          <d:href>/versions/4</d:href><d:href>/versions/5</d:href>
        </d:successor-set>''',
      };
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop>$prop</d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    expect(await client.checkedIn(path: '/file.txt'), '/versions/1');
    expect(await client.checkedOut(path: '/file.txt'), '/workspace/file');
    expect(await client.versionHistory(path: '/file.txt'), '/history/file');
    expect(await client.predecessorSet(path: '/file.txt'), [
      '/versions/1',
      '/versions/2',
    ]);
    expect(await client.successorSet(path: '/file.txt'), [
      '/versions/4',
      '/versions/5',
    ]);
  });
}
