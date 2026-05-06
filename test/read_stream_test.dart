import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('readStream returns response headers and streamed bytes', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      if (request.method == 'GET' && request.uri.path == '/file.txt') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('text', 'plain')
          ..headers.set('ETag', '"stream"')
          ..write('hello stream');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.readStream('/file.txt');
    final body = await response.data!.stream
        .fold<List<int>>(<int>[], (previous, chunk) => previous..addAll(chunk));

    expect(response.headers.value('etag'), '"stream"');
    expect(String.fromCharCodes(body), 'hello stream');
  });

  test('readStream throws on non-success status', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await expectLater(
      client.readStream('/missing.txt'),
      throwsA(isA<WebdavException>()),
    );
  });
}
