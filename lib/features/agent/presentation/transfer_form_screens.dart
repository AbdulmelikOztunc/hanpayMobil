import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanpay_mobil/core/i18n/translator_ext.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/agent/data/agent_repository.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/models/balance_models.dart';
import 'package:hanpay_mobil/shared/models/state_model.dart';
import 'package:hanpay_mobil/shared/utils/receiver_phone_format.dart';
import 'package:hanpay_mobil/shared/widgets/async_views.dart';
import 'package:hanpay_mobil/shared/widgets/gradient_filled_button.dart';
import 'package:hanpay_mobil/shared/widgets/phone_country_field.dart';
import 'package:hanpay_mobil/shared/widgets/stat_card.dart';

const _paymentToleranceTl = 0.01;

final transferFormStatesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(agentRepositoryProvider).getStates();
});

final transferFormMinimumUsdProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(transferRepositoryProvider).getMinimumTransferUsd();
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
  final senderPhone = TextEditingController();
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
  ReceiverPhoneCountry senderPhoneCountry = ReceiverPhoneCountry.tr;
  ReceiverPhoneCountry receiverPhoneCountry = ReceiverPhoneCountry.tm;
  TransferSummaryQuote? quote;
  String? previewNumber;
  double minimumTransferUsd = 0;
  bool loading = false;
  bool quoting = false;
  bool loadingPreview = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    senderName.dispose();
    senderSurname.dispose();
    senderPhone.dispose();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showMissingStateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('transfer_receiver_city')),
        content: Text(ref.t('toast_transfer_state_required')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ref.t('btn_ok')),
          ),
        ],
      ),
    );
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<bool> _validateBeforeSubmit() async {
    if (selectedState == null) {
      await _showMissingStateDialog();
      return false;
    }
    return _formKey.currentState!.validate();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  double _round2(double v) => (v * 100).roundToDouble() / 100;

  String? _phoneValidator(ReceiverPhoneCountry country, String? value) {
    if (value == null || value.trim().isEmpty) return ref.tw('validation_field_required');
    if (!isReceiverPhoneComplete(country, value)) {
      return country == ReceiverPhoneCountry.tr
          ? ref.tw('transfer_phone_incomplete_tr')
          : ref.tw('transfer_phone_incomplete_tm');
    }
    return null;
  }

  String? _discountError() {
    final d = _num(discountUsd);
    if (d < 0) return ref.tw('transfer_discount_negative_error');
    if (quote != null && d > quote!.commission) {
      return ref.tw('transfer_discount_exceeds_commission_error');
    }
    return null;
  }

  bool _paymentBalanced() {
    final amt = _num(amount);
    if (amt <= 0 || quote == null) return false;
    final rate = quote!.exchangeRate;
    if (rate <= 0) return false;
    final paidTl = _round2(
      _num(cashTl) + _num(bankTl) + (_num(cashUsd) + _num(bankUsd)) * rate,
    );
    final delta = _round2(quote!.totalTl - paidTl);
    return delta.abs() <= _paymentToleranceTl;
  }

  String? _preSubmitError() {
    if (quote == null) return ref.tw('transfer_next_blocked_summary');
    final discountErr = _discountError();
    if (discountErr != null) return discountErr;
    if (!_paymentBalanced()) {
      final rate = quote!.exchangeRate;
      final paidTl = _round2(
        _num(cashTl) + _num(bankTl) + (_num(cashUsd) + _num(bankUsd)) * rate,
      );
      final delta = _round2(quote!.totalTl - paidTl);
      final amountStr = '₺${delta.abs().toStringAsFixed(2)}';
      return delta > 0
          ? ref.tw('transfer_next_blocked_payment_under', {'amount': amountStr})
          : ref.tw('transfer_next_blocked_payment_over', {'amount': amountStr});
    }
    return null;
  }

  Future<void> _loadPreviewNumber(int stateId) async {
    setState(() => loadingPreview = true);
    try {
      final n = await ref.read(transferRepositoryProvider).getPreviewTransferNumber(stateId);
      if (mounted) setState(() => previewNumber = n);
    } catch (_) {
      if (mounted) setState(() => previewNumber = null);
    } finally {
      if (mounted) setState(() => loadingPreview = false);
    }
  }

  Future<void> _updateExchangeRate() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('USD/TRY kuru'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Kur'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    );
    final value = double.tryParse(ctrl.text.replaceAll(',', '.'));
    ctrl.dispose();
    if (ok != true || value == null || value <= 0) return;
    try {
      await ref.read(agentRepositoryProvider).updateOwnExchangeRate(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kur güncellendi')));
        await refreshQuote();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

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
        'receiverPhoneCountry': receiverPhoneCountry.apiValue,
        'senderName': senderName.text.trim(),
        'senderSurname': senderSurname.text.trim(),
        'receiverName': receiverName.text.trim(),
        'receiverSurname': receiverSurname.text.trim(),
        'receiverPhone': receiverPhoneForApi(receiverPhoneCountry, receiverPhone.text),
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
    ref.watch(transferFormMinimumUsdProvider).whenData((min) {
      if (minimumTransferUsd != min) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => minimumTransferUsd = min);
        });
      }
    });
    return statesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(transferFormStatesProvider),
      ),
      data: (states) {
        final sortedStates = [...states]..sort((a, b) => a.name.compareTo(b.name));
        return Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<StateDto>(
              initialValue: selectedState,
              decoration: InputDecoration(labelText: ref.tw('transfer_receiver_city')),
              items: sortedStates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedState = v;
                  previewNumber = null;
                });
                if (v != null) _loadPreviewNumber(v.id);
              },
            ),
            if (previewNumber != null || loadingPreview) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: loadingPreview
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.tag),
                title: Text(ref.tw('transfer_preview_number_label')),
                subtitle: Text(previewNumber ?? '—'),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _updateExchangeRate,
                icon: const Icon(Icons.currency_exchange, size: 18),
                label: Text(ref.tw('transfer_btn_update_exchange_rate')),
              ),
            ),
            const SizedBox(height: 12),
            Text(ref.tw('transfer_sender_section_title'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: senderName,
                    decoration: InputDecoration(labelText: ref.tw('transfer_sender_first_name')),
                    validator: (v) => v == null || v.trim().isEmpty ? ref.tw('validation_field_required') : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: senderSurname,
                    decoration: InputDecoration(labelText: ref.tw('transfer_sender_last_name')),
                    validator: (v) => v == null || v.trim().isEmpty ? ref.tw('validation_field_required') : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PhoneCountryField(
              country: senderPhoneCountry,
              phoneController: senderPhone,
              onCountryChanged: (c) => setState(() => senderPhoneCountry = c),
              countryLabel: ref.tw('transfer_sender_phone_country'),
              phoneLabel: ref.tw('transfer_sender_phone'),
              countryTmLabel: ref.tw('transfer_phone_country_tm'),
              countryTrLabel: ref.tw('transfer_phone_country_tr'),
              phonePlaceholder: ref.tw(receiverPhonePlaceholderKey(senderPhoneCountry)),
              phoneValidator: (v) => _phoneValidator(senderPhoneCountry, v),
            ),
            const SizedBox(height: 16),
            Text(ref.tw('transfer_receiver_section_title'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: receiverName,
                    decoration: InputDecoration(labelText: ref.tw('transfer_receiver_first_name')),
                    validator: (v) => v == null || v.trim().isEmpty ? ref.tw('validation_field_required') : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: receiverSurname,
                    decoration: InputDecoration(labelText: ref.tw('transfer_receiver_last_name')),
                    validator: (v) => v == null || v.trim().isEmpty ? ref.tw('validation_field_required') : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PhoneCountryField(
              country: receiverPhoneCountry,
              phoneController: receiverPhone,
              onCountryChanged: (c) => setState(() => receiverPhoneCountry = c),
              countryLabel: ref.tw('transfer_receiver_phone_country'),
              phoneLabel: ref.tw('transfer_receiver_phone'),
              countryTmLabel: ref.tw('transfer_phone_country_tm'),
              countryTrLabel: ref.tw('transfer_phone_country_tr'),
              phonePlaceholder: ref.tw(receiverPhonePlaceholderKey(receiverPhoneCountry)),
              phoneValidator: (v) => _phoneValidator(receiverPhoneCountry, v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: receiverAddress,
              decoration: InputDecoration(labelText: ref.tw('transfer_receiver_address')),
              validator: (v) => v == null || v.trim().isEmpty ? ref.tw('validation_field_required') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: ref.tw('transfer_field_amount_usd')),
              onChanged: (_) => refreshQuote(),
              validator: (v) {
                final amt = _num(amount);
                if (amt <= 0) return ref.tw('transfer_amount_invalid');
                if (minimumTransferUsd > 0 && amt < minimumTransferUsd) {
                  return ref.tw('transfer_minimum_usd_hint', {'min': formatUsd(minimumTransferUsd)});
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(ref.tw('transfer_payment_section_title'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _moneyRow(ref.tw('payment_cash_usd'), cashUsd),
            _moneyRow(ref.tw('payment_cash_tl'), cashTl),
            _moneyRow(ref.tw('payment_bank_usd'), bankUsd),
            _moneyRow(ref.tw('payment_bank_tl'), bankTl),
            _moneyRow(ref.tw('transfer_discount_usd_label'), discountUsd),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: quoting ? null : refreshQuote,
                child: Text(ref.tw('transfer_btn_calculate_summary')),
              ),
            ),
            if (quote != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.tw('transfer_summary_title'), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _summaryRow(ref.tw('transfer_summary_commission'), formatUsd(quote!.commission)),
                      _summaryRow(ref.tw('transfer_summary_net_commission'), formatUsd(quote!.netCommissionUsd)),
                      _summaryRow(ref.tw('transfer_summary_usd_incl_commission'), formatUsd(quote!.totalUsd)),
                      _summaryRow(ref.tw('transfer_summary_total_tl'), '₺${quote!.totalTl.toStringAsFixed(2)}'),
                      _summaryRow(ref.tw('transfer_summary_remaining_usd'), formatUsd(quote!.remainingUsd)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: note,
              decoration: InputDecoration(labelText: ref.tw('transfer_note_label')),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            GradientFilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!await _validateBeforeSubmit()) return;
                await refreshQuote();
                final preSubmit = _preSubmitError();
                if (preSubmit != null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(preSubmit)));
                  }
                  return;
                }
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
      );
      },
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
          await _loadPreviewNumber(selectedState!.id);
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
      final parsedPhone = parsePhoneFromStored(tx.receiverPhone);
      receiverPhoneCountry = parsedPhone.country;
      receiverPhone.text = parsedPhone.display;
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
      if (selectedState != null) {
        await _loadPreviewNumber(selectedState!.id);
      }
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
