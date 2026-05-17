import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('quota supports custom path and headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? custom;
    String? path;

    server.listen((request) async {
      custom = request.headers.value('X-Quota-Test');
      path = request.uri.path;
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/user/</d:href>
    <d:propstat>
      <d:prop>
        <d:quota-used-bytes>26214400</d:quota-used-bytes>
        <d:quota-available-bytes>78643200</d:quota-available-bytes>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final quota = await client.quota(
      path: '/user/',
      headers: const {'X-Quota-Test': 'yes'},
    );

    expect(path, '/user/');
    expect(custom, 'yes');
    expect(quota.$1, 0.25);
    expect(quota.$2, '25.00M/100.00M');
  });

  test('quotaBytes returns raw used and available byte counts', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/</d:href>
    <d:propstat>
      <d:prop>
        <d:quota-used-bytes>11</d:quota-used-bytes>
        <d:quota-available-bytes>-1</d:quota-available-bytes>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    expect(await client.quotaBytes(), (11, -1));
  });
}
