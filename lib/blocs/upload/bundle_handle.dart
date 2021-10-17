import 'package:ardrive/blocs/upload/file_upload_handle.dart';
import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';

class BundleHandle {
  final List<FileUploadHandle> fileUploadHandles;

  BigInt get cost {
    return bundleTx.reward;
  }

  /// The size of the file before it was encoded/encrypted for upload.
  int? get size =>
      fileUploadHandles.map((e) => e.size ?? 0).reduce((a, b) => (a + b));

  /// The size of the file that has been uploaded, not accounting for the file encoding/encryption overhead.
  int get uploadedSize => (size! * uploadProgress).round();

  double uploadProgress = 0;

  late Transaction bundleTx;

  BundleHandle({
    required this.fileUploadHandles,
    required this.bundleTx,
  });

  Stream<Null> upload(ArweaveService arweave) async* {
    await for (final upload in arweave.client.transactions.upload(bundleTx)) {
      uploadProgress = upload.progress;
      yield null;
    }
  }
}
