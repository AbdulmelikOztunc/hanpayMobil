import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/app_locale.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/transfer_list_tile.dart';
import 'package:intl/intl.dart';

final agentTransfersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getMyAgentTransfers();
});

class AgentTransferListScreen extends ConsumerStatefulWidget {
  const AgentTransferListScreen({super.key});

  @override
  ConsumerState<AgentTransferListScreen> createState() => _AgentTransferListScreenState();
}

class _AgentTransferListScreenState extends ConsumerState<AgentTransferListScreen> {
  final _searchCtrl = TextEditingController();
  String? _status;
  String _datePreset = 'month';
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesDate(TransferDto tx) {
    final created = tx.createdAt.toLocal();
    final now = DateTime.now();
    switch (_datePreset) {
      case 'today':
        return created.year == now.year && created.month == now.month && created.day == now.day;
      case 'month':
        return created.year == now.year && created.month == now.month;
      case 'custom':
        if (_from == null || _to == null) return true;
        final from = DateTime(_from!.year, _from!.month, _from!.day);
        final to = DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59);
        return !created.isBefore(from) && !created.isAfter(to);
      default:
        return true;
    }
  }

  List<TransferDto> _filter(List<TransferDto> items) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return items.where((tx) {
      if (_status != null && tx.status.name != _status) return false;
      if (!_matchesDate(tx)) return false;
      if (q.isEmpty) return true;
      return tx.transferNumber.toLowerCase().contains(q) ||
          tx.receiverFullName.toLowerCase().contains(q) ||
          tx.senderFullName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (range != null) {
      setState(() {
        _datePreset = 'custom';
        _from = range.start;
        _to = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agentTransfersProvider);
    final locale = ref.watch(localeControllerProvider);
    final money = NumberFormat.currency(locale: locale.numberFormatTag, symbol: r'$', decimalDigits: 2);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm', locale.numberFormatTag);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Ara',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => setState(() {}),
                  ),
                ),
                onSubmitted: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Durum'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tümü')),
                        DropdownMenuItem(value: 'pending', child: Text('Bekliyor')),
                        DropdownMenuItem(value: 'paid', child: Text('Ödendi')),
                        DropdownMenuItem(value: 'cancelled', child: Text('İptal')),
                        DropdownMenuItem(value: 'inProgress', child: Text('Devam ediyor')),
                      ],
                      onChanged: (v) => setState(() => _status = v),
                    ),
                  ),
                  IconButton(onPressed: _pickCustomRange, icon: const Icon(Icons.date_range)),
                ],
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Bugün')),
                  ButtonSegment(value: 'month', label: Text('Bu ay')),
                ],
                selected: {_datePreset == 'custom' ? 'month' : _datePreset},
                onSelectionChanged: (v) => setState(() => _datePreset = v.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(agentTransfersProvider),
            ),
            data: (transfers) {
              final filtered = _filter(transfers);
              if (filtered.isEmpty) {
                return const Center(child: Text('Havale bulunamadı.'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(agentTransfersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    return TransferListTile(
                      transfer: tx,
                      moneyFmt: money,
                      dateFmt: dateFmt,
                      onTap: () => context.push('/agent/transfers/${tx.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
