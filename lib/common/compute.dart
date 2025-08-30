import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

import 'string.dart';
import 'utils.dart';

List<Group> computeSort({
  required List<Group> groups,
  required ProxiesSortType sortType,
  required DelayMap delayMap,
  required SelectedMap selectedMap,
  required String defaultTestUrl,
}) {
  return groups.map((group) {
    final proxies = group.all;
    final newProxies = switch (sortType) {
      ProxiesSortType.none => proxies,
      ProxiesSortType.delay => _sortOfDelay(
        groups: groups,
        proxies: proxies,
        delayMap: delayMap,
        selectedMap: selectedMap,
        testUrl: group.testUrl.getSafeValue(defaultTestUrl),
      ),
      ProxiesSortType.name => _sortOfName(proxies),
    };
    return group.copyWith(all: newProxies);
  }).toList();
}

int computeProxyDelay({
  required String proxyName,
  required String testUrl,
  required List<Group> groups,
  required SelectedMap selectedMap,
  required DelayMap delayMap,
}) {
  final state = computeRealSelectedProxyState(
    proxyName,
    groups: groups,
    selectedMap: selectedMap,
  );
  final currentDelayMap = delayMap[state.testUrl.getSafeValue(testUrl)] ?? {};
  final delay = currentDelayMap[state.proxyName];
  return delay ?? 0;
}

SelectedProxyState computeRealSelectedProxyState(
  String proxyName, {
  required List<Group> groups,
  required SelectedMap selectedMap,
}) {
  return _getRealSelectedProxyState(
    SelectedProxyState(proxyName: proxyName),
    groups: groups,
    selectedMap: selectedMap,
  );
}

SelectedProxyState _getRealSelectedProxyState(
  SelectedProxyState state, {
  required List<Group> groups,
  required SelectedMap selectedMap,
}) {
  if (state.proxyName.isEmpty) return state;
  final index = groups.indexWhere((element) => element.name == state.proxyName);
  if (index == -1) return state;
  final group = groups[index];
  final currentSelectedName = group.getCurrentSelectedName(
    selectedMap[state.proxyName] ?? '',
  );
  if (currentSelectedName.isEmpty) {
    return state;
  }
  return _getRealSelectedProxyState(
    state.copyWith(proxyName: currentSelectedName, testUrl: group.testUrl),
    groups: groups,
    selectedMap: selectedMap,
  );
}

List<Proxy> _sortOfDelay({
  required List<Group> groups,
  required List<Proxy> proxies,
  required DelayMap delayMap,
  required SelectedMap selectedMap,
  required String testUrl,
}) {
  return List.from(proxies)..sort((a, b) {
    final aDelay = computeProxyDelay(
      proxyName: a.name,
      testUrl: testUrl,
      groups: groups,
      selectedMap: selectedMap,
      delayMap: delayMap,
    );
    final bDelay = computeProxyDelay(
      proxyName: b.name,
      testUrl: testUrl,
      groups: groups,
      selectedMap: selectedMap,
      delayMap: delayMap,
    );
    int getPriority(int delay) {
      if (delay > 0) return 0;
      if (delay == 0) return 1;
      return 2;
    }

    final aPriority = getPriority(aDelay);
    final bPriority = getPriority(bDelay);

    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }
    return aDelay.compareTo(bDelay);
  });
}

List<Proxy> _sortOfName(List<Proxy> proxies) {
  return List.of(proxies)..sort(
    (a, b) =>
        utils.sortByChar(utils.getPinyin(a.name), utils.getPinyin(b.name)),
  );
}
