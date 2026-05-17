import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('subscribe sends SUBSCRIBE notification headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? callback;
    String? subscriptionId;
    String? lifetime;

    server.listen((request) async {
      method = request.method;
      callback = request.headers.value('Call-Back');
      subscriptionId = request.headers.value('Subscription-ID');
      lifetime = request.headers.value('Subscription-Lifetime');
      await request.drain();
      request.response
        ..statusCode = HttpStatus.ok
        ..write('subscribed');
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    final response = await client.subscribe(
      '/resource',
      callback: 'https://example.com/hook',
      subscriptionId: 'sub-1',
      lifetimeSeconds: 60,
    );

    expect(method, 'SUBSCRIBE');
    expect(callback, 'https://example.com/hook');
    expect(subscriptionId, 'sub-1');
    expect(lifetime, '60');
    expect(response.data, 'subscribed');
  });

  test('unsubscribe sends UNSUBSCRIBE with Subscription-ID', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    String? method;
    String? subscriptionId;

    server.listen((request) async {
      method = request.method;
      subscriptionId = request.headers.value('Subscription-ID');
      await request.drain();
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });

    final client = WebdavClient.noAuth(
      url: 'http://${server.address.host}:${server.port}',
    );

    await client.unsubscribe('/resource', subscriptionId: 'sub-1');

    expect(method, 'UNSUBSCRIBE');
    expect(subscriptionId, 'sub-1');
  });
}
