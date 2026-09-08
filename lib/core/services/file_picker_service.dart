import 'package:flutter/foundation.dart';

/// Representation of a selected CV file for job application
@immutable
class SelectedCvFile {
  final String name;
  final String? path;
  final int size; // size in bytes
  final Uint8List? bytes;

  const SelectedCvFile({
    required this.name,
    this.path,
    required this.size,
    this.bytes,
  });

  /// Formatted size in KB or MB
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// File extension (lowercase, e.g. 'pdf', 'docx')
  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex + 1).toLowerCase();
    }
    return '';
  }

  /// Check if file extension is an allowed document format
  bool get isValidCvFormat {
    final ext = extension;
    return ext == 'pdf' || ext == 'doc' || ext == 'docx';
  }
}

/// Abstract contract for CV file selection service (MOB-01-04)
abstract class ICvPickerService {
  /// Open file picker to choose a CV file (.pdf, .doc, .docx)
  Future<SelectedCvFile?> pickCvFile();
}

/// In-memory & Test-friendly Mock CV Picker
class MockCvPickerService implements ICvPickerService {
  final SelectedCvFile? predefinedFile;

  MockCvPickerService({this.predefinedFile});

  @override
  Future<SelectedCvFile?> pickCvFile() async {
    // Return predefined file or realistic default candidate CV
    return predefinedFile ??
        const SelectedCvFile(
          name: 'Nguyen_Van_A_CV_Flutter_2026.pdf',
          path: '/mock/documents/Nguyen_Van_A_CV_Flutter_2026.pdf',
          size: 420 * 1024, // 420 KB
        );
  }
}
