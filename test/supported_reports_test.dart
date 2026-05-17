import 'dart:io';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('supportedReports parses supported-report-set entries', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) async {
      await request.drain();
      request.response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:response>
    <d:href>/</d:href>
    <d:propstat>
      <d:prop>
        <d:supported-report-set>
          <d:supported-report><d:report><d:expand-property/></d:report></d:supported-report>
          <d:supported-report><d:report><c:calendar-query/></d:report></d:supported-report>
        </d:supported-report-set>
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

    final reports = await client.supportedReports();

    expect(reports, contains('d:expand-property'));
    expect(reports, contains('c:calendar-query'));
  });
}
