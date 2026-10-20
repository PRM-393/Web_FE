// Kiem tra du lieu nhap tren form (Form + TextFormField.validator). May chu van kiem tra lai (NFR-SEC-03).
// Ham tra ve null khi hop le, nguoc lai tra ve thong bao loi tieng Viet.

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Vui lòng nhập email';
  if (!_emailPattern.hasMatch(v)) return 'Email không hợp lệ';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
  if (value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
  return null;
}

String? validateRequired(String? value, String field) =>
    (value == null || value.trim().isEmpty) ? 'Vui lòng nhập $field' : null;

// Tien VND la so nguyen (CON-06); cho phep nguoi dung go dau cham / phay ngan cach hang nghin
int? parseMoney(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[.,\s₫]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

String? validateMoney(String? value, String field, {bool allowZero = true}) {
  final amount = parseMoney(value);
  if (amount == null) return 'Vui lòng nhập $field hợp lệ';
  if (amount < 0 || (!allowZero && amount == 0)) return '$field phải lớn hơn 0';
  return null;
}

String? validatePositiveInt(String? value, String field) {
  final n = int.tryParse(value?.trim() ?? '');
  if (n == null || n < 1) return '$field phải là số nguyên từ 1 trở lên';
  return null;
}

// OTP su dung voucher gom dung 6 chu so (FR-REDEEM-06)
String? validateRedeemOtp(String? value) {
  final v = value?.trim() ?? '';
  if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Mã OTP gồm 6 chữ số';
  return null;
}

// FR-SETTLE-01 / BR-09: quan tri vien nhap ty le hoa hong theo phan tram cho de doc.
// May chu luu ty le 0..1 va chi nhan khoang mo 0 < rate < 1, nen phan tram phai 0 < p < 100.
// Gioi han 2 chu so thap phan de ty le gui len khong qua 4 chu so thap phan (DTO cua may chu).
const maxCommissionPercentDecimals = 2;

double? parseCommissionPercent(String? value) {
  // Ban phim tieng Viet hay go dau phay lam dau thap phan
  final text = (value ?? '').trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String? validateCommissionPercent(String? value) {
  final percent = parseCommissionPercent(value);
  if (percent == null) return 'Vui lòng nhập tỷ lệ hoa hồng, ví dụ 10';
  if (percent <= 0) return 'Tỷ lệ hoa hồng phải lớn hơn 0%';
  if (percent >= 100) return 'Tỷ lệ hoa hồng phải nhỏ hơn 100%';
  final decimals = (value ?? '').trim().replaceAll(',', '.').split('.');
  if (decimals.length > 1 && decimals[1].length > maxCommissionPercentDecimals) {
    return 'Tỷ lệ hoa hồng tối đa $maxCommissionPercentDecimals chữ số thập phân';
  }
  return null;
}

// Phan tram tren form -> ty le 0..1 gui len may chu. Lam tron 4 chu so thap phan de
// phep chia cho 100 khong de lai sai so dau cham dong khien may chu tu choi.
double commissionPercentToRate(double percent) => double.parse((percent / 100).toStringAsFixed(4));

String? validateLatitude(String? value) {
  final v = double.tryParse(value?.trim() ?? '');
  if (v == null || v < -90 || v > 90) return 'Vĩ độ từ -90 đến 90';
  return null;
}

String? validateLongitude(String? value) {
  final v = double.tryParse(value?.trim() ?? '');
  if (v == null || v < -180 || v > 180) return 'Kinh độ từ -180 đến 180';
  return null;
}

// Rang buoc giua cac truong cua chien dich: DC-10 / BR-21 (ngay ban, han dung), FR-CAMP-03 / DC-07 (chi nhanh)
const minExpireAfterSaleEnd = Duration(days: 10);

// FR-CAMP-12: truong gia tri theo loai voucher (voucherType null = chi kiem tra chung)
String? validateCampaignRules({
  required int salePrice,
  required int faceValue,
  required DateTime saleStartAt,
  required DateTime saleEndAt,
  required DateTime voucherExpireAt,
  required int storeCount,
  String? voucherType,
  String? discountType,
  int? discountValue,
  int? maxDiscount,
  String? comboItems,
}) {
  if (salePrice <= 0) return 'Giá bán phải lớn hơn 0';
  if (voucherType == 'PREPAID' && faceValue <= salePrice) {
    return 'Voucher mệnh giá phải có giá trị lớn hơn giá bán';
  }
  if (salePrice > faceValue) return 'Giá bán không được lớn hơn giá trị voucher';
  if (voucherType == 'DISCOUNT') {
    if (discountType == null || discountValue == null || discountValue <= 0) {
      return 'Mã giảm giá cần chọn kiểu giảm và nhập giá trị giảm';
    }
    if (discountType == 'PERCENT' && (discountValue > 100 || maxDiscount == null || maxDiscount <= 0)) {
      return 'Giảm theo phần trăm cần giá trị từ 1 đến 100 và mức giảm tối đa';
    }
  }
  if (voucherType == 'COMBO' && (comboItems == null || comboItems.trim().isEmpty)) {
    return 'Combo cần mô tả nội dung gói';
  }
  if (!saleStartAt.isBefore(saleEndAt)) return 'Ngày kết thúc bán phải sau ngày bắt đầu bán';
  if (voucherExpireAt.isBefore(saleEndAt.add(minExpireAfterSaleEnd))) {
    return 'Hạn sử dụng phải sau ngày kết thúc bán ít nhất 10 ngày';
  }
  if (storeCount == 0) return 'Chọn ít nhất một chi nhánh áp dụng';
  return null;
}
