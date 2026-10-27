import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'common.dart';

extension PackageInfoExtension on PackageInfo {
  String get ua => [
    '$appName/v$version',
    'clash-verge',
    'Platform/${Platform.operatingSystem}',
  ].join(' ');
}

/// Compares two version strings: positive when [version1] is newer, negative when older, zero when equal.
///
/// Tolerates the shapes release tags actually come in: a leading `v`, prerelease suffixes like `0.9.3-pre.1` (a prerelease ranks below its own release, per SemVer) and `+build` metadata.
/// Unparsable pieces degrade to a stable comparison instead of throwing, because both sides come from remote tags.
int compareVersions(String version1, String version2) {
  final parsed1 = _parseVersion(version1);
  final parsed2 = _parseVersion(version2);
  final core = _compareCore(parsed1.core, parsed2.core);
  if (core != 0) return core;
  final prerelease = _comparePrerelease(
    parsed1.prerelease,
    parsed2.prerelease,
  );
  if (prerelease != 0) return prerelease;
  return _compareBuild(parsed1.build, parsed2.build);
}

({List<String> core, String? prerelease, String? build}) _parseVersion(
  String version,
) {
  var value = version.trim();
  if (value.startsWith('v') || value.startsWith('V')) {
    value = value.substring(1);
  }
  String? build;
  final buildIndex = value.indexOf('+');
  if (buildIndex >= 0) {
    build = value.substring(buildIndex + 1);
    value = value.substring(0, buildIndex);
  }
  String? prerelease;
  final prereleaseIndex = value.indexOf('-');
  if (prereleaseIndex >= 0) {
    prerelease = value.substring(prereleaseIndex + 1);
    value = value.substring(0, prereleaseIndex);
  }
  return (core: value.split('.'), prerelease: prerelease, build: build);
}

int _compareCore(List<String> parts1, List<String> parts2) {
  final length = parts1.length > parts2.length ? parts1.length : parts2.length;
  for (var index = 0; index < length; index++) {
    final value1 = index < parts1.length ? parts1[index] : '0';
    final value2 = index < parts2.length ? parts2[index] : '0';
    final number1 = int.tryParse(value1);
    final number2 = int.tryParse(value2);
    final result = number1 != null && number2 != null
        ? number1.compareTo(number2)
        : value1.compareTo(value2);
    if (result != 0) return result;
  }
  return 0;
}

int _comparePrerelease(String? prerelease1, String? prerelease2) {
  if (prerelease1 == null && prerelease2 == null) return 0;
  if (prerelease1 == null) return 1;
  if (prerelease2 == null) return -1;
  final parts1 = prerelease1.split('.');
  final parts2 = prerelease2.split('.');
  for (var index = 0; index < parts1.length || index < parts2.length; index++) {
    if (index >= parts1.length) return -1;
    if (index >= parts2.length) return 1;
    final value1 = parts1[index];
    final value2 = parts2[index];
    final number1 = int.tryParse(value1);
    final number2 = int.tryParse(value2);
    if (number1 != null && number2 != null) {
      final result = number1.compareTo(number2);
      if (result != 0) return result;
    } else if (number1 != null) {
      return -1;
    } else if (number2 != null) {
      return 1;
    } else {
      final result = value1.compareTo(value2);
      if (result != 0) return result;
    }
  }
  return 0;
}

int _compareBuild(String? build1, String? build2) {
  final value1 = build1 ?? '0';
  final value2 = build2 ?? '0';
  final number1 = int.tryParse(value1);
  final number2 = int.tryParse(value2);
  if (number1 != null && number2 != null) {
    return number1.compareTo(number2);
  }
  return value1.compareTo(value2);
}

const releaseNotesBeginMarker = '<!-- flclash:changelog:begin -->';
const releaseNotesEndMarker = '<!-- flclash:changelog:end -->';

List<String> parseReleaseBody(String? body) {
  if (body == null) return [];
  final regex = RegExp(r'^[ \t]*-[ \t]+(.*)$', multiLine: true);
  return regex
      .allMatches(scopeReleaseNotes(body))
      .map((match) => match.group(1)?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String scopeReleaseNotes(String body) {
  final begin = body.indexOf(releaseNotesBeginMarker);
  if (begin < 0) return body;
  final start = begin + releaseNotesBeginMarker.length;
  final end = body.indexOf(releaseNotesEndMarker, start);
  return end < 0 ? body.substring(start) : body.substring(start, end);
}
