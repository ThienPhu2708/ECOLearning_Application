import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/promo_ad.dart';

/// Ảnh quảng cáo chiến dịch / chương trình khuyến mãi dùng chung với website.
class PromoAdRepository {
  PromoAdRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Ảnh quảng cáo đang chạy. Token tùy chọn: ưu đãi thân thiết chỉ có khi đã đăng nhập và đủ điều kiện.
  Future<List<PromoAd>> ads() async {
    final data = JsonUtils.asMap(await _api.get('/ads'));
    return JsonUtils.asList(data['items'])
        .map((e) => PromoAd.fromJson(JsonUtils.asMap(e)))
        .where((a) => a.id.isNotEmpty && a.imageUrl.isNotEmpty)
        .toList();
  }

  /// Trang ưu đãi của một quảng cáo; [type] là `campaign` hoặc `promotion`.
  Future<PromoAdPage> page(String type, String id) async =>
      PromoAdPage.fromJson(
        JsonUtils.asMap(
          await _api.get(
            '/ads/${Uri.encodeComponent(type)}/${Uri.encodeComponent(id)}',
          ),
        ),
      );

  /// Popup ưu đãi thân thiết (cần đăng nhập).
  Future<LoyaltyPopup> loyaltyPopup() async => LoyaltyPopup.fromJson(
    JsonUtils.asMap(await _api.get('/coupons/loyalty-popup')),
  );
}
