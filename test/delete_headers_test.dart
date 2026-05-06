import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('remove forwards caller supplied DELETE headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifMatch;
    String? depth;

    server.listen((request) async {
      ifMatch = request.headers.value('If-Match');
      depth = request.headers.value('Depth');
      await request.drain();
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.remove(
      '/file.txt',
      headers: const {'If-Match': '"etag"'},
    );

    expect(ifMatch, '"etag"');
    expect(depth, 'infinity');
  });
}
