import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.meta = const <String, Object?>{},
  });

  final DateTime timestamp;
  final String category;
  final String message;
  final Map<String, Object?> meta;

  Map<String, Object?> toJson() => <String, Object?>{
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'message': message,
    'meta': meta,
  };

  static AppLogEntry fromJson(Map<String, dynamic> json) {
    return AppLogEntry(
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      category: json['category'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      meta:
          (json['meta'] as Map?)?.cast<String, Object?>() ??
          const <String, Object?>{},
    );
  }
}

class AppLogService {
  static const String _fileName = 'finarc_debug_logs.jsonl';
  static const int _maxEntriesInFile = 1000;
  final List<AppLogEntry> _memoryEntries = <AppLogEntry>[];

  Future<void> log({
    required String category,
    required String message,
    Map<String, Object?> meta = const <String, Object?>{},
  }) async {
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      meta: meta,
    );
    _memoryEntries.insert(0, entry);
    if (_memoryEntries.length > 200) {
      _memoryEntries.removeRange(200, _memoryEntries.length);
    }
    try {
      await _appendToDisk(entry);
    } catch (_) {
      // Best-effort logging only. Never block app/test flows on disk logging.
    }
  }

  List<AppLogEntry> recentMemoryEntries() =>
      List<AppLogEntry>.unmodifiable(_memoryEntries);

  Future<List<AppLogEntry>> readFromDisk() async {
    final file = await _file();
    if (!await file.exists()) return const <AppLogEntry>[];
    final lines = await file.readAsLines();
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          try {
            return AppLogEntry.fromJson(
              jsonDecode(line) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<AppLogEntry>()
        .toList(growable: false)
        .reversed
        .toList(growable: false);
  }

  Future<void> clear() async {
    _memoryEntries.clear();
    final file = await _file();
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }

  Future<void> _appendToDisk(AppLogEntry entry) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(entry.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
    await _trimFile(file);
  }

  Future<void> _trimFile(File file) async {
    final lines = await file.readAsLines();
    if (lines.length <= _maxEntriesInFile) return;
    final trimmed = lines.skip(lines.length - _maxEntriesInFile).join('\n');
    await file.writeAsString('$trimmed\n', flush: true);
  }

  Future<File> _file() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File(p.join(dir.path, _fileName));
    } catch (_) {
      return File(p.join(Directory.systemTemp.path, _fileName));
    }
  }
}

final AppLogService globalAppLogService = AppLogService();
