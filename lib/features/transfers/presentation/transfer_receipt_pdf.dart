import 'dart:typed_data';

import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class _Labels {
  _Labels(this.t);
  final String Function(String, [Map<String, Object?>?]) t;

  String get title => _safe('transfer_receipt_title', 'Havale Makbuzu');
  String get senderTitle => _safe('transfer_field_sender', 'Gönderen');
  String get receiverTitle => _safe('transfer_field_receiver', 'Alıcı');
  String get receiverPhone => _safe('transfer_field_receiver_phone', 'Alıcı telefon');
  String get receiverState => _safe('transfer_field_receiver_state', 'Eyalet');
  String get amount => _safe('transfer_field_amount_usd', 'Tutar (USD)');
  String get amountTl => _safe('transfer_field_amount_tl', 'Tutar (TL)');
  String get rate => _safe('transfer_field_exchange_rate', 'Kur');
  String get commission => _safe('transfer_field_commission', 'Komisyon');
  String get netCommission => _safe('transfer_field_net_commission', 'Net komisyon');
  String get totalUsd => _safe('transfer_field_total_usd', 'Toplam (USD)');
  String get totalTl => _safe('transfer_field_total_tl', 'Toplam (TL)');
  String get cashUsd => _safe('transfer_payment_cash_usd', 'Nakit USD');
  String get cashTl => _safe('transfer_payment_cash_tl', 'Nakit TL');
  String get bankUsd => _safe('transfer_payment_bank_usd', 'Banka USD');
  String get bankTl => _safe('transfer_payment_bank_tl', 'Banka TL');
  String get transferNo => _safe('transfer_field_number', 'Havale no');
  String get date => _safe('transfer_field_date', 'Tarih');
  String get agent => _safe('transfer_field_agent', 'Acente');
  String get distributor => _safe('transfer_field_distributor', 'Dağıtıcı');
  String get status => _safe('transfer_field_status', 'Durum');
  String get note => _safe('transfer_receipt_footer', 'Bu makbuz elektronik olarak oluşturulmuştur.');

  String _safe(String key, String fallback) {
    final v = t(key);
    return v == key ? fallback : v;
  }
}

Future<Uint8List> buildTransferReceiptPdf({
  required TransferDto transfer,
  required AppLocale locale,
  required String Function(String, [Map<String, Object?>?]) t,
}) async {
  final doc = pw.Document();
  final labels = _Labels(t);
  final money = NumberFormat.currency(
    locale: locale.numberFormatTag,
    symbol: r'$',
    decimalDigits: 2,
  );
  final moneyTl = NumberFormat.currency(
    locale: locale.numberFormatTag,
    symbol: '₺',
    decimalDigits: 2,
  );
  final date = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag).format(transfer.createdAt.toLocal());

  pw.Widget row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  pw.Widget section(String title, List<pw.Widget> children) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
            pw.SizedBox(height: 6),
            ...children,
          ],
        ),
      );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('HANPAY',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                  pw.SizedBox(height: 4),
                  pw.Text(labels.title, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${labels.transferNo}:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text(transfer.transferNumber, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('${labels.date}: $date', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          section(labels.senderTitle, [
            row(labels.senderTitle, transfer.senderFullName),
          ]),
          section(labels.receiverTitle, [
            row(labels.receiverTitle, transfer.receiverFullName),
            row(labels.receiverPhone, transfer.receiverPhone),
            row(labels.receiverState, transfer.state),
            if (transfer.receiverAddress.isNotEmpty)
              row('Adres', transfer.receiverAddress),
          ]),
          section('${labels.amount} / ${labels.commission}', [
            row(labels.amount, money.format(transfer.amount)),
            row(labels.rate, transfer.exchangeRate.toStringAsFixed(4)),
            row(labels.commission, money.format(transfer.commission)),
            if (transfer.commissionDiscountUsd > 0)
              row('İndirim', money.format(transfer.commissionDiscountUsd)),
            row(labels.netCommission, money.format(transfer.netCommissionUsd)),
            row(labels.totalUsd, money.format(transfer.totalAmount)),
            row(labels.totalTl, moneyTl.format(transfer.totalAmountTl)),
          ]),
          section('Ödeme', [
            if (transfer.cashUsdAmount > 0) row(labels.cashUsd, money.format(transfer.cashUsdAmount)),
            if (transfer.cashTlAmount > 0) row(labels.cashTl, moneyTl.format(transfer.cashTlAmount)),
            if (transfer.bankUsdAmount > 0) row(labels.bankUsd, money.format(transfer.bankUsdAmount)),
            if (transfer.bankTlAmount > 0) row(labels.bankTl, moneyTl.format(transfer.bankTlAmount)),
          ]),
          section('Bilgi', [
            row(labels.agent, transfer.agentName),
            if (transfer.distributorName.isNotEmpty)
              row(labels.distributor, transfer.distributorName),
            row(labels.status, transfer.status.apiValue),
          ]),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.Text(labels.note,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    ),
  );

  return doc.save();
}
