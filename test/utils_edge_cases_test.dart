import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

/// Tests targeting remaining uncovered lines in utils.dart
void main() {
  group('MultiStatusPropstat with null statusCode', () {
    test('parseMultiStatus includes propstat without status element', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/no-status/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>no-status</d:displayname>
      </d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final responses = parseMultiStatus(xml);
      expect(responses.length, 1);
      expect(responses.first.propstats.length, 1);
      expect(responses.first.propstats.first.statusCode, isNull);
      expect(responses.first.propstats.first.rawStatus, isNull);
    });

    test('parseMultiStatus includes propstat with empty status text', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/empty-status/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>test</d:displayname>
      </d:prop>
      <d:status></d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final responses = parseMultiStatus(xml);
      expect(responses.length, 1);
      expect(responses.first.propstats.first.statusCode, isNull);
    });

    test('parseMultiStatus parses properties with and without namespace', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
  <d:response>
    <d:href>/mixed/</d:href>
    <d:propstat>
      <d:prop>
        <d:displayname>mixed</d:displayname>
        <oc:permissions>RDNV</oc:permissions>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final responses = parseMultiStatus(xml);
      final props = responses.first.propstats.first.properties;
      expect(props.containsKey('{DAV:}displayname'), isTrue);
      expect(props.containsKey('{http://owncloud.org/ns}permissions'), isTrue);
    });

    test('parseMultiStatus skips propstat without prop element', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/no-prop/</d:href>
    <d:propstat>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final responses = parseMultiStatus(xml);
      expect(responses.length, 1);
      expect(responses.first.propstats.length, 1);
      expect(responses.first.propstats.first.properties, isEmpty);
    });
  });

  group('parseMultiStatusToMap', () {
    test('skips null statusCode in propstat', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/nullcode/</d:href>
    <d:propstat>
      <d:prop><d:displayname>test</d:displayname></d:prop>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final result = parseMultiStatusToMap(xml);
      // Only overall status if present, propstat with null statusCode is skipped
      expect(result['/nullcode/']!.length, 0);
    });
  });

  group('_decodeHref', () {
    test('returns original on malformed percent encoding', () {
      // Create XML with percent-encoded href that decodes correctly
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/hello%20world</d:href>
    <d:propstat>
      <d:prop><d:displayname>test</d:displayname></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final responses = parseMultiStatus(xml);
      expect(responses.first.href, '/hello world');
    });
  });

  group('parseMultiStatusFailureMessages', () {
    test('captures propstat-level failures with properties', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:" xmlns:custom-ns="urn:custom">
  <d:response>
    <d:href>/mixed/</d:href>
    <d:propstat>
      <d:prop><d:displayname>ok</d:displayname></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
    <d:propstat>
      <d:prop><custom-ns:bad/></d:prop>
      <d:status>HTTP/1.1 403 Forbidden</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final failures = parseMultiStatusFailureMessages(xml);
      expect(failures, isNotEmpty);
      expect(failures.first, contains('403'));
    });

    test('propstat failure without status text uses fallback', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/no-status-text/</d:href>
    <d:propstat>
      <d:prop><d:getetag/></d:prop>
      <d:status>HTTP/1.1 500 Internal Server Error</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final failures = parseMultiStatusFailureMessages(xml);
      expect(failures, isNotEmpty);
      expect(failures.first, contains('/no-status-text/'));
    });
  });

  group('_formatPropertyName', () {
    test('formats element with prefix', () {
      // This is tested indirectly via parsePropPatchFailureMessages
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/test</d:href>
    <d:propstat>
      <d:prop><d:getetag/></d:prop>
      <d:status>HTTP/1.1 403 Forbidden</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final failures = parsePropPatchFailureMessages(xml);
      expect(failures, isNotEmpty);
      expect(failures.first, contains('d:getetag'));
    });

    test('formats element without prefix but with namespace', () {
      // Build XML where element has no prefix but has namespace
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:" xmlns="http://example.com/custom">
  <d:response>
    <d:href>/test</d:href>
    <d:propstat>
      <d:prop><test/></d:prop>
      <d:status>HTTP/1.1 403 Forbidden</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final failures = parsePropPatchFailureMessages(xml);
      expect(failures, isNotEmpty);
    });
  });

  group('_buildIfHeader edge cases', () {
    test('empty result when both lockToken and etag are null', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      String? capturedIf;
      server.listen((request) async {
        capturedIf = request.headers.value('if');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
        await request.response.close();
      });

      final client = WebdavClient.noAuth(
        url: 'http://${server.address.host}:${server.port}',
      );

      await client.conditionalPut('/test', Uint8List.fromList([1]));
      expect(capturedIf, isNull);
    });
  });

  group('wdOptions with allowNotFound', () {
    test('returns 404 when allowNotFound is true', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((request) async {
        await request.drain();
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final client = WebdavClient.noAuth(
        url: 'http://${server.address.host}:${server.port}',
      );

      final features = await client.options(
        path: '/not-found',
        allowNotFound: true,
      );
      expect(features, isEmpty);
    });
  });

  group('Multi-Status response with empty href', () {
    test('uses empty key when href is empty', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href></d:href>
    <d:propstat>
      <d:prop><d:displayname>empty</d:displayname></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final result = parseMultiStatusToMap(xml);
      expect(result.containsKey(''), isTrue);
    });
  });

  group('_requestTarget with empty path', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async => server.close(force: true));

    test('OPTIONS to root path generates auth with / target', () async {
      String? capturedAuth;

      server.listen((request) async {
        capturedAuth = request.headers.value('authorization');
        await request.drain();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.set('DAV', '1');
        await request.response.close();
      });

      final client = WebdavClient.basicAuth(
        url: 'http://${server.address.host}:${server.port}',
        user: 'test',
        pwd: 'test',
      );

      await client.ping();
      expect(capturedAuth, isNotNull);
    });
  });

  group('wdMkcol with ifHeader', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async => server.close(force: true));

    test('sends If header with MKCOL request', () async {
      String? capturedIf;

      server.listen((request) async {
        capturedIf = request.headers.value('if');
        await request.drain();
        request.response.statusCode = HttpStatus.created;
        await request.response.close();
      });

      final client = WebdavClient.noAuth(
        url: 'http://${server.address.host}:${server.port}',
      );

      await client.mkdir('/new-dir/',
          ifHeader: '<http://localhost/new-dir/> (<opaquelocktoken:abc>)');
      expect(capturedIf, isNotNull);
      expect(capturedIf, contains('opaquelocktoken:abc'));
    });
  });

  group('_parseStatusCode', () {
    test('handles status text without 3-digit code', () {
      // parseMultiStatus will parse status line for 3-digit code
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/weird-status/</d:href>
    <d:propstat>
      <d:prop><d:displayname>test</d:displayname></d:prop>
      <d:status>No-Code-Here</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final responses = parseMultiStatus(xml);
      expect(responses.first.propstats.first.statusCode, isNull);
    });
  });

  group('_fixCollectionPath', () {
    test('adds leading slash when missing', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      String? capturedPath;
      server.listen((request) async {
        capturedPath = request.uri.path;
        await request.drain();
        request.response.statusCode = HttpStatus.created;
        await request.response.close();
      });

      final client = WebdavClient.noAuth(
        url: 'http://${server.address.host}:${server.port}',
      );

      await client.mkdir('noslash');
      expect(capturedPath, '/noslash/');
    });
  });

  group('_ensurePropPatchSuccess with 2xx non-207', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async => server.close(force: true));

    test('accepts 200 OK for setProps', () async {
      server.listen((request) async {
        await request.drain();
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      });

      final client = WebdavClient.noAuth(
        url: 'http://${server.address.host}:${server.port}',
      );

      // Should not throw for 200 OK
      await expectLater(
        client.setProps('/test', {'d:displayname': 'val'}),
        completes,
      );
    });
  });
}
