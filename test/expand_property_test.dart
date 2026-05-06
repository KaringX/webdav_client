import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('expandProperty builds RFC 3253 REPORT body', () async {
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
        ..statusCode = HttpStatus.multiStatus
        ..headers.contentType = ContentType('application', 'xml')
        ..write('<multistatus/>');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.expandProperty(
      '/resource',
      const [
        ExpandProperty('version-history', [
          ExpandProperty('x:custom'),
        ]),
      ],
      namespaces: const {'x': 'http://example.com/ns'},
    );

    expect(method, 'REPORT');
    expect(depth, '0');
    expect(body, contains('<d:expand-property'));
    expect(body, contains('name="version-history"'));
    expect(body, contains('name="custom"'));
    expect(body, contains('namespace="http://example.com/ns"'));
    expect(response.data, '<multistatus/>');
  });
}
