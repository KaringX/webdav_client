import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('copy forwards caller supplied headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifMatch;
    String? destination;

    server.listen((request) async {
      ifMatch = request.headers.value('If-Match');
      destination = request.headers.value('Destination');
      await request.drain();
      request.response.statusCode = HttpStatus.created;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.copy(
      '/source.txt',
      '/dest.txt',
      headers: const {'If-Match': '"etag"'},
    );

    expect(ifMatch, '"etag"');
    expect(destination, contains('/dest.txt'));
  });

  test('move forwards caller supplied headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;

    server.listen((request) async {
      custom = request.headers.value('X-WebDAV-Test');
      await request.drain();
      request.response.statusCode = HttpStatus.created;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.move(
      '/source.txt',
      '/dest.txt',
      headers: const {'X-WebDAV-Test': 'yes'},
    );

    expect(custom, 'yes');
  });
}
