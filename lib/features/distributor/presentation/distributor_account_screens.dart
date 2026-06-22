import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/distributor/data/distributor_repository.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/utils/balance_ledger_export.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/balance_ledger_body.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:intl/intl.dart';

class DistributorBalanceFilters {
  const DistributorBalanceFilters({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}

List<DateTime> _monthsInRange(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month);
  final end = DateTime(to.year, to.month);
  final out = <DateTime>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    out.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return out;
}

final distributorBalanceProvider =
    FutureProvider.autoDispose.family<DistributorBalanceSummary, DistributorBalanceFilters>((ref, filters) async {
  final repo = ref.watch(distributorRepositoryProvider);
  final months = _monthsInRange(filters.from, filters.to);
  if (months.isEmpty) {
    final now = DateTime.now();
    return repo.getBalance(year: now.year, month: now.month);
  }
  final chunks = await Future.wait(months.map((m) => repo.getBalance(year: m.year, month: m.month)));
  final fromDay = DateTime(filters.from.year, filters.from.month, filters.from.day);
  final toDay = DateTime(filters.to.year, filters.to.month, filters.to.day, 23, 59, 59);
  bool inRange(DateTime d) => !d.isBefore(fromDay) && !d.isAfter(toDay);

  final deposits = <BalanceDepositItem>[];
  final transfers = <BalanceTransferItem>[];
  for (final chunk in chunks) {
    deposits.addAll(chunk.deposits.where((d) => inRange(d.date)));
    transfers.addAll(chunk.transfers.where((t) => inRange(t.date)));
  }
  deposits.sort((a, b) => a.date.compareTo(b.date));
  transfers.sort((a, b) => a.date.compareTo(b.date));
  final latest = chunks.last;
  return DistributorBalanceSummary(
    currentBalance: latest.currentBalance,
    currency: latest.currency,
    openingBalance: chunks.first.openingBalance,
    deposits: deposits,
    transfers: transfers,
  );
});

class DistributorBalanceScreen extends ConsumerStatefulWidget {
  const DistributorBalanceScreen({super.key});

  @override
  ConsumerState<DistributorBalanceScreen> createState() => _DistributorBalanceScreenState();
}

class _DistributorBalanceScreenState extends ConsumerState<DistributorBalanceScreen> {
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

  DistributorBalanceFilters get _filters => DistributorBalanceFilters(from: _from, to: _to);

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

  Future<void> _export(DistributorBalanceSummary data) async {
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
      filenamePrefix: 'distributor-bakiye',
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
    final async = ref.watch(distributorBalanceProvider(filters));
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
                ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorBalanceProvider(filters))),
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
                    onRefresh: () async => ref.invalidate(distributorBalanceProvider(filters)),
                    child: BalanceLedgerScreenBody(
                      currentBalance: data.currentBalance,
                      openingBalance: data.openingBalance,
                      currency: data.currency,
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

class DistributorPrimFilters {
  const DistributorPrimFilters({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}

final distributorPrimsProvider =
    FutureProvider.autoDispose.family<List<DistributorPrimRow>, DistributorPrimFilters>((ref, filters) async {
  final repo = ref.watch(distributorRepositoryProvider);
  final months = _monthsInRange(filters.from, filters.to);
  if (months.isEmpty) {
    final now = DateTime.now();
    return repo.getMyPrims(year: now.year, month: now.month);
  }
  final chunks = await Future.wait(months.map((m) => repo.getMyPrims(year: m.year, month: m.month)));
  final fromDay = DateTime(filters.from.year, filters.from.month, filters.from.day);
  final toDay = DateTime(filters.to.year, filters.to.month, filters.to.day, 23, 59, 59);
  final merged = <DistributorPrimRow>[];
  final seen = <int>{};
  for (final chunk in chunks) {
    for (final row in chunk) {
      if (seen.add(row.id) && !row.earnedAt.isBefore(fromDay) && !row.earnedAt.isAfter(toDay)) {
        merged.add(row);
      }
    }
  }
  merged.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  return merged;
});

class DistributorPrimsScreen extends ConsumerStatefulWidget {
  const DistributorPrimsScreen({super.key});

  @override
  ConsumerState<DistributorPrimsScreen> createState() => _DistributorPrimsScreenState();
}

class _DistributorPrimsScreenState extends ConsumerState<DistributorPrimsScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
  }

  DistributorPrimFilters get _filters => DistributorPrimFilters(from: _from, to: _to);

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final async = ref.watch(distributorPrimsProvider(filters));
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            label: Text('${dateFmt.format(_from)} - ${dateFmt.format(_to)}'),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) =>
                ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorPrimsProvider(filters))),
            data: (rows) {
              final earned = rows.where((r) => !r.isReversed).fold<double>(0, (s, r) => s + r.primAmount);
              final reversed = rows.where((r) => r.isReversed).fold<double>(0, (s, r) => s + r.primAmount);
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(distributorPrimsProvider(filters)),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        StatCard(label: 'Kazanılan', value: formatUsd(earned), icon: Icons.trending_up),
                        StatCard(label: 'Geri alınan', value: formatUsd(reversed), icon: Icons.undo),
                        StatCard(label: 'Net', value: formatUsd(earned - reversed), icon: Icons.savings),
                        StatCard(label: 'Kayıt', value: '${rows.length}', icon: Icons.list_alt),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (rows.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Prim kaydı yok.')))
                    else
                      ...rows.map(
                        (r) => Card(
                          child: ListTile(
                            title: Text('#${r.transferNumber}'),
                            subtitle: Text(
                              '${r.earnedAt.day}.${r.earnedAt.month}.${r.earnedAt.year} · Havale ${formatUsd(r.transferAmount)}',
                            ),
                            trailing: Text(
                              formatUsd(r.primAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: r.isReversed ? Colors.red : Colors.green.shade700,
                                decoration: r.isReversed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final distributorUsersProvider = FutureProvider.autoDispose((ref) async {
  final users = await ref.watch(distributorRepositoryProvider).getUsers();
  return users.where((u) => u.role.contains('Distributor')).toList(growable: false);
});

class DistributorUsersScreen extends ConsumerWidget {
  const DistributorUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(distributorUsersProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          ErrorView(message: e.toString(), onRetry: () => ref.invalidate(distributorUsersProvider)),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('Kullanıcı bulunamadı.'));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(distributorUsersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final u = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?')),
                  title: Text(u.fullName),
                  subtitle: Text('${u.email}\n${u.role}'),
                  isThreeLine: true,
                  trailing: Icon(u.isActive ? Icons.check_circle : Icons.block, color: u.isActive ? Colors.green : Colors.grey),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
