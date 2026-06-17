import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/features/auth/presentation/auth_controller.dart';
import 'package:hanpay_mobil/features/insights/data/insights_repository.dart';
import 'package:hanpay_mobil/shared/models/insights_models.dart';
import 'package:hanpay_mobil/shared/models/role.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';
import 'package:intl/intl.dart';

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

final transferReportProvider =
    FutureProvider.autoDispose.family<List<TransferReportRow>, (InsightsScope, String)>((ref, args) {
  final scope = args.$1;
  final period = args.$2;
  return ref.watch(insightsRepositoryProvider).getTransferReport(
        period: period,
        agentId: scope.agentId,
        distributorId: scope.distributorId,
        take: 200,
      );
});

class TransferReportScreen extends ConsumerStatefulWidget {
  const TransferReportScreen({super.key, this.showAdminFilters = false});

  final bool showAdminFilters;

  @override
  ConsumerState<TransferReportScreen> createState() => _TransferReportScreenState();
}

class _TransferReportScreenState extends ConsumerState<TransferReportScreen> {
  String period = 'thisMonth';

  @override
  Widget build(BuildContext context) {
    final scope = _scopeFromRef(ref);
    final async = ref.watch(transferReportProvider((scope, period)));
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'today', label: Text('Bugün')),
              ButtonSegment(value: 'thisMonth', label: Text('Bu ay')),
            ],
            selected: {period},
            onSelectionChanged: (v) => setState(() => period = v.first),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(transferReportProvider((scope, period))),
            ),
            data: (rows) {
              final totalAmount = rows.fold<double>(0, (s, r) => s + r.amount);
              final totalCommission = rows.fold<double>(0, (s, r) => s + r.netCommission);
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(transferReportProvider((scope, period))),
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
