import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/features/insights/data/insights_repository.dart';
import 'package:hanpay_mobil/shared/models/insights_models.dart';
import 'package:hanpay_mobil/shared/models/role.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class InsightsScope {
  const InsightsScope({this.agentId, this.distributorId});

  final int? agentId;
  final int? distributorId;

  static InsightsScope fromSession(AppRole role, {int? agentId, int? distributorId}) {
    if (role.isAdmin) return const InsightsScope();
    if (role.isAgent) return InsightsScope(agentId: agentId);
    if (role.isDistributor) return InsightsScope(distributorId: distributorId);
    return const InsightsScope();
  }
}

InsightsScope _scopeFromRef(WidgetRef ref) {
  final session = ref.read(authControllerProvider).session!;
  return InsightsScope.fromSession(
    session.role,
    agentId: session.agentId,
    distributorId: session.distributorId,
  );
}

final monthlyVolumeProvider = FutureProvider.autoDispose.family<MonthlyTransferVolumeDto, (InsightsScope, int)>(
  (ref, args) {
    final scope = args.$1;
    final months = args.$2;
    return ref.watch(insightsRepositoryProvider).getMonthlyTransferVolume(
          months: months,
          agentId: scope.agentId,
          distributorId: scope.distributorId,
        );
  },
);

class MonthlyTransferVolumeScreen extends ConsumerStatefulWidget {
  const MonthlyTransferVolumeScreen({super.key});

  @override
  ConsumerState<MonthlyTransferVolumeScreen> createState() => _MonthlyTransferVolumeScreenState();
}

class _MonthlyTransferVolumeScreenState extends ConsumerState<MonthlyTransferVolumeScreen> {
  int months = 6;

