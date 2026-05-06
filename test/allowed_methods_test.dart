import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('allowedMethods parses Allow headers from OPTIONS', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.add('Allow', 'OPTIONS, PROPFIND')
        ..headers.add('Allow', 'REPORT');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    expect(await client.allowedMethods(), ['OPTIONS', 'PROPFIND', 'REPORT']);
  });
}
