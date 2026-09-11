import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/call_model.dart';
import '../../services/call_history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.user});

  final User user;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = CallHistoryService();
  String _filter = 'all';

  List<CallModel> _applyFilter(List<CallModel> items) {
    return switch (_filter) {
      'missed' => items.where((item) => item.status == 'missed' || item.status == 'failed').toList(),
      'incoming' => items.where((item) => item.direction == 'incoming').toList(),
      'outgoing' => items.where((item) => item.direction == 'outgoing').toList(),
      _ => items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: StreamBuilder<List<CallModel>>(
        stream: _service.watchHistory(widget.user.uid),
        builder: (context, snapshot) {
          final source = snapshot.data ?? const <CallModel>[];
          final items = _applyFilter(source);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Call history', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            const SizedBox(height: 5),
                            Text('${source.length} recent calls', style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (source.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear history',
                          style: IconButton.styleFrom(backgroundColor: scheme.errorContainer),
                          onPressed: () => _confirmClear(context),
                          icon: Icon(Icons.delete_sweep_rounded, color: scheme.error),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                sliver: SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final option in const [
                          ('all', 'All'),
                          ('incoming', 'Incoming'),
                          ('outgoing', 'Outgoing'),
                          ('missed', 'Missed'),
                        ]) ...[
                          ChoiceChip(
                            label: Text(option.$2),
                            selected: _filter == option.$1,
                            onSelected: (selected) => setState(() => _filter = option.$1),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null)
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                const SliverFillRemaining(hasScrollBody: false, child: _MessageState())
              else if (items.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: _MessageState(empty: true))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _HistoryTile(item: items[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear call history?'),
        content: const Text('This removes the call records from Firestore for your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')), 
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.clearHistory(widget.user.uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call history cleared.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not clear history: $error')));
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final CallModel item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incoming = item.direction == 'incoming';
    final missed = item.status == 'missed' || item.status == 'failed';
    final video = item.callType == 'video';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: missed ? scheme.errorContainer : scheme.primaryContainer,
              child: Icon(video ? Icons.videocam_rounded : Icons.call_rounded, color: missed ? scheme.error : scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.peerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(incoming ? Icons.call_received_rounded : Icons.call_made_rounded, size: 15, color: missed ? scheme.error : scheme.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${_status(item.status)} • ${item.createdAt == null ? 'Time unavailable' : Formatters.callDate(item.createdAt!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: missed ? scheme.error : scheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.durationSeconds > 0)
              Text(Formatters.duration(item.durationSeconds), style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _status(String value) {
    if (value.isEmpty) return 'Ended';
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({this.empty = false});

  final bool empty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 34, backgroundColor: scheme.primaryContainer, child: Icon(empty ? Icons.phone_in_talk_outlined : Icons.error_outline_rounded, size: 32, color: scheme.primary)),
            const SizedBox(height: 14),
            Text(empty ? 'No calls in this view' : 'Could not load call history', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(empty ? 'Try another filter or make your first call.' : 'Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
