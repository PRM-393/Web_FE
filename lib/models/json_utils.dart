// Cot numeric/bigint cua PostgreSQL duoc TypeORM tra ve dang chuoi, nen phai nhan ca num lan String
double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? value) => value == null ? null : asDouble(value);

DateTime asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);

DateTime? asDateOrNull(Object? value) => value is String ? DateTime.tryParse(value) : null;

List<T> asList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) =>
    value is List ? value.whereType<Map<String, dynamic>>().map(fromJson).toList() : <T>[];

// F01: trang ket qua { items, total, page, pageSize }; phan hoi dang mang (cu) coi nhu mot trang duy nhat
class PageResult<T> {
  const PageResult({required this.items, required this.total, required this.page, required this.pageSize});

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;

  factory PageResult.fromJson(Object? json, T Function(Map<String, dynamic>) fromJson) {
    if (json is Map) {
      final items = asList(json['items'], fromJson);
      return PageResult(
        items: items,
        total: asInt(json['total'], items.length),
        page: asInt(json['page'], 1),
        pageSize: asInt(json['pageSize'], items.isEmpty ? 20 : items.length),
      );
    }
    final items = asList(json, fromJson);
    return PageResult(items: items, total: items.length, page: 1, pageSize: items.isEmpty ? 20 : items.length);
  }
}
