import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('digest authentication retries only once for repeated challenges',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    var count = 0;

    server.listen((request) async {
      count++;
      await request.drain();
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..headers.add(
          HttpHeaders.wwwAuthenticateHeader,
          'Digest realm="r", nonce="n", qop="auth"',
        );
      await request.response.close();
    });

    final client = WebdavClient(
      url: 'http://${server.address.host}:${server.port}',
      auth: DigestAuth(
        user: 'u',
        pwd: 'p',
        digestParts: DigestParts('Digest realm="r", nonce="initial"'),
      ),
    );

    await expectLater(
      client.request<String>('GET'),
      throwsA(isA<WebdavException>()),
    );
    expect(count, 2);
  });
}
