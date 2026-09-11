import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static String duration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  static String callDate(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    if (sameDay) return 'Today, ${DateFormat('h:mm a').format(local)}';
    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday = local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day;
    if (wasYesterday) return 'Yesterday, ${DateFormat('h:mm a').format(local)}';
    return DateFormat('MMM d, h:mm a').format(local);
  }

  static String lastSeen(DateTime? value) {
    if (value == null) return 'Last seen unavailable';
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inSeconds < 45) return 'Active just now';
    if (difference.inMinutes < 60) return 'Active ${difference.inMinutes}m ago';
    if (difference.inHours < 24) return 'Active ${difference.inHours}h ago';
    return 'Last seen ${DateFormat('MMM d').format(value.toLocal())}';
  }
}
