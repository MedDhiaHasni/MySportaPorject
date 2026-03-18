class AppDateUtils {
  AppDateUtils._();

  static const _days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
                          'Jul','Aug','Sep','Oct','Nov','Dec'];

  static String formatDate(DateTime d) =>
      '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}'; // traja3 date f format "Mon, 12 Jan"

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String formatTime(String time) => time; // HH:mm passthrough

  static bool isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static bool isTomorrow(DateTime d) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return d.year == tomorrow.year && d.month == tomorrow.month && d.day == tomorrow.day;
  }

  static String relativeDay(DateTime d) {
    if (isToday(d))    return 'Today';
    if (isTomorrow(d)) return 'Tomorrow';
    return formatDate(d);
  }
}   
