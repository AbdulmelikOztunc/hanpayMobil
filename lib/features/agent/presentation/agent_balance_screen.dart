import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/utils/balance_ledger_export.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/balance_ledger_body.dart';
import 'package:intl/intl.dart';

class AgentBalanceFilters {
  const AgentBalanceFilters({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

List<({int year, int month})> _monthsInRange(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month);
  final end = DateTime(to.year, to.month);
  final out = <({int year, int month})>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    out.add((year: cursor.year, month: cursor.month));
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return out;
}

final agentBalanceProvider = FutureProvider.autoDispose.family<AgentBalanceSummary, AgentBalanceFilters>(
  (ref, filters) async {
    final repo = ref.watch(agentRepositoryProvider);
    final months = _monthsInRange(filters.from, filters.to);
    if (months.isEmpty) {
      final now = DateTime.now();
      return repo.getBalance(year: now.year, month: now.month);
    }

    final chunks = await Future.wait(
      months.map((m) => repo.getBalance(year: m.year, month: m.month)),
    );

    final allDeposits = <BalanceDepositItem>[];
    final allTransfers = <BalanceTransferItem>[];
    for (final chunk in chunks) {
      allDeposits.addAll(chunk.deposits);
      allTransfers.addAll(chunk.transfers);
    }

    final fromDay = DateTime(filters.from.year, filters.from.month, filters.from.day);
    final toDay = DateTime(filters.to.year, filters.to.month, filters.to.day, 23, 59, 59);

    bool inRange(DateTime d) => !d.isBefore(fromDay) && !d.isAfter(toDay);

    final deposits = allDeposits.where((d) => inRange(d.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final transfers = allTransfers.where((t) => inRange(t.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final latest = chunks.last;
    return AgentBalanceSummary(
      currentBalance: latest.currentBalance,
      creditLimit: latest.creditLimit,
      currency: latest.currency,
      openingBalance: chunks.first.openingBalance,
      deposits: deposits,
      transfers: transfers,
    );
  },
);

class AgentBalanceScreen extends ConsumerStatefulWidget {
  const AgentBalanceScreen({super.key});

  @override
  ConsumerState<AgentBalanceScreen> createState() => _AgentBalanceScreenState();
}

class _AgentBalanceScreenState extends ConsumerState<AgentBalanceScreen> {
  late DateTime _from;
  late DateTime _to;
  String _preset = 'month';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
  }

  AgentBalanceFilters get _filters => AgentBalanceFilters(from: _from, to: _to);

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range != null) {
      setState(() {
        _preset = 'custom';
        _from = range.start;
        _to = range.end;
      });
    }
  }

  void _setPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _preset = preset;
      switch (preset) {
        case 'today':
          _from = DateTime(now.year, now.month, now.day);
          _to = now;
        case 'month':
          _from = DateTime(now.year, now.month, 1);
          _to = now;
      }
    });
  }

  Future<void> _export(AgentBalanceSummary data) async {
    final rows = <BalanceLedgerExportRow>[
      ...data.deposits.map(
        (d) => BalanceLedgerExportRow(
          date: d.date,
          title: d.description.isEmpty ? 'Bakiye yüklemesi' : d.description,
          subtitle: d.performedByName,
          amount: d.amount,
          isCredit: true,
        ),
      ),
      ...data.transfers.map(
        (t) => BalanceLedgerExportRow(
          date: t.date,
          title: '#${t.transferNumber}',
          subtitle: t.counterpartyName ?? '',
          amount: t.totalAmount,
          isCredit: false,
        ),
      ),
    ]..sort((a, b) => (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)));

    await shareBalanceLedgerCsv(
      filenamePrefix: 'agent-bakiye',
      openingBalance: data.openingBalance,
      closingBalance: data.currentBalance,
      rows: rows,
      from: _from,
      to: _to,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final async = ref.watch(agentBalanceProvider(filters));
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Bugün')),
                  ButtonSegment(value: 'month', label: Text('Bu ay')),
                ],
                selected: {_preset},
                onSelectionChanged: (v) => _setPreset(v.first),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${dateFmt.format(_from)} - ${dateFmt.format(_to)}'),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) =>
                ErrorView(message: e.toString(), onRetry: () => ref.invalidate(agentBalanceProvider(filters))),
            data: (data) => Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'CSV indir',
                    onPressed: () => _export(data),
                    icon: const Icon(Icons.download),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(agentBalanceProvider(filters)),
                    child: BalanceLedgerScreenBody(
                      currentBalance: data.currentBalance,
                      openingBalance: data.openingBalance,
                      currency: data.currency,
                      creditLimit: data.creditLimit,
                      deposits: data.deposits
                          .map((d) => BalanceLedgerDeposit(
                                date: d.date,
                                amount: d.amount,
                                description: d.description,
                                performedByName: d.performedByName,
                              ))
                          .toList(),
                      transfers: data.transfers
                          .map((t) => BalanceLedgerTransfer(
                                transferNumber: t.transferNumber,
                                totalAmount: t.totalAmount,
                                date: t.date,
                                counterpartyName: t.counterpartyName,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
