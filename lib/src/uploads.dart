import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'rest_client.dart';
import 'types.dart';

class UploadFileParams {
  const UploadFileParams({
    required this.bytes,
    required this.filename,
    required this.mediaType,
    this.roomId,
  });

  final Uint8List bytes;
  final String filename;
  final String mediaType;
  final String? roomId;
}

class UploadFileResult {
  const UploadFileResult({
    required this.uploadId,
    required this.filename,
    required this.mediaType,
  });

  final String uploadId;
  final String filename;
  final String mediaType;
}

Future<UploadFileResult> uploadFileToStorage(
  RestClient rest,
  UploadFileParams params,
) async {
  final presigned = await rest.presignUpload(PresignUploadParams(
    filename: params.filename,
    mediaType: params.mediaType,
    sizeBytes: params.bytes.length,
    roomId: params.roomId,
  ));

  final put = await http.put(
    Uri.parse(presigned.uploadUrl),
    headers: {'Content-Type': params.mediaType},
    body: params.bytes,
  );
  if (put.statusCode < 200 || put.statusCode >= 300) {
    throw Exception('Upload PUT failed: ${put.statusCode}');
  }

  await rest.completeUpload(presigned.uploadId);
  return UploadFileResult(
    uploadId: presigned.uploadId,
    filename: params.filename,
    mediaType: params.mediaType,
  );
}
