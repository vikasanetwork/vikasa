import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/decimal_utils.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountCtrl = TextEditingController();
  final _walletEmailCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  Decimal _available = Decimal.zero;
  Decimal _minWithdrawal = Decimal.parse('5.00000000');
  Decimal _burnRate = Decimal.parse('0.0001'); // 0.01%

  String _kycStatus = 'none';
  int _completedWithdrawals = 0;

  List<Map<String, dynamic>> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final supa = Supabase.maybeGetInstance();
      final user = supa?.client.auth.currentUser;
      if (supa == null || user == null) {
        setState(() => _loading = false);
        return;
      }

      // Load config values
      final cfg = await supa.client.from('config').select('key,value').in_('key', [
        'min_withdrawal',
        'burn_rate',
      ]);
      for (final row in (cfg as List)) {
        final key = row['key'] as String;
        final value = row['value'];
        if (key == 'min_withdrawal') {
          final s = value['value']?.toString() ?? '5.00000000';
          _minWithdrawal = Decimal.parse(s);
        } else if (key == 'burn_rate') {
          final s = value['value']?.toString() ?? '0.0001';
          _burnRate = Decimal.parse(s);
        }
      }

      // Load profile
      final prof = await supa.client.from('profiles').select('nc_wallet_email, kyc_status').eq('id', user.id).maybeSingle();
      if (prof != null) {
        _walletEmailCtrl.text = (prof['nc_wallet_email'] as String?) ?? '';
        _kycStatus = (prof['kyc_status'] as String?) ?? 'none';
      }

      // Compute available = sum(unlocked claims) - sum(withdrawals requested or complete)
      final claims = await supa.client
          .from('claims')
          .select('amount,status')
          .eq('user_id', user.id)
          .in_('status', ['unlocked']);
      Decimal unlocked = Decimal.zero;
      for (final c in (claims as List)) {
        unlocked += Decimal.parse(c['amount'].toString());
      }

      final wd = await supa.client
          .from('withdrawals')
          .select('gross_amount,status,requested_at,processed_at')
          .eq('user_id', user.id)
          .in_('status', ['requested', 'complete'])
          .order('requested_at', ascending: false);
      Decimal reserved = Decimal.zero;
      int completed = 0;
      for (final w in (wd as List)) {
        reserved += Decimal.parse((w['gross_amount'] ?? '0').toString());
        if ((w['status'] as String?) == 'complete') completed++;
      }
      _completedWithdrawals = completed;
      _withdrawals = (wd as List).cast<Map<String, dynamic>>();

      _available = unlocked - reserved;
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _kycRequiredExceeded => _completedWithdrawals >= 5 && _kycStatus != 'verified';

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');

    final amount = _parseAmount(_amountCtrl.text);
    final canPreview = amount != null;
    final burn = canPreview ? (amount! * _burnRate) : Decimal.zero;
    final net = canPreview ? (amount! - burn) : Decimal.zero;

    final canSubmit = !_loading && !_submitting &&
        amount != null && amount > Decimal.zero &&
        amount >= _minWithdrawal && amount <= _available &&
        _walletEmailCtrl.text.trim().isNotEmpty &&
        !_kycRequiredExceeded;

    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw VIK')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _infoRow('Available', '${formatDecimal(_available, precision: 8)} VIK'),
                  _infoRow('Minimum', '${formatDecimal(_minWithdrawal, precision: 8)} VIK'),
                  _infoRow('Burn rate', '${formatDecimal(_burnRate, precision: 8)} (fraction)'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _walletEmailCtrl,
                    decoration: const InputDecoration(labelText: 'NC Wallet Email (required)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (VIK)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (canPreview) ...[
                    _infoRow('Burn', '${formatDecimal(burn, precision: 8)} VIK'),
                    _infoRow('Net (after burn)', '${formatDecimal(net, precision: 8)} VIK'),
                  ],
                  if (_kycRequiredExceeded)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('KYC required after 5 withdrawals. Please complete KYC to continue.',
                          style: TextStyle(color: Colors.orangeAccent)),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    child: Text(_submitting ? 'Submitting…' : 'Request Withdrawal (Saturday processing)'),
                  ),
                  const SizedBox(height: 24),
                  Text('Recent withdrawals', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_withdrawals.isEmpty)
                    const Text('No withdrawals yet.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _withdrawals.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final w = _withdrawals[i];
                        final amount = Decimal.parse((w['gross_amount'] ?? '0').toString());
                        final status = (w['status'] as String?) ?? 'requested';
                        final ts = (w['processed_at'] ?? w['requested_at'])?.toString();
                        final when = ts != null ? df.format(DateTime.parse(ts).toUtc()) : '-';
                        return ListTile(
                          title: Text('${formatDecimal(amount, precision: 8)} VIK'),
                          subtitle: Text(when + ' UTC'),
                          trailing: Chip(
                            label: Text(status),
                            backgroundColor: status == 'complete' ? const Color(0xFF1B5E20) : const Color(0xFF263238),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Decimal? _parseAmount(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return Decimal.parse(t);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final supa = Supabase.maybeGetInstance();
      final user = supa?.client.auth.currentUser;
      if (supa == null || user == null) return;

      final wallet = _walletEmailCtrl.text.trim();
      if (wallet.isEmpty) return;
      await supa.client.from('profiles').update({'nc_wallet_email': wallet}).eq('id', user.id);

      final amount = _parseAmount(_amountCtrl.text);
      if (amount == null) return;

      // Validate client-side constraints again
      if (amount < _minWithdrawal || amount > _available) {
        _show('Invalid amount');
        return;
      }

      final insertRes = await supa.client.from('withdrawals').insert({
        'user_id': user.id,
        'gross_amount': amount.toString(),
        'status': 'requested',
      });
      if (insertRes.error != null) {
        _show('Failed: ${insertRes.error!.message}');
        return;
      }

      _show('Withdrawal requested. Will be processed on Saturday (UTC).');
      _amountCtrl.clear();
      await _init();
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
