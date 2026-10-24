import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/coupon.dart';

/// Promotion and wallet operations shared with the website.
class CouponRepository {
  CouponRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<CollectableCoupons> collectable({String? courseId}) async {
    final data = JsonUtils.asMap(
      await _api.get(
        '/coupons/collectable',
        query: {
          if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        },
      ),
    );
    return CollectableCoupons.fromJson(data);
  }

  Future<CouponWallet> wallet(String tab) async => CouponWallet.fromJson(
    JsonUtils.asMap(await _api.get('/coupons/wallet', query: {'tab': tab})),
  );

  Future<Map<String, dynamic>> save(String code) async => JsonUtils.asMap(
    await _api.post('/coupons/${Uri.encodeComponent(code)}/save'),
  );

  Future<Map<String, dynamic>> check(
    String code,
    List<String> courseIds,
  ) async => JsonUtils.asMap(
    await _api.post(
      '/coupons/check',
      data: {'code': code, 'courseIds': courseIds},
    ),
  );

  Future<Map<String, dynamic>> details(String code) async =>
      JsonUtils.asMap(await _api.get('/coupons/${Uri.encodeComponent(code)}'));
}
