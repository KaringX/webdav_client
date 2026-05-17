import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('create sends If-None-Match star', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifNoneMatch;

    server.listen((request) async {
      if (request.method == 'PUT') {
        ifNoneMatch = request.headers.value('If-None-Match');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else {
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.create('/file.txt', Uint8List.fromList([1]));

    expect(ifNoneMatch, '*');
  });

  test('create does not send PUT preconditions to parent MKCOL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? mkcolIfNoneMatch;
    String? putIfNoneMatch;

    server.listen((request) async {
      if (request.method == 'MKCOL') {
        mkcolIfNoneMatch = request.headers.value('If-None-Match');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == 'PUT') {
        putIfNoneMatch = request.headers.value('If-None-Match');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else {
        await request.drain();
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.create('/dir/file.txt', Uint8List.fromList([1]));

    expect(mkcolIfNoneMatch, isNull);
    expect(putIfNoneMatch, '*');
  });

  test('write does not send WebDAV If header to parent MKCOL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? mkcolIf;
    String? putIf;

    server.listen((request) async {
      if (request.method == 'MKCOL') {
        mkcolIf = request.headers.value('If');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == 'PUT') {
        putIf = request.headers.value('If');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else {
        await request.drain();
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.write(
      '/dir/file.txt',
      Uint8List.fromList([1]),
      headers: const {'If': '<http://localhost/dir/file.txt> (["etag"])'},
    );

    expect(mkcolIf, isNull);
    expect(putIf, '<http://localhost/dir/file.txt> (["etag"])');
  });

  test('write does not send PUT entity headers to parent MKCOL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? mkcolContentType;
    String? mkcolContentLength;
    String? mkcolContentEncoding;
    String? mkcolContentLanguage;
    String? mkcolContentRange;
    String? putContentType;
    String? putContentLength;
    String? putContentEncoding;
    String? putContentLanguage;
    String? putContentRange;

    server.listen((request) async {
      if (request.method == 'MKCOL') {
        mkcolContentType = request.headers.value('Content-Type');
        mkcolContentLength = request.headers.value('Content-Length');
        mkcolContentEncoding = request.headers.value('Content-Encoding');
        mkcolContentLanguage = request.headers.value('Content-Language');
        mkcolContentRange = request.headers.value('Content-Range');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == 'PUT') {
        putContentType = request.headers.value('Content-Type');
        putContentLength = request.headers.value('Content-Length');
        putContentEncoding = request.headers.value('Content-Encoding');
        putContentLanguage = request.headers.value('Content-Language');
        putContentRange = request.headers.value('Content-Range');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
      } else {
        await request.drain();
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    // WebdavClient.noAuth.write applies entity headers only to the final PUT;
    // automatic parent MKCOL probes must stay body-less.
    await client.write(
      '/dir/file.txt',
      Uint8List.fromList([1, 2, 3]),
      headers: const {
        'Content-Type': 'application/custom',
        'Content-Length': '99',
        'Content-Encoding': 'gzip',
        'Content-Language': 'en',
        'Content-Range': 'bytes 0-2/3',
      },
    );

    expect(mkcolContentType, isNull);
    // The client emits an empty MKCOL body, so the transport reports length 0
    // rather than inheriting the caller supplied PUT length.
    expect(mkcolContentLength, '0');
    expect(mkcolContentEncoding, isNull);
    expect(mkcolContentLanguage, isNull);
    expect(mkcolContentRange, isNull);
    expect(putContentType, 'application/custom');
    // Content-Length is normalized to the actual body length, not the caller
    // supplied override.
    expect(putContentLength, '3');
    expect(putContentEncoding, 'gzip');
    expect(putContentLanguage, 'en');
    expect(putContentRange, 'bytes 0-2/3');
  });

  test('updateIfMatch sends quoted If-Match etag', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? ifMatch;

    server.listen((request) async {
      if (request.method == 'PUT') {
        ifMatch = request.headers.value('If-Match');
        await request.drain();
        request.response.statusCode = HttpStatus.noContent;
      } else {
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.updateIfMatch(
      '/file.txt',
      Uint8List.fromList([1]),
      'etag-value',
    );

    expect(ifMatch, '"etag-value"');
  });
}
