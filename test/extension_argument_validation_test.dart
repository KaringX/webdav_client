import 'package:test/test.dart';
import 'package:webdav_client_plus/webdav_client_plus.dart';

void main() {
  test('syncCollection rejects Depth zero', () {
    final client = WebdavClient.noAuth(url: 'http://example.com');

    expect(
      () => client.syncCollection('/collection/', depth: PropsDepth.zero),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('syncCollection accepts Depth infinity', () {
    final client = WebdavClient.noAuth(url: 'http://example.com');

    expect(
      () => client.syncCollection('/collection/', depth: PropsDepth.infinity),
      returnsNormally,
    );
  });

  test('label rejects unknown action names', () {
    final client = WebdavClient.noAuth(url: 'http://example.com');

    expect(
      () => client.label('/version', labelName: 'release', action: 'invalid'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
