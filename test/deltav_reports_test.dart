import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  Future<(String body, String? depth)> capture(
    Future<void> Function(WebdavClient client) action,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? body;
    String? depth;

    server.listen((request) async {
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
    await action(client);
    return (body!, depth);
  }

  test('versionTree builds version-tree REPORT', () async {
    final result = await capture((client) async {
      await client.versionTree('/versions/1', properties: const ['getetag']);
    });

    expect(result.$1, contains('<d:version-tree'));
    expect(result.$1, contains('<d:getetag/>'));
    expect(result.$2, '0');
  });

  test('versionHistoryReport builds version-history REPORT', () async {
    final result = await capture((client) async {
      await client.versionHistoryReport(
        '/file.txt',
        properties: const ['x:custom'],
        namespaces: const {'x': 'http://example.com/ns'},
      );
    });

    expect(result.$1, contains('<d:version-history'));
    expect(result.$1, contains('xmlns:x="http://example.com/ns"'));
    expect(result.$1, contains('<x:custom/>'));
  });
}
