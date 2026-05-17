import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  Future<(String method, String? custom)> capture(
    Future<void> Function(WebdavClient client) action,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? custom;

    server.listen((request) async {
      method = request.method;
      custom = request.headers.value('X-DeltaV-Test');
      await request.drain();
      request.response
        ..statusCode = HttpStatus.created
        ..write('created');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );
    await action(client);
    return (method!, custom);
  }

  test('mkactivity sends MKACTIVITY', () async {
    final result = await capture((client) async {
      await client.mkactivity(
        '/activities/a1',
        headers: const {'X-DeltaV-Test': 'activity'},
      );
    });

    expect(result, ('MKACTIVITY', 'activity'));
  });

  test('baselineControl sends BASELINE-CONTROL', () async {
    final result = await capture((client) async {
      await client.baselineControl(
        '/vcc/',
        headers: const {'X-DeltaV-Test': 'baseline'},
      );
    });

    expect(result, ('BASELINE-CONTROL', 'baseline'));
  });
}
