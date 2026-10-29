import '../../core/utils/json_utils.dart';

/// Shared promotion card returned by `/coupons/collectable`, `/coupons/wallet`
/// and `/coupons/{code}`.
class Coupon {
  // Fields are normalized from the shared promotion API so wallet, home, and
  // checkout can render the same coupon without screen-specific parsing.
  final String code;
  final String title;
  final String discountText;
  final String? note;
  final String description;
  final List<String> conditions;
  final bool isPublic;
  final bool isLoyalty;
  final bool saved;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final int? remaining;
  final String status;
  final String statusText;
  final DateTime? savedAt;
  final int myUses;
  final int? perUserLimit;
  final bool expiringSoon;
  final String? reason;

  const Coupon({
    required this.code,
    required this.title,
    required this.discountText,
    required this.description,
    required this.conditions,
    required this.status,
    required this.statusText,
    this.note,
    this.isPublic = false,
    this.isLoyalty = false,
    this.saved = false,
    this.startsAt,
    this.expiresAt,
    this.remaining,
    this.savedAt,
    this.myUses = 0,
    this.perUserLimit,
    this.expiringSoon = false,
    this.reason,
  });

  // Keep API compatibility for the legacy `name` and `endDate` field names.
  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
    code: JsonUtils.asString(json['code']),
    title: JsonUtils.asString(json['title'] ?? json['name']),
    discountText: JsonUtils.asString(json['discountText']),
    note: JsonUtils.asStringOrNull(json['note']),
    description: JsonUtils.asString(json['description']),
    conditions: JsonUtils.asStringList(json['conditions']),
    isPublic: JsonUtils.asBool(json['isPublic']),
    isLoyalty: JsonUtils.asBool(json['isLoyalty']),
    saved: JsonUtils.asBool(json['saved']),
    startsAt: JsonUtils.asDate(json['startsAt']),
    expiresAt: JsonUtils.asDate(json['expiresAt'] ?? json['endDate']),
    remaining: json['remaining'] == null
        ? null
        : JsonUtils.asInt(json['remaining']),
    status: JsonUtils.asString(json['status'], fallback: 'usable'),
    statusText: JsonUtils.asString(json['statusText']),
    savedAt: JsonUtils.asDate(json['savedAt']),
    myUses: JsonUtils.asInt(json['myUses']),
    perUserLimit: json['perUserLimit'] == null
        ? null
        : JsonUtils.asInt(json['perUserLimit']),
    expiringSoon: JsonUtils.asBool(json['expiringSoon']),
    reason: JsonUtils.asStringOrNull(json['reason']),
  );
}

class CouponWallet {
  final Map<String, int> counts;
  final List<Coupon> items;

  const CouponWallet({required this.counts, required this.items});

  // The API returns per-tab totals alongside the coupons currently requested.
  factory CouponWallet.fromJson(Map<String, dynamic> json) {
    final rawCounts = JsonUtils.asMap(json['counts']);
    return CouponWallet(
      counts: rawCounts.map(
        (key, value) => MapEntry(key, JsonUtils.asInt(value)),
      ),
      items: JsonUtils.asMapList(json['items']).map(Coupon.fromJson).toList(),
    );
  }
}

class CollectableCoupons {
  final List<Coupon> coupons;
  final List<Map<String, dynamic>> loyaltyUpcoming;
  final Map<String, dynamic>? stats;

  const CollectableCoupons({
    required this.coupons,
    required this.loyaltyUpcoming,
    this.stats,
  });

  factory CollectableCoupons.fromJson(Map<String, dynamic> json) =>
      CollectableCoupons(
        coupons: JsonUtils.asMapList(
          json['coupons'],
        ).map(Coupon.fromJson).toList(),
        loyaltyUpcoming: JsonUtils.asMapList(json['loyaltyUpcoming']),
        stats: json['stats'] == null ? null : JsonUtils.asMap(json['stats']),
      );
}
