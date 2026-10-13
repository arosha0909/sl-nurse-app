import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'pastel_card.dart';

/// Loads data with [load], shows a skeleton while waiting and a retry card on error,
/// and reloads automatically whenever [DataSync] reports a change.
///
/// Keeps showing the previous data during a background reload, so pull-to-refresh
/// and post-save refreshes don't flash the skeleton.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.skeleton,
    this.reloadKey,
  });

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;
  final Widget? skeleton;

  /// Changing this (e.g. the selected month) triggers a reload.
  final Object? reloadKey;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = false;
  DataSync? _sync;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = AppScope.of(context).sync;
    if (!identical(sync, _sync)) {
      _sync?.removeListener(_reload);
      _sync = sync..addListener(_reload);
      if (_data == null) _reload();
    }
  }

  @override
  void didUpdateWidget(AsyncView<T> old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey) {
      _data = null; // different subject: show the skeleton, not stale data
      _reload();
    }
  }

  @override
  void dispose() {
    _sync?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted || generation != _generation) {
        return; // a newer load superseded this one
      }
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) return widget.builder(context, data, _reload);
    if (_error != null) return ErrorCard(message: '$_error', onRetry: _reload);
    if (_loading || data == null) {
      return widget.skeleton ?? const SkeletonList();
    }
    return const SizedBox.shrink();
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: PastelCard(
        color: AppColors.peach,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const IconBadge(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.peachDeep,
              size: 56,
            ),
            const SizedBox(height: 14),
            Text('Couldn\'t load this', style: text.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: text.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft pulsing placeholder blocks shaped like the screen's cards.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.heights = const [56, 220, 150, 120]});

  final List<double> heights;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: SafeArea(
        child: ResponsiveContent(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Column(
                children: [
                  for (final h in widget.heights) ...[
                    Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          AppColors.lavender,
                          AppColors.surfaceMuted,
                          _c.value,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Snackbar helpers so error/success feedback looks the same everywhere.
extension Feedback on BuildContext {
  void showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  /// Runs [task], showing [success] or the error message. Returns true on success.
  Future<bool> runWithFeedback(
    Future<void> Function() task, {
    String? success,
  }) async {
    try {
      await task();
      if (mounted && success != null) showMessage(success);
      return true;
    } catch (e) {
      if (mounted) showMessage('$e');
      return false;
    }
  }
}
