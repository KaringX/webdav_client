import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('principalPropertySearch builds RFC 3744 REPORT body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? body;

    server.listen((request) async {
      method = request.method;
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

    final response = await client.principalPropertySearch(
      '/principals/',
      property: 'displayname',
      match: 'Alice',
      properties: const ['displayname', 'x:custom'],
      namespaces: const {'x': 'http://example.com/ns'},
    );

    expect(method, 'REPORT');
    expect(body, contains('<d:principal-property-search'));
    expect(body, contains('<d:property-search>'));
    expect(body, contains('<d:match>Alice</d:match>'));
    expect(body, contains('<d:displayname/>'));
    expect(body, contains('<x:custom/>'));
    expect(response.data, '<multistatus/>');
  });

  test('principalSearchPropertySet builds RFC 3744 REPORT body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? body;

    server.listen((request) async {
      body = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('application', 'xml')
        ..write('<set/>');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.principalSearchPropertySet('/principals/');

    expect(body, contains('<d:principal-search-property-set'));
    expect(response.data, '<set/>');
  });
}
