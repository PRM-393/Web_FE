import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

// Dinh dang tien te VND, khong co phan thap phan - CON-06, NFR-USA-04
String formatVnd(num amount) => _vnd.format(amount);

// Du lieu luu UTC, hien thi theo mui gio Asia/Ho_Chi_Minh (UTC+7, khong co gio mua he) - CON-05
String formatDateTime(DateTime value) =>
    _dateTime.format(value.toUtc().add(const Duration(hours: 7)));

final _date = DateFormat('dd/MM/yyyy');

String formatDate(DateTime value) => _date.format(value.toUtc().add(const Duration(hours: 7)));

// Phan tram -> chuoi gon: 10 -> "10", 7.5 -> "7.5", 99.99 -> "99.99".
// Giu toi da 2 chu so thap phan de ty le hoa hong 99.99% khong bi lam tron thanh "100".
String formatPercentValue(double percent) {
  final text = percent.toStringAsFixed(2);
  return text.contains('.') ? text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : text;
}

// Ty le 0..1 -> "10%"
String formatPercent(double rate) => '${formatPercentValue(rate * 100)}%';

// BR-25: moc "ngay" tinh theo gio Viet Nam. Ngay chon tren form (khong co gio) doi sang thoi diem UTC.
const _vnOffset = Duration(hours: 7);

DateTime vnStartOfDayUtc(DateTime day) => DateTime.utc(day.year, day.month, day.day).subtract(_vnOffset);

DateTime vnEndOfDayUtc(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day, 23, 59, 59).subtract(_vnOffset);

// Thoi diem UTC -> ngay theo gio Viet Nam (chi dung y/m/d) de dien lai vao form
DateTime vnCalendarDay(DateTime value) {
  final vn = value.toUtc().add(_vnOffset);
  return DateTime(vn.year, vn.month, vn.day);
}
