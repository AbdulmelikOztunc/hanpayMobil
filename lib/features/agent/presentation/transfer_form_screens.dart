import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/translator_ext.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/models/state_model.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/gradient_filled_button.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

final transferFormStatesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(agentRepositoryProvider).getStates();
});

class CreateTransferScreen extends ConsumerStatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  ConsumerState<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class EditTransferScreen extends ConsumerStatefulWidget {
  const EditTransferScreen({super.key, required this.transferId});

  final int transferId;

  @override
  ConsumerState<EditTransferScreen> createState() => _EditTransferScreenState();
}

abstract class _TransferFormStateBase<T extends ConsumerStatefulWidget> extends ConsumerState<T> {
  final _formKey = GlobalKey<FormState>();
  final senderName = TextEditingController();
  final senderSurname = TextEditingController();
  final receiverName = TextEditingController();
  final receiverSurname = TextEditingController();
  final receiverPhone = TextEditingController();
  final receiverAddress = TextEditingController();
  final amount = TextEditingController();
  final cashUsd = TextEditingController(text: '0');
  final cashTl = TextEditingController(text: '0');
  final bankUsd = TextEditingController(text: '0');
  final bankTl = TextEditingController(text: '0');
  final discountUsd = TextEditingController(text: '0');
  final note = TextEditingController();

  StateDto? selectedState;
  TransferSummaryQuote? quote;
  bool loading = false;
  bool quoting = false;

