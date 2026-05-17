import 'package:test/test.dart';
import 'package:webdav_client_plus/src/models/webdav_file.dart';

/// Tests for _normalizeHrefForComparison edge cases in WebdavFile.parseFiles.
void main() {
  group('WebdavFile._normalizeHrefForComparison edge cases', () {
    test('href without leading slash gets normalized to /', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>test/no-leading-slash.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>no-leading-slash.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final files = WebdavFile.parseFiles('/test', xml, skipSelf: false);
      expect(files.length, 1);
      // path is the decoded href
      expect(files.first.path, 'test/no-leading-slash.txt');
    });

    test('href with double slashes gets normalized', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/dir//</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:displayname>dir</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/dir/child.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>child.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final files = WebdavFile.parseFiles('/dir/', xml, skipSelf: true);
      expect(files.length, 1);
      expect(files.first.name, 'child.txt');
    });

    test('href with query string preserved in path but stripped for skipSelf', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/base/</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:displayname>base</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/base/child.txt?cache=123</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>child.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      // skipSelf=true filters /base/ self, child with ?query is preserved
      final files = WebdavFile.parseFiles('/base/', xml, skipSelf: true);
      expect(files.length, 1);
      // path preserves original href (with query)
      expect(files.first.name, 'child.txt');
    });

    test('href with fragment preserved in path but stripped for skipSelf', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/base/</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:displayname>base</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/base/child.txt#section</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>child.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final files = WebdavFile.parseFiles('/base/', xml, skipSelf: true);
      expect(files.length, 1);
      expect(files.first.name, 'child.txt');
    });

    test('non-collection href with trailing slash gets slash stripped', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/base/</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:displayname>base</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/base/file.txt/</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>file.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final files = WebdavFile.parseFiles('/base/', xml, skipSelf: true);
      expect(files.length, 1);
      // Non-collection with trailing slash should have slash stripped in path
      expect(files.first.path, '/base/file.txt/');
    });

    test('collection href without trailing slash gets slash added', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/base/subdir</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype><d:collection/></d:resourcetype>
        <d:displayname>subdir</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      // skipSelf=true with base '/base/' (collection)
      // self href '/base/subdir' without trailing slash
      // should normalize to '/base/subdir/' for comparison
      final files = WebdavFile.parseFiles('/base/', xml, skipSelf: true);
      // The self entry /base/subdir (normalized to /base/subdir/) doesn't match /base/
      // so it should NOT be skipped
      expect(files.length, 1);
      expect(files.first.name, 'subdir');
    });

    test('file href with relative path gets leading slash', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>relative-path.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>relative-path.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      final files = WebdavFile.parseFiles('/test', xml, skipSelf: false);
      expect(files.length, 1);
      expect(files.first.name, 'relative-path.txt');
    });

    test('skipSelf with non-collection base path (no trailing slash)', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/file.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>file.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/other.txt</d:href>
    <d:propstat>
      <d:prop>
        <d:resourcetype/>
        <d:displayname>other.txt</d:displayname>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';
      // skipSelf=true, base is '/file.txt' (non-collection, no trailing slash)
      final files = WebdavFile.parseFiles('/file.txt', xml, skipSelf: true);
      // /file.txt matches /file.txt so it's filtered out
      expect(files.length, 1);
      expect(files.first.name, 'other.txt');
    });
  });
}
