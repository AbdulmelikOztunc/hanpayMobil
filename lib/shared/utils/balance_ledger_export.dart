import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BalanceLedgerExportRow {
  const BalanceLedgerExportRow({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
  });

  final DateTime? date;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
}

Future<void> shareBalanceLedgerCsv({
  required String filenamePrefix,
  required double openingBalance,
  required double closingBalance,
  required List<BalanceLedgerExportRow> rows,
  DateTime? from,
  DateTime? to,
}) async {
  final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
  final range = from != null && to != null
      ? '${DateFormat('dd.MM.yyyy').format(from)} - ${DateFormat('dd.MM.yyyy').format(to)}'
      : '';
  final buffer = StringBuffer()
    ..writeln('Hesap detay listesi')
    ..writeln('Dönem,$range')
    ..writeln('Açılış,${openingBalance.toStringAsFixed(2)}')
    ..writeln('Kapanış,${closingBalance.toStringAsFixed(2)}')
    ..writeln('')
    ..writeln('Tarih,Açıklama,Karşı taraf,Tutar,Yön');

  for (final r in rows) {
    final date = r.date != null ? dateFmt.format(r.date!.toLocal()) : '';
    final dir = r.isCredit ? 'Giriş' : 'Çıkış';
    final amount = r.amount.toStringAsFixed(2);
    buffer.writeln('"$date","${_csv(r.title)}","${_csv(r.subtitle)}",$amount,$dir');
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filenamePrefix-${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(buffer.toString());
  await Share.shareXFiles([XFile(file.path)], text: 'Bakiye defteri');
}

String _csv(String value) => value.replaceAll('"', '""');
