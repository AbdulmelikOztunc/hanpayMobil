import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanpay_mobil/core/network/api_exception.dart';
import 'package:hanpay_mobil/features/admin/data/admin_repository.dart';
import 'package:hanpay_mobil/features/transfers/data/transfer_repository.dart';
import 'package:hanpay_mobil/shared/models/admin_models.dart';
import 'package:hanpay_mobil/shared/models/state_model.dart';
import 'package:hanpay_mobil/shared/models/transfer.dart';

Future<void> showCreateAgentDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final limitCtrl = TextEditingController(text: '0');
  final commissionCtrl = TextEditingController(text: '2');
  var countryCode = 'TR';

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Acente oluştur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kod')),
              TextField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Kredi limiti (USD)'),
              ),
              TextField(
                controller: commissionCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Komisyon (%)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: countryCode,
                decoration: const InputDecoration(labelText: 'Ülke kodu'),
                items: const [
                  DropdownMenuItem(value: 'TR', child: Text('TR')),
                  DropdownMenuItem(value: 'TM', child: Text('TM')),
                  DropdownMenuItem(value: 'RU', child: Text('RU')),
                ],
                onChanged: (v) => setState(() => countryCode = v ?? 'TR'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oluştur')),
        ],
      ),
    ),
  );
  if (ok != true) {
    nameCtrl.dispose();
    codeCtrl.dispose();
    limitCtrl.dispose();
    commissionCtrl.dispose();
    return;
  }

  final pct = double.tryParse(commissionCtrl.text.replaceAll(',', '.')) ?? 0;
  try {
    await ref.read(adminRepositoryProvider).createAgent({
      'name': nameCtrl.text.trim(),
      'code': codeCtrl.text.trim(),
      'countryCode': countryCode,
      'limit': double.tryParse(limitCtrl.text.replaceAll(',', '.')) ?? 0,
      'commissionRate': pct / 100,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acente oluşturuldu')));
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } finally {
    nameCtrl.dispose();
    codeCtrl.dispose();
    limitCtrl.dispose();
    commissionCtrl.dispose();
  }
}

Future<void> showEditAgentDialog(
  BuildContext context,
  WidgetRef ref,
  AdminAgentDto agent,
) async {
  final nameCtrl = TextEditingController(text: agent.name);
  final limitCtrl = TextEditingController(text: (agent.creditLimit ?? 0).toString());
  final commissionCtrl = TextEditingController(
    text: agent.commissionRate != null ? (agent.commissionRate! * 100).toStringAsFixed(2) : '0',
  );
  var isActive = agent.isActive;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Acente düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(
              controller: limitCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kredi limiti (USD)'),
            ),
            TextField(
              controller: commissionCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Komisyon (%)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    ),
  );
  if (ok != true) {
    nameCtrl.dispose();
    limitCtrl.dispose();
    commissionCtrl.dispose();
    return;
  }

  final pct = double.tryParse(commissionCtrl.text.replaceAll(',', '.')) ?? 0;
  try {
    await ref.read(adminRepositoryProvider).updateAgent(agent.id, {
      'name': nameCtrl.text.trim(),
      'limit': double.tryParse(limitCtrl.text.replaceAll(',', '.')) ?? 0,
      'commissionRate': pct / 100,
      'isActive': isActive,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acente güncellendi')));
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } finally {
    nameCtrl.dispose();
    limitCtrl.dispose();
    commissionCtrl.dispose();
  }
}

Future<void> showCreateDistributorDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  StateDto? selectedState;
  int? primPackageId;
  final states = await ref.read(adminRepositoryProvider).getStates();
  final packages = await ref.read(adminRepositoryProvider).getPrimPackages();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Dağıtıcı oluştur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
              if (states.isNotEmpty)
                DropdownButtonFormField<StateDto>(
                  initialValue: selectedState,
                  decoration: const InputDecoration(labelText: 'Eyalet'),
                  items: states.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => selectedState = v),
                ),
              if (packages.isNotEmpty)
                DropdownButtonFormField<int?>(
                  initialValue: primPackageId,
                  decoration: const InputDecoration(labelText: 'Prim paketi (isteğe bağlı)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Yok')),
                    ...packages.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                  ],
                  onChanged: (v) => setState(() => primPackageId = v),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oluştur')),
        ],
      ),
    ),
  );
  if (ok != true || selectedState == null) {
    nameCtrl.dispose();
    return;
  }

  try {
    await ref.read(adminRepositoryProvider).createDistributor({
      'name': nameCtrl.text.trim(),
      'state': selectedState!.name,
      'stateCode': selectedState!.code,
      if (primPackageId != null) 'distributorPrimPackageId': primPackageId,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dağıtıcı oluşturuldu')));
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } finally {
    nameCtrl.dispose();
  }
}

Future<void> showEditDistributorDialog(
  BuildContext context,
  WidgetRef ref,
  AdminDistributorDto distributor,
) async {
  final nameCtrl = TextEditingController(text: distributor.name);
  var isActive = distributor.isActive;
  final states = await ref.read(adminRepositoryProvider).getStates();
  StateDto? selectedState = states.where((s) => s.name == distributor.stateName).firstOrNull;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Dağıtıcı düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
            if (states.isNotEmpty)
              DropdownButtonFormField<StateDto>(
                initialValue: selectedState,
                decoration: const InputDecoration(labelText: 'Eyalet'),
                items: states.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => selectedState = v),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      ),
    ),
  );
  if (ok != true) {
    nameCtrl.dispose();
    return;
  }

  try {
    await ref.read(adminRepositoryProvider).updateDistributor(distributor.id, {
      'name': nameCtrl.text.trim(),
      if (selectedState != null) 'state': selectedState!.name,
      if (selectedState != null) 'stateCode': selectedState!.code,
      'isActive': isActive,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dağıtıcı güncellendi')));
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } finally {
    nameCtrl.dispose();
  }
}

bool canAdminCancelTransfer(TransferStatus status) =>
    status != TransferStatus.cancelled && status != TransferStatus.paid;

Future<bool> showAdminCancelTransferDialog(
  BuildContext context,
  WidgetRef ref, {
  required int transferId,
  double netCommissionUsd = 0,
}) async {
  final noteCtrl = TextEditingController();
  var commissionMode = 1;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Transferi iptal et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Admin notu (isteğe bağlı)'),
              maxLines: 2,
            ),
            if (netCommissionUsd > 0) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: commissionMode,
                decoration: const InputDecoration(labelText: 'Komisyon'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Acenteye iade')),
                  DropdownMenuItem(value: 2, child: Text('Platformda bırak')),
                ],
                onChanged: (v) => setState(() => commissionMode = v ?? 1),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal et'),
          ),
        ],
      ),
    ),
  );
  final adminNote = noteCtrl.text.trim();
  noteCtrl.dispose();
  if (ok != true) return false;

  try {
    await ref.read(transferRepositoryProvider).cancelAsAdmin(
          transferId,
          commissionSettlement: commissionMode,
          adminNote: adminNote.isEmpty ? null : adminNote,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer iptal edildi')));
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
}
