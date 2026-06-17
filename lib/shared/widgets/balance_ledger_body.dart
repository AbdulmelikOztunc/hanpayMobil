import 'package:flutter/material.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

class BalanceLedgerScreenBody extends StatelessWidget {
  const BalanceLedgerScreenBody({
    super.key,
    required this.currentBalance,
    required this.openingBalance,
    required this.currency,
    required this.deposits,
    required this.transfers,
    this.creditLimit,
  });

  final double currentBalance;
  final double openingBalance;
  final String currency;
  final double? creditLimit;
  final List<BalanceLedgerDeposit> deposits;
  final List<BalanceLedgerTransfer> transfers;

  @override
  Widget build(BuildContext context) {
    final money = formatUsd;
    final entries = <_LedgerEntry>[
      _LedgerEntry(
        title: 'Dönem açılış',
        subtitle: '',
        amount: openingBalance,
        isCredit: true,
      ),
      ...deposits.map(
        (d) => _LedgerEntry(
          title: d.description.isEmpty ? 'Bakiye yüklemesi' : d.description,
          subtitle: d.performedByName,
          amount: d.amount,
          isCredit: true,
          date: d.date,
        ),
      ),
      ...transfers.map(
        (t) => _LedgerEntry(
          title: '#${t.transferNumber}',
          subtitle: t.counterpartyName ?? '',
          amount: t.totalAmount,
          isCredit: false,
          date: t.date,
        ),
      ),
    ]..sort((a, b) => (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatCard(label: 'Güncel bakiye', value: money(currentBalance), icon: Icons.wallet),
            StatCard(label: 'Dönem açılış', value: money(openingBalance), icon: Icons.history),
            if (creditLimit != null)
              StatCard(label: 'Kredi limiti', value: money(creditLimit!), icon: Icons.credit_score),
            StatCard(label: 'Para birimi', value: currency, icon: Icons.attach_money),
          ],
        ),
        const SizedBox(height: 20),
        Text('Hareketler', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (entries.length <= 1)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Bu dönemde hareket yok.')),
          )
        else
          ...entries.skip(1).map(
                (e) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: e.isCredit
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      child: Icon(
                        e.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: e.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                        size: 18,
                      ),
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      [if (e.subtitle.isNotEmpty) e.subtitle, if (e.date != null) _fmt(e.date!)].join(' · '),
                    ),
                    trailing: Text(
                      '${e.isCredit ? '+' : '-'}${money(e.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: e.isCredit ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class BalanceLedgerDeposit {
  const BalanceLedgerDeposit({
    required this.date,
    required this.amount,
    required this.description,
    required this.performedByName,
  });

  final DateTime date;
  final double amount;
  final String description;
  final String performedByName;
}

class BalanceLedgerTransfer {
  const BalanceLedgerTransfer({
    required this.transferNumber,
    required this.totalAmount,
    required this.date,
    this.counterpartyName,
  });

  final String transferNumber;
  final double totalAmount;
  final DateTime date;
  final String? counterpartyName;
}

class _LedgerEntry {
  const _LedgerEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    this.date,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final DateTime? date;
}
