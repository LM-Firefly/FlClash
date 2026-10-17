import 'dart:io';
import 'package:fl_clash/common/file.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Data stays beside the executable while portable mode is on, so a moved
/// install carries its profiles and settings along.
///
/// A `portable` marker file next to the executable is the on-disk switch: it
/// is visible before any preference store is open, which is what
/// [AppPath.supportDirectory] needs at startup. The settings toggle only
/// creates or deletes that marker.
///
/// User data lives in `data/clash`, not `data` itself: the Windows build
/// already ships Flutter's own `data` folder there (`flutter_assets`,
/// `app.so`, `icudtl.dat`), and writing profiles beside those would mix the
/// two.
class PortableMode {
  static PortableMode? _instance;

  PortableMode._internal();

  factory PortableMode() {
    _instance ??= PortableMode._internal();
    return _instance!;
  }

  @visibleForTesting
  static String Function() resolveRoot = () =>
      dirname(Platform.resolvedExecutable);

  @visibleForTesting
  static Future<Directory> Function() resolveSystemSupport =
      getApplicationSupportDirectory;

  String get rootPath => resolveRoot();

  String get markerPath => join(rootPath, 'portable');

  Directory get dataDirectory => Directory(join(rootPath, 'data', 'clash'));

  bool get enabled => File(markerPath).existsSync();

  bool get hasLocalData {
    final dir = dataDirectory;
    return File(join(dir.path, 'shared_preferences.json')).existsSync() ||
        File(join(dir.path, 'database.sqlite')).existsSync();
  }

  Future<void> enable() async {
    await dataDirectory.create(recursive: true);
    await File(markerPath).writeAsString('');
    await ensureLocalData();
  }

  Future<void> disable() async {
    await File(markerPath).safeDelete();
  }

  /// Copies the system data directory over once, so the first portable start
  /// keeps the profiles the user already had. A portable directory that already
  /// holds data is left alone.
  Future<void> ensureLocalData() async {
    if (hasLocalData) {
      return;
    }
    final source = await resolveSystemSupport();
    if (!await source.exists()) {
      return;
    }
    await _copyDirectoryContents(source, dataDirectory);
  }

  Future<void> _copyDirectoryContents(
    Directory source,
    Directory target,
  ) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = basename(entity.path);
      if (name == 'FlClash.lock') {
        continue;
      }
      final destination = join(target.path, name);
      if (entity is File) {
        await entity.copy(destination);
      } else if (entity is Directory) {
        await _copyDirectoryContents(entity, Directory(destination));
      }
    }
  }
}

final portableMode = PortableMode();

/// Switching the data directory cannot land mid-session: the database and the
/// single-instance lock already hold the old one.
///
/// The waiter must outlive this process and must never block it:
///
/// * `Process.run` on a script that polls for this PID deadlocks — the run
///   holds this process open, so the PID never goes away. `Process.start`
///   plus `start` (ShellExecute) puts the waiter in its own process tree and
///   returns at once.
/// * `cmd /c start "" "path"` as one argv is also unsafe: Dart escapes the
///   inner quotes as `\"`, which cmd does not read as quotes. The launcher is
///   split into separate argv elements, and the exe path lives inside the
///   `.cmd` body where no Dart quoting applies. The script sits beside the
///   executable so `start` is handed a short, stable path.
Future<void> relaunchApplication() async {
  final executable = Platform.resolvedExecutable;
  final self = pid;
  final script = File(join(dirname(executable), 'flclash-relaunch.cmd'));
  await script.writeAsString(
    '@echo off\r\n'
    'set /a waits=0\r\n'
    ':wait\r\n'
    'tasklist /fi "PID eq $self" /nh 2>nul | find "$self" >nul\r\n'
    'if errorlevel 1 goto run\r\n'
    'set /a waits+=1\r\n'
    'if %waits% geq 60 goto run\r\n'
    'ping -n 2 127.0.0.1 >nul\r\n'
    'goto wait\r\n'
    ':run\r\n'
    'start "" "$executable"\r\n'
    'del "%~f0"\r\n',
  );
  await Process.start('cmd.exe', [
    '/c',
    'start',
    '/min',
    'cmd.exe',
    '/c',
    script.path,
  ], mode: ProcessStartMode.detached);
}