  @override
  Widget build(BuildContext context) {
    final scope = _scopeFromRef(ref);
    final async = ref.watch(monthlyVolumeProvider((scope, months)));
    final monthFmt = DateFormat('MMM yyyy', 'tr');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 6, label: Text('6 ay')),
              ButtonSegment(value: 12, label: Text('12 ay')),
            ],
            selected: {months},
            onSelectionChanged: (v) => setState(() => months = v.first),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(monthlyVolumeProvider((scope, months))),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(monthlyVolumeProvider((scope, months))),
              child: ListView(
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
                      StatCard(
                        label: 'Toplam tutar',
                        value: formatUsd(data.totalAmount),
                        icon: Icons.payments_outlined,
                      ),
                      StatCard(
                        label: 'Transfer adedi',
                        value: '${data.totalTransferCount}',
                        icon: Icons.swap_horiz,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (data.points.isNotEmpty) ...[
                    Text('Grafik', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _VerticalBarChart(
                      items: data.points
                          .map(
                            (p) => _BarChartItem(
                              label: monthFmt.format(DateTime(p.year, p.month)),
                              value: p.amount,
                              subtitle: '${p.transferCount} adet',
                            ),
                          )
                          .toList(),
                      valueFormatter: formatUsd,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Aylık dağılım', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (data.points.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Bu dönemde veri yok.')),
                    )
                  else
                    ...data.points.map((p) {
                      final maxAmount = data.points.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
                      final ratio = maxAmount > 0 ? p.amount / maxAmount : 0.0;
                      final label = monthFmt.format(DateTime(p.year, p.month));
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${p.transferCount} adet'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: ratio.clamp(0, 1)),
                              const SizedBox(height: 6),
                              Text(formatUsd(p.amount)),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final paymentDistributionProvider =
    FutureProvider.autoDispose.family<PaymentDistributionDto, (InsightsScope, int, int)>((ref, args) {
  final scope = args.$1;
  return ref.watch(insightsRepositoryProvider).getPaymentDistribution(
        year: args.$2,
        month: args.$3,
        agentId: scope.agentId,
        distributorId: scope.distributorId,
      );
});

class PaymentDistributionScreen extends ConsumerStatefulWidget {
  const PaymentDistributionScreen({super.key});

  @override
  ConsumerState<PaymentDistributionScreen> createState() => _PaymentDistributionScreenState();
}

class _PaymentDistributionScreenState extends ConsumerState<PaymentDistributionScreen> {
  late int year;
  late int month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(year, month),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        year = picked.year;
        month = picked.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scopeFromRef(ref);
    final async = ref.watch(paymentDistributionProvider((scope, year, month)));

    return Column(
      children: [
        ListTile(
          title: const Text('Dönem'),
          subtitle: Text('${month.toString().padLeft(2, '0')}/$year'),
          trailing: IconButton(icon: const Icon(Icons.calendar_month), onPressed: _pickMonth),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(paymentDistributionProvider((scope, year, month))),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(paymentDistributionProvider((scope, year, month))),
              child: ListView(
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
                      StatCard(
                        label: 'Transfer adedi',
                        value: '${data.totalTransferCount}',
                        icon: Icons.receipt_long,
                      ),
                      StatCard(
                        label: 'Toplam tutar',
                        value: formatUsd(data.totalTransferAmount),
                        icon: Icons.attach_money,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _VerticalBarChart(
                    items: [
                      _BarChartItem(label: 'Nakit', value: data.usdTotals.cash, color: Colors.green.shade600),
                      _BarChartItem(label: 'Banka', value: data.usdTotals.bank, color: Colors.blue.shade600),
                    ],
                    valueFormatter: formatUsd,
                    title: 'USD dağılımı',
                  ),
                  const SizedBox(height: 12),
                  _VerticalBarChart(
                    items: [
                      _BarChartItem(label: 'Nakit', value: data.tlTotals.cash, color: Colors.green.shade600),
                      _BarChartItem(label: 'Banka', value: data.tlTotals.bank, color: Colors.blue.shade600),
                    ],
                    valueFormatter: (v) => '₺${v.toStringAsFixed(2)}',
                    title: 'TL dağılımı',
                  ),
                  const SizedBox(height: 12),
                  _DistributionCard(
                    title: 'USD — Nakit / Banka',
                    cash: data.usdTotals.cash,
                    bank: data.usdTotals.bank,
                    cashRatio: data.usdRatios.cashRatio,
                    bankRatio: data.usdRatios.bankRatio,
                  ),
                  const SizedBox(height: 12),
                  _DistributionCard(
                    title: 'TL — Nakit / Banka',
                    cash: data.tlTotals.cash,
                    bank: data.tlTotals.bank,
                    cashRatio: data.tlRatios.cashRatio,
                    bankRatio: data.tlRatios.bankRatio,
                    isTl: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.title,
    required this.cash,
    required this.bank,
    required this.cashRatio,
    required this.bankRatio,
    this.isTl = false,
  });

  final String title;
  final double cash;
  final double bank;
  final double cashRatio;
  final double bankRatio;
  final bool isTl;

  String _fmt(double v) => isTl ? '₺${v.toStringAsFixed(2)}' : formatUsd(v);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row('Nakit', _fmt(cash), cashRatio),
            const SizedBox(height: 8),
            _row('Banka', _fmt(bank), bankRatio),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, double ratio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: ratio.clamp(0, 1)),
        Text('${(ratio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

final transferReportProvider = FutureProvider.autoDispose
    .family<List<TransferReportRow>, ({InsightsScope scope, String period, int? filterAgentId, int? filterDistributorId, String? status, int? stateId})>(
  (ref, args) {
    final agentId = args.filterAgentId ?? args.scope.agentId;
    final distributorId = args.filterDistributorId ?? args.scope.distributorId;
    return ref.watch(insightsRepositoryProvider).getTransferReport(
          period: args.period,
          agentId: agentId,
          distributorId: distributorId,
          status: args.status,
          stateId: args.stateId,
          take: 200,
        );
  },
);

class TransferReportScreen extends ConsumerStatefulWidget {
  const TransferReportScreen({super.key, this.showAdminFilters = false});

  final bool showAdminFilters;

  @override
  ConsumerState<TransferReportScreen> createState() => _TransferReportScreenState();
}

class _TransferReportScreenState extends ConsumerState<TransferReportScreen> {
  String period = 'thisMonth';
  var _exporting = false;
  int? _filterAgentId;
  int? _filterDistributorId;
  String? _filterStatus;
  int? _filterStateId;

  ({InsightsScope scope, String period, int? filterAgentId, int? filterDistributorId, String? status, int? stateId}) _query(InsightsScope scope) => (
        scope: scope,
        period: period,
        filterAgentId: widget.showAdminFilters ? _filterAgentId : null,
        filterDistributorId: widget.showAdminFilters ? _filterDistributorId : null,
        status: widget.showAdminFilters ? _filterStatus : null,
        stateId: widget.showAdminFilters ? _filterStateId : null,
      );

  Future<void> _exportExcel(({InsightsScope scope, String period, int? filterAgentId, int? filterDistributorId, String? status, int? stateId}) query) async {
    setState(() => _exporting = true);
    try {
      final agentId = query.filterAgentId ?? query.scope.agentId;
      final distributorId = query.filterDistributorId ?? query.scope.distributorId;
      final export = await ref.read(insightsRepositoryProvider).downloadTransferReportExcel(
            period: query.period,
            agentId: agentId,
            distributorId: distributorId,
            status: query.status,
            stateId: query.stateId,
            take: 200,
          );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${export.filename}');
      await file.writeAsBytes(export.bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Transfer raporu');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scopeFromRef(ref);
    final query = _query(scope);
    final async = ref.watch(transferReportProvider(query));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    final agentsAsync = widget.showAdminFilters ? ref.watch(_reportAgentsProvider) : null;
    final distributorsAsync = widget.showAdminFilters ? ref.watch(_reportDistributorsProvider) : null;
    final statesAsync = widget.showAdminFilters ? ref.watch(_reportStatesProvider) : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              if (widget.showAdminFilters) ...[
                agentsAsync?.when(
                  data: (agents) => DropdownButtonFormField<int?>(
                    initialValue: _filterAgentId,
                    decoration: const InputDecoration(labelText: 'Acente'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...agents.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                    ],
                    onChanged: (v) => setState(() => _filterAgentId = v),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ) ?? const SizedBox.shrink(),
                const SizedBox(height: 8),
                distributorsAsync?.when(
                  data: (distributors) => DropdownButtonFormField<int?>(
                    initialValue: _filterDistributorId,
                    decoration: const InputDecoration(labelText: 'Dağıtıcı'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...distributors.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                    ],
                    onChanged: (v) => setState(() => _filterDistributorId = v),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ) ?? const SizedBox.shrink(),
                const SizedBox(height: 8),
                statesAsync?.when(
                  data: (states) => DropdownButtonFormField<int?>(
                    initialValue: _filterStateId,
                    decoration: const InputDecoration(labelText: 'Eyalet'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...states.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _filterStateId = v),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ) ?? const SizedBox.shrink(),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _filterStatus,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tümü')),
                    DropdownMenuItem(value: 'Pending', child: Text('Bekliyor')),
                    DropdownMenuItem(value: 'Paid', child: Text('Ödendi')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('İptal')),
                    DropdownMenuItem(value: 'InProgress', child: Text('Devam ediyor')),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'today', label: Text('Bugün')),
                        ButtonSegment(value: 'thisMonth', label: Text('Bu ay')),
                      ],
                      selected: {period},
                      onSelectionChanged: (v) => setState(() => period = v.first),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Excel indir',
                    onPressed: _exporting ? null : () => _exportExcel(query),
                    icon: _exporting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(transferReportProvider(query)),
            ),
            data: (rows) {
              final totalAmount = rows.fold<double>(0, (s, r) => s + r.amount);
              final totalCommission = rows.fold<double>(0, (s, r) => s + r.netCommission);
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(transferReportProvider(query)),
                child: rows.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Rapor satırı bulunamadı.')),
                        ],
                      )
                    : ListView(
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
                              StatCard(label: 'Satır', value: '${rows.length}', icon: Icons.list),
                              StatCard(label: 'Toplam', value: formatUsd(totalAmount), icon: Icons.summarize),
                              StatCard(
                                label: 'Net komisyon',
                                value: formatUsd(totalCommission),
                                icon: Icons.percent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...rows.map(
                            (r) => Card(
                              child: ListTile(
                                title: Text(r.transferNumber ?? r.receiverFullName),
                                subtitle: Text(
                                  '${r.status}\n${r.receiverFullName}\n${dateFmt.format(r.createdAtLocal)}',
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(formatUsd(r.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(formatUsd(r.netCommission), style: const TextStyle(fontSize: 12)),
                                  ],
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

class _BarChartItem {
  const _BarChartItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
  });

  final String label;
  final double value;
  final String? subtitle;
  final Color? color;
}

class _VerticalBarChart extends StatelessWidget {
  const _VerticalBarChart({
    required this.items,
    required this.valueFormatter,
    this.title,
    this.height = 160,
  });

  final List<_BarChartItem> items;
  final String Function(double) valueFormatter;
  final String? title;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maxValue = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in items)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              valueFormatter(item.value),
                              style: theme.textTheme.labelSmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: maxValue > 0 ? (item.value / maxValue).clamp(0.05, 1.0) : 0.05,
                                  widthFactor: 0.65,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: item.color ?? theme.colorScheme.primary,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.label,
                              style: theme.textTheme.labelSmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.subtitle != null)
                              Text(
                                item.subtitle!,
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _reportAgentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getAgents();
});

final _reportDistributorsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getDistributors();
});

final _reportStatesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminRepositoryProvider).getStates();
});
