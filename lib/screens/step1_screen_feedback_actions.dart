part of 'step1_screen.dart';

extension _Step1ScreenFeedbackActions on _Step1ScreenState {
  /// Shows a lightweight floating feedback message for completed actions.
  void _showFeedback(
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (!mounted) {
      return;
    }
    final ui = SmokeUiTheme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor ?? ui.surfaceAlt,
        content: Text(
          message,
          style: TextStyle(
            color: foregroundColor ?? ui.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Runs a settings action and provides consistent tactile and visual feedback.
  Future<void> _runSettingAction(
    Future<void> Function() action,
    String message,
  ) async {
    await action();
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback(message);
  }

  /// Adds a smoking record and confirms the result to the user.
  Future<void> _handleAddRecord() async {
    await ref.read(appControllerProvider.notifier).addSmokingRecord();
    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    _showFeedback('흡연 기록을 남겼어요.');
  }

  /// Reverts the latest record when the history contains at least one entry.
  Future<void> _handleUndoRecord() async {
    final canUndo = ref.read(appControllerProvider).records.isNotEmpty;
    if (!canUndo) {
      return;
    }

    await ref.read(appControllerProvider.notifier).undoLastRecord();
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('방금 기록을 되돌렸어요.');
  }
}
