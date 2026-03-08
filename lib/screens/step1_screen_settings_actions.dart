part of 'step1_screen.dart';

extension _Step1ScreenSettingsActions on _Step1ScreenState {
  /// Collects and stores the pack price used for cost calculations.
  Future<void> _pickPackPrice(BuildContext context, AppState state) async {
    final initialText = state.settings.packPrice <= 0
        ? ''
        : state.settings.packPrice.toStringAsFixed(
            state.settings.packPrice % 1 == 0 ? 0 : 2,
          );
    final raw = await _showCostValueInputSheet(
      context: context,
      title: '갑당 가격',
      hintText: '예: 4500',
      helperText:
          '${AppDefaults.minPackPrice.toInt()} ~ ${AppDefaults.maxPackPrice.toInt()} 범위',
      initialText: initialText,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: (value) {
        final parsed = double.tryParse(value);
        if (parsed == null) {
          return '숫자만 입력해주세요.';
        }
        if (parsed <= 0) {
          return '0보다 큰 값을 입력해주세요.';
        }
        if (parsed < AppDefaults.minPackPrice ||
            parsed > AppDefaults.maxPackPrice) {
          return '허용 범위를 벗어났습니다.';
        }
        return null;
      },
    );

    if (raw == null || !context.mounted) {
      return;
    }
    final parsed = double.parse(raw);
    await ref.read(appControllerProvider.notifier).setPackPrice(parsed);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('갑당 가격을 저장했어요.');
  }

  /// Collects and stores the cigarette count per pack for cost calculations.
  Future<void> _pickCigarettesPerPack(
    BuildContext context,
    AppState state,
  ) async {
    final raw = await _showCostValueInputSheet(
      context: context,
      title: '한 갑 개비 수',
      hintText: '예: 20',
      helperText:
          '${AppDefaults.minCigarettesPerPack} ~ ${AppDefaults.maxCigarettesPerPack} 범위',
      initialText: state.settings.cigarettesPerPack.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final parsed = int.tryParse(value);
        if (parsed == null) {
          return '정수를 입력해주세요.';
        }
        if (parsed <= 0) {
          return '0보다 큰 값을 입력해주세요.';
        }
        if (parsed < AppDefaults.minCigarettesPerPack ||
            parsed > AppDefaults.maxCigarettesPerPack) {
          return '허용 범위를 벗어났습니다.';
        }
        return null;
      },
    );

    if (raw == null || !context.mounted) {
      return;
    }
    final parsed = int.parse(raw);
    await ref.read(appControllerProvider.notifier).setCigarettesPerPack(parsed);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('한 갑 개비 수를 저장했어요.');
  }

  /// Lets the user choose the currency code used for cost formatting.
  Future<void> _pickCurrencyCode(BuildContext context, AppState state) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: SmokeUiTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ui = SmokeUiTheme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '통화',
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...AppDefaults.currencyCodeOptions.map((code) {
                final symbol = CostStatsService.resolveCurrencySymbol(code);
                final selected = state.settings.currencyCode == code;
                return ListTile(
                  dense: true,
                  title: Text('$code ($symbol)'),
                  trailing: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: SmokeUiPalette.accentDark,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(code),
                );
              }),
            ],
          ),
        );
      },
    );

    if (picked == null || picked == state.settings.currencyCode || !mounted) {
      return;
    }
    await ref.read(appControllerProvider.notifier).setCurrencyCode(picked);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('통화를 변경했어요.');
  }

  /// Opens a reusable numeric input sheet for cost-related settings.
  Future<String?> _showCostValueInputSheet({
    required BuildContext context,
    required String title,
    required String hintText,
    required String helperText,
    required String initialText,
    required List<TextInputFormatter> inputFormatters,
    required String? Function(String value) validator,
  }) async {
    final controller = TextEditingController(text: initialText);
    String? errorText;
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: SmokeUiTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ui = SmokeUiTheme.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('cost_input_field'),
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: inputFormatters,
                      decoration: InputDecoration(
                        hintText: hintText,
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: SmokeUiPalette.accentDark,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setModalState(() {
                            errorText = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      key: const Key('cost_apply_button'),
                      text: '적용',
                      onTap: () {
                        final raw = controller.text.trim().replaceAll(',', '');
                        final validationMessage = validator(raw);
                        if (validationMessage != null) {
                          setModalState(() {
                            errorText = validationMessage;
                          });
                          return;
                        }
                        Navigator.of(context).pop(raw);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: ui.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    return value;
  }

  /// Confirms destructive reset intent before clearing all local data.
  Future<void> _confirmReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text('기록과 설정을 모두 초기화할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }
    await ref.read(appControllerProvider.notifier).resetAllData();
    if (!mounted) {
      return;
    }
    await HapticFeedback.mediumImpact();
    _showFeedback('기록과 설정을 초기화했어요.');
  }

  /// Opens the bundled privacy policy document in a dedicated reader screen.
  Future<void> _openPrivacyPolicy(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }
}
