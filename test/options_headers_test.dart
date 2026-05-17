import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('options forwards caller supplied headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;

    server.listen((request) async {
      custom = request.headers.value('X-Options-Test');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set('DAV', '1, 2');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final capabilities = await client.options(
      headers: const {'X-Options-Test': 'yes'},
    );

    expect(custom, 'yes');
    expect(capabilities, ['1', '2']);
  });

  test('ping forwards caller supplied OPTIONS headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;

    server.listen((request) async {
      custom = request.headers.value('X-Ping-Test');
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.ping(null, const {'X-Ping-Test': 'yes'});

    expect(custom, 'yes');
  });
}
