import 'dart:math';

import 'package:intl/intl.dart';

import '../domain/app_defaults.dart';
import '../domain/models/record_period.dart';
import '../domain/models/smoking_record.dart';
import '../domain/models/user_settings.dart';

class CostStatsService {
  const CostStatsService._();

  static bool isConfigured(UserSettings settings) {
    return settings.packPrice > 0 && settings.cigarettesPerPack > 0;
  }

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

  static int normalizeCigarettesPerPack(int value) {
    return value.clamp(
      AppDefaults.minCigarettesPerPack,
      AppDefaults.maxCigarettesPerPack,
    );
  }

  static double computeUnitCost(UserSettings settings) {
    if (!isConfigured(settings)) {
      return 0;
    }
    final unit = settings.packPrice / settings.cigarettesPerPack;
    return _sanitizeAmount(unit);
  }

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

  static double computeSpendForRecords({
    required List<SmokingRecord> records,
    required UserSettings settings,
  }) {
    final count = records.fold(0, (sum, item) => sum + item.count);
    return computeSpendForCount(cigaretteCount: count, settings: settings);
  }

  static double computeLifetimeSpend({
    required List<SmokingRecord> allRecords,
    required UserSettings settings,
  }) {
    return computeSpendForRecords(records: allRecords, settings: settings);
  }

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
      RecordPeriod.week => 7,
      RecordPeriod.month => DateTime(now.year, now.month + 1, 0).day,
    };

    return _sanitizeAmount(periodSpend / max(1, divisor));
  }

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

  static double _sanitizeAmount(double value) {
    if (!value.isFinite || value.isNaN || value.isNegative) {
      return 0;
    }
    return value;
  }

  static int _decimalDigitsForCurrency(String currencyCode) {
    return switch (currencyCode.toUpperCase()) {
      'KRW' || 'JPY' => 0,
      _ => 2,
    };
  }
}
