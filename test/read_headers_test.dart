import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('read forwards caller supplied GET headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifNoneMatch;

    server.listen((request) async {
      ifNoneMatch = request.headers.value('If-None-Match');
      request.response
        ..statusCode = HttpStatus.ok
        ..add([1, 2, 3]);
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final bytes = await client.read(
      '/file.txt',
      headers: const {'If-None-Match': '"etag"'},
    );

    expect(ifNoneMatch, '"etag"');
    expect(bytes, Uint8List.fromList([1, 2, 3]));
  });

  test('readStream forwards caller supplied GET headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? range;

    server.listen((request) async {
      range = request.headers.value('Range');
      request.response
        ..statusCode = HttpStatus.ok
        ..write('partial');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.readStream(
      '/file.txt',
      headers: const {'Range': 'bytes=0-6'},
    );
    await response.data!.stream.drain<void>();

    expect(range, 'bytes=0-6');
  });
}
