import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('write forwards caller supplied PUT headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? contentType;
    String? ifMatch;

    server.listen((request) async {
      if (request.method == 'PUT') {
        contentType = request.headers.contentType?.mimeType;
        ifMatch = request.headers.value('If-Match');
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

    await client.write(
      '/file.txt',
      Uint8List.fromList([1, 2, 3]),
      headers: const {
        'Content-Type': 'text/plain',
        'If-Match': '"abc"',
      },
    );

    expect(contentType, 'text/plain');
    expect(ifMatch, '"abc"');
  });

  test('writeStream uploads caller supplied byte streams', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    var body = <int>[];
    String? contentType;

    server.listen((request) async {
      if (request.method == 'PUT') {
        contentType = request.headers.contentType?.mimeType;
        body = await request.fold<List<int>>(
          <int>[],
          (previous, chunk) => previous..addAll(chunk),
        );
        request.response.statusCode = HttpStatus.created;
      } else {
        request.response.statusCode = HttpStatus.ok;
      }
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.writeStream(
      '/stream.txt',
      Stream<List<int>>.fromIterable([
        [1, 2],
        [3],
      ]),
      3,
      headers: const {'Content-Type': 'application/custom'},
    );

    expect(contentType, 'application/custom');
    expect(body, [1, 2, 3]);
  });

  test('writeFile forwards caller supplied PUT headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final tempDir = await Directory.systemTemp.createTemp('wd_write_headers_');
    addTearDown(() async {
      await server.close(force: true);
      await tempDir.delete(recursive: true);
    });

    final localFile = File('${tempDir.path}/upload.txt');
    await localFile.writeAsString('hello');

    String? contentType;
    String? ifNoneMatch;

    server.listen((request) async {
      if (request.method == 'PUT') {
        contentType = request.headers.contentType?.mimeType;
        ifNoneMatch = request.headers.value('If-None-Match');
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

    await client.writeFile(
      localFile.path,
      '/upload.txt',
      headers: const {
        'Content-Type': 'text/plain',
        'If-None-Match': '*',
      },
    );

    expect(contentType, 'text/plain');
    expect(ifNoneMatch, '*');
  });
}
