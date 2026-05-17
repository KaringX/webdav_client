import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('label sends RFC 3253 LABEL body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? body;

    server.listen((request) async {
      method = request.method;
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

    final response = await client.label(
      '/versions/1',
      labelName: 'release',
      action: 'add',
    );

    expect(method, 'LABEL');
    expect(body, contains('<d:label'));
    expect(body, contains('<d:add>'));
    expect(body, contains('<d:label-name>release</d:label-name>'));
    expect(response.data, '<ok/>');
  });
}
