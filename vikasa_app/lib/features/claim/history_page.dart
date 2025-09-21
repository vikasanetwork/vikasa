import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/decimal_utils.dart';

class ClaimHistoryPage extends StatefulWidget {
  const ClaimHistoryPage({super.key});

  @override
  State<ClaimHistoryPage> createState() => _ClaimHistoryPageState();
}

class _ClaimHistoryPageState extends State<ClaimHistoryPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final supa = Supabase.maybeGetInstance();
    final user = supa?.client.auth.currentUser;
    if (supa == null || user == null) return [];
    final rows = await supa.client
        .from('claims')
        .select('claimed_at, unlock_at, status, amount')
        .eq('user_id', user.id)
        .order('claimed_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Scaffold(
      appBar: AppBar(title: const Text('Claim History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No claims yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final row = items[i];
              final claimedAt = DateTime.parse(row['claimed_at']).toUtc();
              final unlockAt = DateTime.parse(row['unlock_at']).toUtc();
              final status = (row['status'] as String?) ?? 'locked';
              final amountStr = row['amount'].toString();
              final display = formatDecimalString(amountStr, precision: 8);

              return ListTile(
                title: Text('$display VIK'),
                subtitle: Text('Claimed: ${df.format(claimedAt)} UTC\nUnlock: ${df.format(unlockAt)} UTC'),
                trailing: Chip(
                  label: Text(status),
                  backgroundColor: status == 'unlocked' ? const Color(0xFF1B5E20) : const Color(0xFF263238),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
