import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('create sends If-None-Match star', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifNoneMatch;

    server.listen((request) async {
      if (request.method == 'PUT') {
        ifNoneMatch = request.headers.value('If-None-Match');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else {
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.create('/file.txt', Uint8List.fromList([1]));

    expect(ifNoneMatch, '*');
  });

  test('updateIfMatch sends quoted If-Match etag', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifMatch;

    server.listen((request) async {
      if (request.method == 'PUT') {
        ifMatch = request.headers.value('If-Match');
        await request.drain();
        request.response.statusCode = HttpStatus.noContent;
      } else {
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.updateIfMatch(
      '/file.txt',
      Uint8List.fromList([1]),
      'etag-value',
    );

    expect(ifMatch, '"etag-value"');
  });
}
