import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_secrets.dart';
import '../../../core/services/firestore_service.dart';
import '../models/file_model.dart';

class FileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ─── Pick ────────────────────────────────────────────────────────────────

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  // ─── Upload ──────────────────────────────────────────────────────────────

  Future<void> uploadFile({
    required String classCode,
    required String courseId,
    required String uploadedBy,
    required PlatformFile pickedFile,
    required Function(double progress) onProgress,
  }) async {
    final file = File(pickedFile.path!);
    final fileName = pickedFile.name;
    final extension =
        path.extension(fileName).replaceAll('.', '').toLowerCase();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppSecrets.cloudinaryCloudName}/auto/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppSecrets.cloudinaryUploadPreset
      ..fields['folder'] = 'klassinfo/$classCode/$courseId'
      ..fields['public_id'] = path.basenameWithoutExtension(fileName)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    onProgress(0.1);
    final streamedResponse = await request.send();
    onProgress(0.7);
    final response = await http.Response.fromStream(streamedResponse);
    onProgress(0.9);

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final downloadUrl = responseData['secure_url'] as String;
    onProgress(1.0);

    final fileModel = FileModel(
      id: '',
      name: fileName,
      url: downloadUrl,
      fileType: extension,
      uploadedBy: uploadedBy,
      uploadedAt: DateTime.now(),
    );

    await _db
        .collection('classes')
        .doc(classCode)
        .collection('courses')
        .doc(courseId)
        .collection('files')
        .add(fileModel.toMap());
  }

  // ─── Cache + Download ────────────────────────────────────────────────────

  /// Returns the local [File] for [fileModel], downloading from Cloudinary
  /// only if it hasn't been cached yet. Calls [onProgress] with 0.0→1.0.
  Future<File> getOrDownloadFile(
    FileModel fileModel, {
    required void Function(double) onProgress,
  }) async {
    final localFile = await _localFileFor(fileModel);

    // Already on disk — nothing to do
    if (await localFile.exists()) {
      onProgress(1.0);
      return localFile;
    }

    // Download from Cloudinary
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(fileModel.url));
      final streamedResponse = await client.send(request);

      final contentLength = streamedResponse.contentLength ?? 0;
      var received = 0;

      final sink = localFile.openWrite();
      await streamedResponse.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (contentLength > 0) {
            onProgress(received / contentLength);
          }
        },
        onDone: () {},
        cancelOnError: true,
      ).asFuture();

      await sink.flush();
      await sink.close();
      onProgress(1.0);
      return localFile;
    } catch (e) {
      // Clean up partial file on error
      if (await localFile.exists()) await localFile.delete();
      client.close();
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Whether the file is already downloaded locally.
  Future<bool> isDownloaded(FileModel fileModel) async {
    final localFile = await _localFileFor(fileModel);
    return localFile.exists();
  }

  /// Canonical local path for a given file.
  /// Uses the app's documents directory so it persists across app restarts.
  Future<File> _localFileFor(FileModel fileModel) async {
    final dir = await getApplicationDocumentsDirectory();
    final klassDir =
        Directory('${dir.path}/klassinfo_files');
    if (!await klassDir.exists()) await klassDir.create(recursive: true);
    return File('${klassDir.path}/${fileModel.localFileName}');
  }

  // ─── Stream ──────────────────────────────────────────────────────────────

  Stream<List<FileModel>> filesStream(String classCode, String courseId) {
    return _firestoreService
        .filesStream(classCode, courseId)
        .map((snapshot) =>
            snapshot.docs.map((doc) => FileModel.fromFirestore(doc)).toList());
  }
}