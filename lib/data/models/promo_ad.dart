import '../../core/utils/json_utils.dart';
import 'course.dart';

/// Ảnh quảng cáo chiến dịch / chương trình khuyến mãi (`GET /ads`), hiện dạng popup ở trang chủ.
class PromoAd {
  /// `campaign` (chiến dịch, gồm nhiều chương trình) hoặc `promotion` (một chương trình).
  final String type;
  final String id;
  final String title;
  final String imageUrl;
  final DateTime? expiresAt;

  const PromoAd({
    required this.type,
    required this.id,
    required this.title,
    required this.imageUrl,
    this.expiresAt,
  });

  factory PromoAd.fromJson(Map<String, dynamic> json) => PromoAd(
    type: JsonUtils.asString(json['type']),
    id: JsonUtils.asString(json['id']),
    title: JsonUtils.asString(json['title']),
    imageUrl: JsonUtils.asString(json['imageUrl']),
    expiresAt: JsonUtils.asDate(json['expiresAt']),
  );

  /// Khóa nhận diện một quảng cáo (dùng để chỉ hiện một lần mỗi lượt mở app).
  String get key => '$type:$id';
}

/// Một chương trình khuyến mãi trên trang ưu đãi (`GET /ads/{type}/{id}`).
class PromoOffer {
  final String id;
  final String title;
  final String discountText;
  final String? note;
  final List<String> conditions;
  final DateTime? expiresAt;

  /// Giảm trực tiếp: tự áp dụng lên giá khóa học, không có mã.
  final bool isDirectDiscount;
  final bool isLoyalty;

  /// Mã coupon công khai; null với giảm trực tiếp hoặc khi người dùng chưa đủ điều kiện (ưu đãi thân thiết).
  final String? code;
  final bool canSave;
  final bool saved;

  /// Lý do chưa nhận được ưu đãi (vd. ưu đãi thân thiết chưa đủ điều kiện).
  final String? message;

  /// Áp dụng cho mọi khóa học nên không liệt kê khóa.
  final bool appliesToAll;
  final int totalCourses;
  final List<Course> courses;

  const PromoOffer({
    required this.id,
    required this.title,
    required this.discountText,
    this.note,
    this.conditions = const [],
    this.expiresAt,
    this.isDirectDiscount = false,
    this.isLoyalty = false,
    this.code,
    this.canSave = false,
    this.saved = false,
    this.message,
    this.appliesToAll = false,
    this.totalCourses = 0,
    this.courses = const [],
  });

  factory PromoOffer.fromJson(Map<String, dynamic> json) => PromoOffer(
    id: JsonUtils.asString(json['id']),
    title: JsonUtils.asString(json['title']),
    discountText: JsonUtils.asString(json['discountText']),
    note: JsonUtils.asStringOrNull(json['note']),
    conditions: JsonUtils.asStringList(json['conditions']),
    expiresAt: JsonUtils.asDate(json['expiresAt']),
    isDirectDiscount: JsonUtils.asBool(json['isDirectDiscount']),
    isLoyalty: JsonUtils.asBool(json['isLoyalty']),
    code: JsonUtils.asStringOrNull(json['code']),
    canSave: JsonUtils.asBool(json['canSave']),
    saved: JsonUtils.asBool(json['saved']),
    message: JsonUtils.asStringOrNull(json['message']),
    appliesToAll: JsonUtils.asBool(json['appliesToAll']),
    totalCourses: JsonUtils.asInt(json['totalCourses']),
    courses: JsonUtils.asList(
      json['courses'],
    ).map((e) => Course.fromJson(JsonUtils.asMap(e))).toList(),
  );

  PromoOffer copyWith({bool? saved, bool? canSave}) => PromoOffer(
    id: id,
    title: title,
    discountText: discountText,
    note: note,
    conditions: conditions,
    expiresAt: expiresAt,
    isDirectDiscount: isDirectDiscount,
    isLoyalty: isLoyalty,
    code: code,
    canSave: canSave ?? this.canSave,
    saved: saved ?? this.saved,
    message: message,
    appliesToAll: appliesToAll,
    totalCourses: totalCourses,
    courses: courses,
  );
}

/// Trang ưu đãi mở ra khi bấm ảnh quảng cáo.
class PromoAdPage {
  final String type;
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<PromoOffer> offers;

  const PromoAdPage({
    required this.type,
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.startsAt,
    this.endsAt,
    this.offers = const [],
  });

  factory PromoAdPage.fromJson(Map<String, dynamic> json) => PromoAdPage(
    type: JsonUtils.asString(json['type']),
    id: JsonUtils.asString(json['id']),
    title: JsonUtils.asString(json['title']),
    description: JsonUtils.asStringOrNull(json['description']),
    imageUrl: JsonUtils.asStringOrNull(json['imageUrl']),
    startsAt: JsonUtils.asDate(json['startsAt']),
    endsAt: JsonUtils.asDate(json['endsAt']),
    offers: JsonUtils.asList(
      json['offers'],
    ).map((e) => PromoOffer.fromJson(JsonUtils.asMap(e))).toList(),
  );
}

/// Popup "Ưu đãi dành riêng cho học viên thân thiết" (`GET /coupons/loyalty-popup`).
/// Chỉ có khi học viên đã đủ điều kiện ([kind] = `eligible`).
class LoyaltyPopup {
  final bool show;
  final String kind;
  final String promotionId;
  final String? code;
  final String title;
  final String discountText;
  final String? note;
  final String description;
  final List<String> conditions;
  final DateTime? expiresAt;

  const LoyaltyPopup({
    required this.show,
    this.kind = '',
    this.promotionId = '',
    this.code,
    this.title = '',
    this.discountText = '',
    this.note,
    this.description = '',
    this.conditions = const [],
    this.expiresAt,
  });

  factory LoyaltyPopup.fromJson(Map<String, dynamic> json) => LoyaltyPopup(
    show: JsonUtils.asBool(json['show']),
    kind: JsonUtils.asString(json['kind']),
    promotionId: JsonUtils.asString(json['promotionId']),
    code: JsonUtils.asStringOrNull(json['code']),
    title: JsonUtils.asString(json['title']),
    discountText: JsonUtils.asString(json['discountText']),
    note: JsonUtils.asStringOrNull(json['note']),
    description: JsonUtils.asString(json['description']),
    conditions: JsonUtils.asStringList(json['conditions']),
    expiresAt: JsonUtils.asDate(json['expiresAt']),
  );

  bool get isEligible => show && kind == 'eligible' && (code ?? '').isNotEmpty;
}
