import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/home_widget_snapshot.dart';
import '../presentation/home/home_widget_presenter.dart';
import '../presentation/state/app_providers.dart';

/// Keeps native home screen widgets synchronized with the latest app snapshot.
class HomeWidgetSyncScope extends ConsumerStatefulWidget {
  /// Wraps the app subtree that should trigger widget synchronization.
  const HomeWidgetSyncScope({required this.child, super.key});

  /// Child subtree that remains visually unchanged by this synchronization layer.
  final Widget child;

  @override
  ConsumerState<HomeWidgetSyncScope> createState() =>
      _HomeWidgetSyncScopeState();
}

class _HomeWidgetSyncScopeState extends ConsumerState<HomeWidgetSyncScope> {
  ProviderSubscription<HomeWidgetSnapshot?>? _subscription;
  bool _didStart = false;

  /// Starts widget synchronization after the first frame to avoid init races.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startSync());
    });
  }

  /// Subscribes to the derived widget payload and performs initial sync.
  Future<void> _startSync() async {
    if (_didStart || !mounted) {
      return;
    }
    _didStart = true;

    final service = ref.read(homeScreenWidgetServiceProvider);
    await service.initialize();

    final initialSnapshot = HomeWidgetPresenter.buildIfReady(
      ref.read(appControllerProvider),
    );
    if (initialSnapshot != null) {
      await service.syncSnapshot(initialSnapshot);
    }

    _subscription = ref.listenManual(
      appControllerProvider.select(HomeWidgetPresenter.buildIfReady),
      (_, next) {
        if (next == null) {
          return;
        }
        unawaited(service.syncSnapshot(next));
      },
    );
  }

  /// Releases the provider subscription used for widget synchronization.
  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  /// Returns the original child subtree without altering visual structure.
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
