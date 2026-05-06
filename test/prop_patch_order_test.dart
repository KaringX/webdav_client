import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';
import 'package:xml/xml.dart';

void main() {
  test('propPatch preserves caller supplied PROPPATCH instruction order', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? capturedBody;
    String? capturedContentType;

    server.listen((request) async {
      capturedContentType = request.headers.contentType?.toString();
      capturedBody = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname />
        <x:color xmlns:x="http://example.com/ns" />
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

    await client.propPatch(
      '/file.txt',
      const [
        PropPatchOperation.remove('displayname'),
        PropPatchOperation.set('x:color', 'blue'),
        PropPatchOperation.setXml(
          'x:metadata',
          '<x:child xmlns:x="http://example.com/ns">value</x:child>',
        ),
      ],
      namespaces: const {'x': 'http://example.com/ns'},
    );

    expect(capturedContentType, contains('xml'));
    final document = XmlDocument.parse(capturedBody!);
    final operations = document.rootElement.childElements
        .map((element) => element.name.local)
        .toList(growable: false);

    expect(operations, ['remove', 'set', 'set']);
    expect(capturedBody, contains('<x:color>blue</x:color>'));
    expect(capturedBody, contains('<x:metadata>'));
    expect(capturedBody, contains('<x:child'));
  });
}
