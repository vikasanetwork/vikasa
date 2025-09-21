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

/// Convert integer smallest units (e.g., 8 decimals) to display string.
/// [units] is the integer amount, [scale] is the number of decimal places the units represent.
String formatUnits(BigInt units, {int scale = 8, int precision = 8}) {
  final d = Decimal.fromBigInt(units) / Decimal.tenPow(scale);
  return formatDecimal(d, precision: precision);
}
