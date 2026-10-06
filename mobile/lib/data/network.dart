import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  offline,
  wifi,
  mobile;

  bool get isOffline => this == NetworkStatus.offline;
}

/// Source of connectivity. Replaced by a fake in tests.
abstract class ConnectivitySource {
  Future<NetworkStatus> current();
  Stream<NetworkStatus> changes();
}

class PlatformConnectivity implements ConnectivitySource {
  static NetworkStatus _map(List<ConnectivityResult> r) {
    if (r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.wifi;
    }
    if (r.contains(ConnectivityResult.mobile)) return NetworkStatus.mobile;
    if (r.isEmpty || r.every((e) => e == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus
        .wifi; // vpn, bluetooth, other: treat as unmetered online
  }

  @override
  Future<NetworkStatus> current() async =>
      _map(await Connectivity().checkConnectivity());

  @override
  Stream<NetworkStatus> changes() =>
      Connectivity().onConnectivityChanged.map(_map);
}

final connectivitySourceProvider = Provider<ConnectivitySource>(
  (ref) => PlatformConnectivity(),
);

/// Current network status; optimistic `wifi` until the first reading arrives.
class NetworkController extends Notifier<NetworkStatus> {
  StreamSubscription<NetworkStatus>? _sub;

  @override
  NetworkStatus build() {
    final src = ref.watch(connectivitySourceProvider);
    _sub = src.changes().listen((s) => state = s);
    ref.onDispose(() => _sub?.cancel());
    src.current().then((s) => state = s);
    return NetworkStatus.wifi;
  }

  Future<void> recheck() async =>
      state = await ref.read(connectivitySourceProvider).current();
}

final networkStatusProvider =
    NotifierProvider<NetworkController, NetworkStatus>(NetworkController.new);
