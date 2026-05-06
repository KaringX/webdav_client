import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('lock forwards caller supplied headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;
    String? contentType;

    server.listen((request) async {
      custom = request.headers.value('X-Lock-Test');
      contentType = request.headers.contentType?.mimeType;
      await request.drain();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.add('Lock-Token', '<opaquelocktoken:headers>')
        ..write('<d:prop xmlns:d="DAV:"/>');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final token = await client.lock(
      '/file.txt',
      headers: const {
        'X-Lock-Test': 'yes',
        'Content-Type': 'application/custom+xml',
      },
    );

    expect(token, 'opaquelocktoken:headers');
    expect(custom, 'yes');
    expect(contentType, 'application/custom+xml');
  });

  test('unlock forwards caller supplied headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;
    String? lockToken;

    server.listen((request) async {
      custom = request.headers.value('X-Unlock-Test');
      lockToken = request.headers.value('Lock-Token');
      await request.drain();
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.unlock(
      '/file.txt',
      'opaquelocktoken:headers',
      headers: const {'X-Unlock-Test': 'yes'},
    );

    expect(custom, 'yes');
    expect(lockToken, '<opaquelocktoken:headers>');
  });
}
