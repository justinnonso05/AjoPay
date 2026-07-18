/// Formats a numeric amount with thousands separators, e.g. 12345.5 -> "12,345.50".
String formatAmount(double amount) {
  final isWhole = amount == amount.roundToDouble();
  final value = isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  final parts = value.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  return parts.length > 1 ? '${buffer.toString()}.${parts[1]}' : buffer.toString();
}
