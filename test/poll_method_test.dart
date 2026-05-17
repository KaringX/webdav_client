import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('poll sends POLL with Subscription-ID header', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? subscription;

    server.listen((request) async {
      method = request.method;
      subscription = request.headers.value('Subscription-ID');
      await request.drain();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('application', 'xml')
        ..write('<poll/>');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.poll('/resource', subscriptionId: 'sub-1');

    expect(method, 'POLL');
    expect(subscription, 'sub-1');
    expect(response.data, '<poll/>');
  });
}
