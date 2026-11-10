import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/home_feed.dart';

class HomeRepository {
  HomeRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Các mục của Trang chủ: tiếp tục học, bán chạy tuần này, vì bạn đã học...,
  /// đã xem gần đây, giáo viên nổi bật.
  Future<HomeFeed> home() async =>
      HomeFeed.fromJson(JsonUtils.asMap(await _api.get('/home')));
}
