import 'package:decimal/decimal.dart';

/// Format a Decimal with fixed [precision] digits (>= 8 by default), zero-padded.
String formatDecimal(Decimal value, {int precision = 8}) {
  if (precision < 0) precision = 0;
  return value.toStringAsFixed(precision);
}

/// Parse a decimal string and format with fixed [precision].
String formatDecimalString(String value, {int precision = 8}) {
  return formatDecimal(Decimal.parse(value), precision: precision);
}

/// Convert integer smallest units (e.g., 8 decimals) to display string without rounding.
/// [units] is the integer amount, [scale] is the number of decimal places the units represent.
String formatUnits(BigInt units, {int scale = 8, int precision = 8}) {
  if (precision < 0) precision = 0;
  final isNeg = units.isNegative;
  final abs = units.abs();
  final base = BigInt.from(10).pow(scale);
  final intPart = abs ~/ base;
  String frac = (abs % base).toString().padLeft(scale, '0');

  if (precision == 0) {
    return '${isNeg ? '-' : ''}$intPart';
  }
  if (scale >= precision) {
    frac = frac.substring(0, precision); // truncate extra digits, no rounding
  } else {
    frac = frac.padRight(precision, '0'); // extend with zeros
  }
  return '${isNeg ? '-' : ''}$intPart.$frac';
}
