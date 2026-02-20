import 'dart:math';

import 'package:intl/intl.dart';

import '../domain/app_defaults.dart';
import '../domain/models/record_period.dart';
import '../domain/models/smoking_record.dart';
import '../domain/models/user_settings.dart';

class CostStatsService {
  const CostStatsService._();

  /// Returns whether cost tracking inputs are valid for spend computation.
  static bool isConfigured(UserSettings settings) {
    return settings.packPrice > 0 && settings.cigarettesPerPack > 0;
  }

  /// Normalizes pack price to policy range.
  static double normalizePackPrice(double value) {
    if (!value.isFinite || value.isNaN) {
      return 0;
    }
    final sanitized = max(0, value);
    if (sanitized == 0) {
      return 0;
    }
    return sanitized
        .clamp(AppDefaults.minPackPrice, AppDefaults.maxPackPrice)
        .toDouble();
  }

  /// Normalizes cigarettes per pack to policy range.
  static int normalizeCigarettesPerPack(int value) {
    return value.clamp(
      AppDefaults.minCigarettesPerPack,
      AppDefaults.maxCigarettesPerPack,
    );
  }

  /// Computes cost of one cigarette from current settings.
  static double computeUnitCost(UserSettings settings) {
    if (!isConfigured(settings)) {
      return 0;
    }
    final unit = settings.packPrice / settings.cigarettesPerPack;
    return _sanitizeAmount(unit);
  }

  /// Computes spend for a plain cigarette count.
  static double computeSpendForCount({
    required int cigaretteCount,
    required UserSettings settings,
  }) {
    if (cigaretteCount <= 0) {
      return 0;
    }
    final spend = computeUnitCost(settings) * cigaretteCount;
    return _sanitizeAmount(spend);
  }

  /// Computes spend from a list of smoking records.
  static double computeSpendForRecords({
    required List<SmokingRecord> records,
    required UserSettings settings,
  }) {
    final count = records.fold(0, (sum, item) => sum + item.count);
    return computeSpendForCount(cigaretteCount: count, settings: settings);
  }

  /// Computes lifetime spend over all records.
  static double computeLifetimeSpend({
    required List<SmokingRecord> allRecords,
    required UserSettings settings,
  }) {
    return computeSpendForRecords(records: allRecords, settings: settings);
  }

  /// Computes average daily spend for selected period policy.
  static double computeAverageDailySpend({
    required RecordPeriod period,
    required DateTime now,
    required List<SmokingRecord> periodRecords,
    required UserSettings settings,
  }) {
    final periodSpend = computeSpendForRecords(
      records: periodRecords,
      settings: settings,
    );
    if (periodSpend <= 0) {
      return 0;
    }

    // Policy:
    // - today: same as period spend
    // - week: divide by 7
    // - month: divide by total days in current month (calendar-based)
    final divisor = switch (period) {
      RecordPeriod.today => 1,
      RecordPeriod.week => AppDefaults.daysPerWeek,
      RecordPeriod.month => DateTime(now.year, now.month + 1, 0).day,
    };

    return _sanitizeAmount(periodSpend / max(1, divisor));
  }

  /// Formats amount as localized currency string with policy fallback.
  static String formatCurrency(double amount, UserSettings settings) {
    final safeAmount = _sanitizeAmount(amount);
    final code = settings.currencyCode.isEmpty
        ? AppDefaults.defaultCurrencyCode
        : settings.currencyCode.toUpperCase();
    final symbol = settings.currencySymbol.isNotEmpty
        ? settings.currencySymbol
        : resolveCurrencySymbol(code);
    final decimals = _decimalDigitsForCurrency(code);

    try {
      final formatter = NumberFormat.currency(
        name: code,
        symbol: symbol,
        decimalDigits: decimals,
      );
      return formatter.format(safeAmount);
    } catch (_) {
      return '$code ${safeAmount.toStringAsFixed(decimals)}';
    }
  }

  /// Resolves display symbol from a currency code with deterministic fallback.
  static String resolveCurrencySymbol(String currencyCode) {
    final code = currencyCode.toUpperCase();
    try {
      final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
      if (symbol.isNotEmpty) {
        return symbol;
      }
    } catch (_) {
      // Keep deterministic fallback below.
    }

    return switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'JPY' => '¥',
      'KRW' => '₩',
      _ => code,
    };
  }

  /// Sanitizes invalid numeric values into safe non-negative amount.
  static double _sanitizeAmount(double value) {
    if (!value.isFinite || value.isNaN || value.isNegative) {
      return 0;
    }
    return value;
  }

  /// Returns display decimal digits by currency policy.
  static int _decimalDigitsForCurrency(String currencyCode) {
    return switch (currencyCode.toUpperCase()) {
      'KRW' || 'JPY' => 0,
      _ => 2,
    };
  }
}
