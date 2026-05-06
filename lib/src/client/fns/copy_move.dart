part of '../client.dart';

extension WebdavClientCopyMove on WebdavClient {
  /// Rename a folder or file
  /// If you rename the folder, some webdav services require a '/' at the end of the path.
  ///
  /// {@template webdav_client_rename}
  /// - [oldPath] of the resource
  /// - [newPath] of the resource
  /// - [overwrite] If true, the destination will be overwritten
  /// - [cancelToken] for cancelling the request
  /// - [depth] sets the MOVE `Depth` header (RFC 4918 §10.2 only allows
  ///   `PropsDepth.infinity`)
  /// - [ifHeader] supplies preconditions such as lock tokens via an HTTP If header
  /// {@endtemplate}
  Future<void> rename(
    String oldPath,
    String newPath, {
    bool overwrite = false,
    CancelToken? cancelToken,
    PropsDepth? depth,
    String? ifHeader,
    Map<String, dynamic>? headers,
  }) {
    if (depth != null && depth != PropsDepth.infinity) {
      throw ArgumentError(
        'MOVE requests only support Depth.infinity per RFC 4918 §10.2',
      );
    }

    return _client.wdCopyMove(
      oldPath,
      newPath,
      false,
      overwrite,
      cancelToken: cancelToken,
      depth: PropsDepth.infinity,
      ifHeader: ifHeader,
      headers: headers,
    );
  }

  /// Move a folder or file
  /// If you move the folder, some webdav services require a '/' at the end of the path.
  ///
  /// - [oldPath] of the resource
  /// - [newPath] of the resource
  /// - [overwrite] If true, the destination will be overwritten
  /// - [cancelToken] for cancelling the request
  /// - [ifHeader] supplies preconditions such as lock tokens via an HTTP If header
  /// - [depth] of the PROPFIND request
  ///
  /// {@macro webdav_client_rename}
  Future<void> move(
    String oldPath,
    String newPath, {
    bool overwrite = false,
    CancelToken? cancelToken,
    PropsDepth? depth,
    String? ifHeader,
    Map<String, dynamic>? headers,
  }) {
    return rename(
      oldPath,
      newPath,
      overwrite: overwrite,
      cancelToken: cancelToken,
      depth: depth,
      ifHeader: ifHeader,
      headers: headers,
    );
  }

  /// Copy a file / folder.
  ///
  /// - [oldPath] of the resource
  /// - [newPath] of the resource
  /// - [overwrite] If true, the destination will be overwritten
  /// - [cancelToken] for cancelling the request
  /// - [ifHeader] supplies preconditions such as lock tokens via an HTTP If header
  ///
  /// **Warning:**
  /// If copied the folder (A > B), it will copy all the contents of folder A to folder B.
  /// Some WebDAV services may **delete** existing contents in the target folder.
  Future<void> copy(
    String oldPath,
    String newPath, {
    bool overwrite = false,
    CancelToken? cancelToken,
    String? ifHeader,
    PropsDepth depth = PropsDepth.infinity,
    Map<String, dynamic>? headers,
  }) {
    if (depth == PropsDepth.one) {
      throw ArgumentError(
        'COPY requests only support Depth 0 or infinity per RFC 4918 §9.8',
      );
    }

    return _client.wdCopyMove(
      oldPath,
      newPath,
      true,
      overwrite,
      cancelToken: cancelToken,
      ifHeader: ifHeader,
      depth: depth,
      headers: headers,
    );
  }
}
