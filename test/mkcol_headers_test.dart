import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('mkdir forwards caller supplied MKCOL headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;

    server.listen((request) async {
      custom = request.headers.value('X-MKCOL-Test');
      await request.drain();
      request.response.statusCode = HttpStatus.created;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.mkdir(
      '/folder/',
      headers: const {'X-MKCOL-Test': 'yes'},
    );

    expect(custom, 'yes');
  });

  test('mkdir body respects caller supplied content-type', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? contentType;

    server.listen((request) async {
      contentType = request.headers.contentType?.mimeType;
      await request.drain();
      request.response.statusCode = HttpStatus.created;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.mkdir(
      '/folder/',
      body: '<mkcol/>',
      headers: const {'Content-Type': 'application/custom+xml'},
    );

    expect(contentType, 'application/custom+xml');
  });
}
