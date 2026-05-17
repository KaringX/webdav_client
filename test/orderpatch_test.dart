import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('orderpatch sends ORDERPATCH XML body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? depth;
    String? body;

    server.listen((request) async {
      method = request.method;
      depth = request.headers.value('Depth');
      body = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('application', 'xml')
        ..write('<ok/>');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.orderpatch('/ordered/', '<orderpatch/>');

    expect(method, 'ORDERPATCH');
    expect(depth, isNull);
    expect(body, '<orderpatch/>');
    expect(response.data, '<ok/>');
  });
}
