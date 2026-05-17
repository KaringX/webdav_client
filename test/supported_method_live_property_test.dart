import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('supportedMethods returns supported-method names', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await request.drain();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/</d:href><d:propstat><d:prop>
    <d:supported-method-set>
      <d:supported-method name="OPTIONS"/>
      <d:supported-method name="PROPFIND"/>
    </d:supported-method-set>
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    expect(await client.supportedMethods(), ['OPTIONS', 'PROPFIND']);
  });

  test('supportedLiveProperties returns property names', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await request.drain();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:x="http://example.com/ns">
  <d:response><d:href>/</d:href><d:propstat><d:prop>
    <d:supported-live-property-set>
      <d:supported-live-property><d:getetag/></d:supported-live-property>
      <d:supported-live-property><x:custom/></d:supported-live-property>
    </d:supported-live-property-set>
  </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final properties = await client.supportedLiveProperties();
    expect(properties, contains('d:getetag'));
    expect(properties, contains('x:custom'));
  });
}
