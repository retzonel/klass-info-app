import 'package:cloud_firestore/cloud_firestore.dart';

class FileModel {
  final String id;
  final String name;
  final String url;           // Firebase Storage download URL
  final String fileType;      // 'pdf', 'doc', 'ppt', etc.
  final String uploadedBy;    // uid
  final DateTime uploadedAt;

  const FileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory FileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FileModel(
      id: doc.id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      fileType: data['fileType'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  String get localFileName {
    return name.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
  }

  // Returns the right icon for each file type
  String get displayType => fileType.toUpperCase();

  bool get isPdf => fileType.toLowerCase() == 'pdf';
}