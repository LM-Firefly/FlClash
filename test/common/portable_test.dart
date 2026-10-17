import 'dart:io';
import 'package:fl_clash/common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory systemSupport;

  setUp(() {
    root = Directory.systemTemp.createTempSync('portable_mode_root');
    systemSupport = Directory.systemTemp.createTempSync('portable_mode_sys');
    PortableMode.resolveRoot = () => root.path;
    PortableMode.resolveSystemSupport = () async => systemSupport;
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
    if (systemSupport.existsSync()) {
      systemSupport.deleteSync(recursive: true);
    }
  });

  test(
    'enable writes the marker and copies missing system data once',
    () async {
      File(
        join(systemSupport.path, 'shared_preferences.json'),
      ).writeAsStringSync('{"a":1}');
      Directory(
        join(systemSupport.path, 'profiles', '1'),
      ).createSync(recursive: true);
      File(
        join(systemSupport.path, 'profiles', '1', 'p.yaml'),
      ).writeAsStringSync('x: 1');
      File(join(systemSupport.path, 'FlClash.lock')).writeAsStringSync('lock');

      await portableMode.enable();

      expect(portableMode.enabled, isTrue);
      expect(portableMode.hasLocalData, isTrue);
      expect(
        File(
          join(root.path, 'data', 'clash', 'shared_preferences.json'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          join(root.path, 'data', 'clash', 'profiles', '1', 'p.yaml'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(join(root.path, 'data', 'clash', 'FlClash.lock')).existsSync(),
        isFalse,
        reason: 'the single-instance lock is not data to carry over',
      );
    },
  );

  test('enable keeps Flutter runtime files in data untouched', () async {
    // The Windows package ships its own data folder beside the exe.
    Directory(
      join(root.path, 'data', 'flutter_assets'),
    ).createSync(recursive: true);
    File(join(root.path, 'data', 'icudtl.dat')).writeAsStringSync('icu');
    File(
      join(systemSupport.path, 'shared_preferences.json'),
    ).writeAsStringSync('{"a":1}');

    await portableMode.enable();

    expect(
      File(join(root.path, 'data', 'icudtl.dat')).readAsStringSync(),
      'icu',
    );
    expect(
      Directory(join(root.path, 'data', 'flutter_assets')).existsSync(),
      isTrue,
    );
    expect(
      File(
        join(root.path, 'data', 'clash', 'shared_preferences.json'),
      ).existsSync(),
      isTrue,
    );
  });

  test('enable leaves an already populated portable directory alone', () async {
    final data = portableMode.dataDirectory..createSync(recursive: true);
    File(join(data.path, 'shared_preferences.json')).writeAsStringSync('keep');
    File(
      join(systemSupport.path, 'shared_preferences.json'),
    ).writeAsStringSync('system');

    await portableMode.enable();

    expect(
      File(join(data.path, 'shared_preferences.json')).readAsStringSync(),
      'keep',
    );
  });

  test(
    'disable removes the marker and leaves portable data in place',
    () async {
      File(
        join(systemSupport.path, 'shared_preferences.json'),
      ).writeAsStringSync('{}');
      await portableMode.enable();
      await portableMode.disable();

      expect(portableMode.enabled, isFalse);
      expect(portableMode.dataDirectory.existsSync(), isTrue);
      expect(portableMode.hasLocalData, isTrue);
    },
  );

  test('resolveSupportDirectory follows the marker', () async {
    File(
      join(systemSupport.path, 'shared_preferences.json'),
    ).writeAsStringSync('{}');

    await portableMode.enable();
    final resolved = await AppPath.resolveSupportDirectory();

    expect(resolved.path, portableMode.dataDirectory.path);
  });
}
