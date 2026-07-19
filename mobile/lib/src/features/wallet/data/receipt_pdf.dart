import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import 'wallet_models.dart';

const _brandDark = PdfColor.fromInt(0xFF1D3108);
const _brandAccent = PdfColor.fromInt(0xFF5BA72D);
const _muted = PdfColor.fromInt(0xFF8A9182);

bool _isCreditType(String type) {
  final t = type.toLowerCase().replaceAll('_', '').replaceAll('-', '');
  const creditKeywords = ['deposit', 'topup', 'payout', 'refund', 'credit', 'received', 'reversal'];
  const debitKeywords = ['withdraw', 'contribution', 'debit', 'payment'];
  if (debitKeywords.any(t.contains)) return false;
  return creditKeywords.any(t.contains);
}

String _friendlyType(String type) {
  final words = type.replaceAll('_', ' ').split(' ');
  return words.map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
}

/// Renders a transaction receipt as a one-page PDF and opens the native
/// share/save sheet — entirely client-side, no backend call involved.
Future<void> shareReceiptPdf(TransactionReceipt receipt) async {
  final doc = pw.Document();
  final isCredit = _isCreditType(receipt.type);

  final rows = <List<String>>[
    ['Type', _friendlyType(receipt.type)],
    ['Date', '${formatShortDate(receipt.date)} · ${formatTime(receipt.date)}'],
    if (receipt.senderName != null) ['From', receipt.senderName!],
    if (receipt.recipientName != null) ['To', receipt.recipientName!],
    if (receipt.narration != null && receipt.narration!.isNotEmpty) ['Narration', receipt.narration!],
    if (receipt.reference != null && receipt.reference!.isNotEmpty) ['Reference', receipt.reference!],
    ['Transaction ID', receipt.transactionId],
  ];

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('AjoPay', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _brandDark)),
                pw.Text('Transaction Receipt', style: const pw.TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    '${isCredit ? '+' : '-'}₦${formatAmount(receipt.amount.abs())}',
                    style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: isCredit ? _brandAccent : _brandDark),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(receipt.status.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _brandAccent)),
                ],
              ),
            ),
            pw.SizedBox(height: 32),
            for (final row in rows) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(row[0], style: const pw.TextStyle(fontSize: 11, color: _muted)),
                  pw.SizedBox(
                    width: 300,
                    child: pw.Text(row[1], textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _brandDark)),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey100),
              pw.SizedBox(height: 12),
            ],
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Generated ${DateTime.now().toString().split('.').first} • AjoPay',
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ),
          ],
        );
      },
    ),
  );

  final idPrefix = receipt.transactionId.substring(0, receipt.transactionId.length.clamp(0, 8));
  await Printing.sharePdf(bytes: await doc.save(), filename: 'ajopay-receipt-$idPrefix.pdf');
}
