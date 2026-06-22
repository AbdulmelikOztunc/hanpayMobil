import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/shared/models/admin_models.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:intl/intl.dart';

final adminPrimPackagesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getPrimPackages();
});

final adminPrimRecordsProvider = FutureProvider.autoDispose
    .family<List<DistributorPrimRow>, ({int? distributorId, DateTime from, DateTime to})>((ref, filters) async {
  final months = _monthsInRange(filters.from, filters.to);
  if (months.isEmpty) {
    final now = DateTime.now();
    return ref.watch(adminRepositoryProvider).getAllPrims(
          year: now.year,
          month: now.month,
          distributorId: filters.distributorId,
        );
  }
  final chunks = await Future.wait(
    months.map(
      (m) => ref.watch(adminRepositoryProvider).getAllPrims(
            year: m.year,
            month: m.month,
            distributorId: filters.distributorId,
          ),
    ),
  );
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

class AdminPrimPackagesScreen extends ConsumerWidget {
  const AdminPrimPackagesScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    PrimPackageDetail? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;
    final brackets = existing?.brackets
            .map(
              (b) => _BracketForm(
                min: b.minAmountUsd,
                max: b.maxAmountUsd,
                prim: b.primUsdPerTransfer,
                sort: b.sortOrder,
              ),
            )
            .toList() ??
        [_BracketForm()];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Prim paketi oluştur' : 'Prim paketi düzenle'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Paket adı'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Dilimler', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => setState(() => brackets.add(_BracketForm(sort: brackets.length))),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ekle'),
                      ),
                    ],
                  ),
                  ...brackets.asMap().entries.map((e) {
                    final idx = e.key;
                    final b = e.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: b.min.toString(),
                                    decoration: const InputDecoration(labelText: 'Min USD'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (v) => b.min = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: b.max.toString(),
                                    decoration: const InputDecoration(labelText: 'Max USD'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (v) => b.max = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                            TextFormField(
                              initialValue: b.prim.toString(),
                              decoration: const InputDecoration(labelText: 'Prim USD / transfer'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (v) => b.prim = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                            ),
                            if (brackets.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () => setState(() => brackets.removeAt(idx)),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (saved != true || name.isEmpty) return;

    final body = {
      'name': name,
      'isActive': isActive,
      'brackets': brackets
          .asMap()
          .entries
          .map(
            (e) => {
              'minAmountUsd': e.value.min,
              'maxAmountUsd': e.value.max,
              'primUsdPerTransfer': e.value.prim,
              'sortOrder': e.key,
            },
          )
          .toList(),
    };

    try {
      if (existing == null) {
        await ref.read(adminRepositoryProvider).createPrimPackage(body);
      } else {
        await ref.read(adminRepositoryProvider).updatePrimPackage(existing.id, body);
      }
      ref.invalidate(adminPrimPackagesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prim paketi kaydedildi')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PrimPackageRow pkg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paketi sil'),
        content: Text('"${pkg.name}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deletePrimPackage(pkg.id);
      ref.invalidate(adminPrimPackagesProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPrimPackagesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminPrimPackagesProvider)),
        data: (rows) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminPrimPackagesProvider),
          child: rows.isEmpty
              ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Prim paketi yok.'))])
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = rows[index];
                    return Card(
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.distributorName ?? 'Genel paket'),
                        trailing: Icon(
                          p.isActive ? Icons.check_circle : Icons.pause_circle,
                          color: p.isActive ? Colors.green : Colors.grey,
                        ),
                        onTap: () async {
                          try {
                            final detail = await ref.read(adminRepositoryProvider).getPrimPackage(p.id);
                            if (context.mounted) await _openForm(context, ref, existing: detail);
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                            }
                          }
                        },
                        onLongPress: () => _delete(context, ref, p),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _BracketForm {
  _BracketForm({this.min = 0, this.max = 0, this.prim = 0, this.sort = 0});
  double min;
  double max;
  double prim;
  int sort;
}

class AdminPrimRecordsScreen extends ConsumerStatefulWidget {
  const AdminPrimRecordsScreen({super.key});

  @override
  ConsumerState<AdminPrimRecordsScreen> createState() => _AdminPrimRecordsScreenState();
}

class _AdminPrimRecordsScreenState extends ConsumerState<AdminPrimRecordsScreen> {
  late DateTime _from;
  late DateTime _to;
  int? _distributorId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
  }

  ({int? distributorId, DateTime from, DateTime to}) get _filters =>
      (distributorId: _distributorId, from: _from, to: _to);

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
    final async = ref.watch(adminPrimRecordsProvider(filters));
    final distributorsAsync = ref.watch(_primDistributorsProvider);
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              distributorsAsync.when(
                data: (items) => DropdownButtonFormField<int?>(
                  initialValue: _distributorId,
                  decoration: const InputDecoration(labelText: 'Dağıtıcı'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    ...items.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setState(() => _distributorId = v),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
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
                ErrorView(message: e.toString(), onRetry: () => ref.invalidate(adminPrimRecordsProvider(filters))),
            data: (rows) {
              final earned = rows.where((r) => !r.isReversed).fold<double>(0, (s, r) => s + r.primAmount);
              final reversed = rows.where((r) => r.isReversed).fold<double>(0, (s, r) => s + r.primAmount);
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminPrimRecordsProvider(filters)),
                child: ListView(
                  padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Prim kaydı yok.')),
                      )
                    else
                      ...rows.map(
                        (r) => Card(
                          child: ListTile(
                            title: Text('#${r.transferNumber}'),
                            subtitle: Text('${r.distributorName ?? '-'}\n${dateFmt.format(r.earnedAt.toLocal())}'),
                            isThreeLine: true,
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

final _primDistributorsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getDistributors();
});
