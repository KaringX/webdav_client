import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('principalMatch builds self REPORT body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? body;

    server.listen((request) async {
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

    final response = await client.principalMatch('/principals/', self: true);

    expect(body, contains('<d:principal-match'));
    expect(body, contains('<d:self/>'));
    expect(response.data, '<multistatus/>');
  });

  test('principalMatch builds property REPORT body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? body;

    server.listen((request) async {
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

    await client.principalMatch(
      '/principals/',
      property: 'group-member-set',
      properties: const ['displayname'],
    );

    expect(body, contains('<d:group-member-set/>'));
    expect(body, contains('<d:displayname/>'));
  });

  test('principalMatch declares namespace for custom match property', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? body;

    server.listen((request) async {
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

    await client.principalMatch(
      '/principals/',
      property: 'x:foo',
      properties: const ['displayname'],
      namespaces: const {'x': 'http://example.com/ns'},
    );

    expect(body, contains('xmlns:x="http://example.com/ns"'));
    expect(body, contains('<x:foo/>'));
    expect(body, contains('<d:displayname/>'));
  });

  test('principalMatch requires self or property', () {
    final client = WebdavClient.noAuth(url: 'http://example.com');

    expect(
      () => client.principalMatch('/principals/'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