  @override
  void dispose() {
    senderName.dispose();
    senderSurname.dispose();
    receiverName.dispose();
    receiverSurname.dispose();
    receiverPhone.dispose();
    receiverAddress.dispose();
    amount.dispose();
    cashUsd.dispose();
    cashTl.dispose();
    bankUsd.dispose();
    bankTl.dispose();
    discountUsd.dispose();
    note.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> refreshQuote() async {
    final amt = _num(amount);
    if (amt <= 0) {
      setState(() => quote = null);
      return;
    }
    setState(() => quoting = true);
    try {
      final q = await ref.read(transferRepositoryProvider).getSummaryQuote(
            transferAmountUsd: amt,
            cashUsd: _num(cashUsd),
            bankUsd: _num(bankUsd),
            cashTl: _num(cashTl),
            bankTl: _num(bankTl),
            discountUsd: _num(discountUsd),
          );
      if (mounted) setState(() => quote = q);
    } catch (_) {
      if (mounted) setState(() => quote = null);
    } finally {
      if (mounted) setState(() => quoting = false);
    }
  }

  Map<String, dynamic> buildBody() => {
        'stateId': selectedState!.id,
        'receiverPhoneCountry': 'TM',
        'senderName': senderName.text.trim(),
        'senderSurname': senderSurname.text.trim(),
        'receiverName': receiverName.text.trim(),
        'receiverSurname': receiverSurname.text.trim(),
        'receiverPhone': receiverPhone.text.trim(),
        'receiverAddress': receiverAddress.text.trim(),
        'amount': _num(amount),
        'amountInWords': quote?.transferAmountUsdWords ?? '',
        'cashUsd': _num(cashUsd),
        'cashTl': _num(cashTl),
        'bankUsd': _num(bankUsd),
        'bankTl': _num(bankTl),
        if (_num(discountUsd) > 0) 'discountUsd': _num(discountUsd),
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      };

  Widget buildForm({required String submitLabel, required Future<void> Function() onSubmit}) {
    final statesAsync = ref.watch(transferFormStatesProvider);
    return statesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(transferFormStatesProvider),
      ),
      data: (states) => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<StateDto>(
              value: selectedState,
              decoration: InputDecoration(labelText: ref.tw('transfer_field_state')),
              items: states
                  .map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.code})')))
                  .toList(),
              onChanged: (v) => setState(() => selectedState = v),
              validator: (v) => v == null ? 'Eyalet seçin' : null,
            ),
            const SizedBox(height: 12),
            Text(ref.tw('transfer_field_sender'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: senderName,
                    decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: senderSurname,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(ref.tw('transfer_field_receiver'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: receiverName,
                    decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: receiverSurname,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: receiverPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: receiverAddress,
              decoration: const InputDecoration(labelText: 'Adres'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: ref.tw('transfer_field_amount_usd')),
              onChanged: (_) => refreshQuote(),
              validator: (v) {
                if (_num(amount) <= 0) return 'Geçerli tutar girin';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text('Ödeme dağılımı', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _moneyRow('Nakit USD', cashUsd),
            _moneyRow('Nakit TL', cashTl),
            _moneyRow('Banka USD', bankUsd),
            _moneyRow('Banka TL', bankTl),
            _moneyRow('İndirim USD', discountUsd),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: quoting ? null : refreshQuote, child: const Text('Özet hesapla')),
            ),
            if (quote != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Özet', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _summaryRow('Komisyon', formatUsd(quote!.commission)),
                      _summaryRow('Net komisyon', formatUsd(quote!.netCommissionUsd)),
                      _summaryRow('Toplam USD', formatUsd(quote!.totalUsd)),
                      _summaryRow('Toplam TL', '₺${quote!.totalTl.toStringAsFixed(2)}'),
                      _summaryRow('Kalan USD', formatUsd(quote!.remainingUsd)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            GradientFilledButton(
              onPressed: loading ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => loading = true);
                try {
                  await onSubmit();
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                } finally {
                  if (mounted) setState(() => loading = false);
                }
              },
              loading: loading,
              child: Text(submitLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => refreshQuote(),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}

class _CreateTransferScreenState extends _TransferFormStateBase<CreateTransferScreen> {
  @override
  Widget build(BuildContext context) {
    return buildForm(
      submitLabel: ref.tw('nav_create_transfer'),
      onSubmit: () async {
        await refreshQuote();
        if (selectedState != null) {
          await ref.read(transferRepositoryProvider).getPreviewTransferNumber(selectedState!.id);
        }
        final number = await ref.read(transferRepositoryProvider).createTransfer(buildBody());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Havale oluşturuldu: $number')));
        context.go('/agent/transfers');
      },
    );
  }
}

class _EditTransferScreenState extends _TransferFormStateBase<EditTransferScreen> {
  bool bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tx = await ref.read(transferRepositoryProvider).getById(widget.transferId);
      senderName.text = tx.senderName.isNotEmpty ? tx.senderName : tx.senderFullName.split(' ').first;
      senderSurname.text = tx.senderSurname;
      receiverName.text = tx.receiverName.isNotEmpty ? tx.receiverName : tx.receiverFullName.split(' ').first;
      receiverSurname.text = tx.receiverSurname;
      receiverPhone.text = tx.receiverPhone;
      receiverAddress.text = tx.receiverAddress;
      amount.text = tx.amount.toString();
      cashUsd.text = tx.cashUsdAmount.toString();
      cashTl.text = tx.cashTlAmount.toString();
      bankUsd.text = tx.bankUsdAmount.toString();
      bankTl.text = tx.bankTlAmount.toString();
      discountUsd.text = tx.commissionDiscountUsd.toString();
      note.text = '';
      final states = await ref.read(agentRepositoryProvider).getStates();
      selectedState = states.where((s) => s.id == tx.stateId).firstOrNull ??
          (states.isNotEmpty ? states.first : null);
      await refreshQuote();
    } finally {
      if (mounted) setState(() => bootstrapping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bootstrapping) return const LoadingView();
    return buildForm(
      submitLabel: 'Güncelle',
      onSubmit: () async {
        final body = buildBody()
          ..remove('amountInWords')
          ..addAll({
            'amount': _num(amount),
            if (quote != null) 'amountInWords': quote!.transferAmountUsdWords,
          });
        await ref.read(transferRepositoryProvider).updateTransfer(widget.transferId, body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Havale güncellendi')));
        context.pop();
      },
    );
  }
}
