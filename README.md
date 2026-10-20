# ECOLearning App (Flutter)

Ứng dụng di động cho **học viên** của hệ thống ECOLearning (KLCN044). Phát triển tiếp từ bộ UI Tuần 04
(`D:\Nam4_DH\KLTN\Tuan04\UI-Design-App`), nối với API của website.

Tài liệu phân công và tài liệu API: **`D:\Nam4_DH\KLTN\Tuan10\Task_Tuan10.docx`**. Mã việc (T-x, N-x)
và mã API (A1, B3, G4…) trong code đều theo tài liệu này.

| Thành viên | Phụ trách |
| --- | --- |
| Phú | API (backend, repo ECOLearning) |
| Thư | Khung chung (`lib/core`, `lib/data/api…`), luồng **Tìm & Mua**: đăng nhập/đăng ký, trang chủ & gợi ý, khám phá, chi tiết khóa học, giỏ hàng, thanh toán VNPay |
| Ngọc | Luồng **Học tập**: khóa học của tôi, không gian học (video, tiến độ), đánh giá, quiz, chứng chỉ, hồ sơ, lịch sử đơn hàng, yêu thích |

## Chạy app

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://xxxx.trycloudflare.com/api/v1
```

- `API_BASE_URL` là địa chỉ Phú gửi trong nhóm (Cloudflare Tunnel, đổi mỗi lần chạy lại).
  Không truyền thì dùng giá trị trong `lib/core/config/api_config.dart`.
- Máy ảo Android **không** gọi được `https://localhost:44350` của máy chạy web, nên phải dùng địa chỉ tunnel.
- Kiểm tra code: `flutter analyze` (phải "No issues found") và `flutter test`.

## Cấu trúc thư mục

```
lib/
  main.dart                     Nạp token + giỏ hàng, đăng ký provider, xử lý hết phiên (401)
  core/
    config/api_config.dart      BASE_URL, thời gian chờ, hằng số thanh toán / tiến độ
    network/api_client.dart     Gọi API (dio): tự gắn token, mở khung { success, data }, lỗi → ApiException
    network/api_exception.dart  Lỗi có message tiếng Việt, code (EMAIL_EXISTS…), errors theo từng ô
    network/paged_result.dart   Dữ liệu phân trang { items, page, total, totalPages }
    storage/token_storage.dart  Lưu token an toàn (flutter_secure_storage)
    utils/json_utils.dart       Đọc JSON an toàn (thiếu trường / khác kiểu không văng app)
    constants/, theme/, utils/formatters.dart   Design system từ bộ UI Tuần 04
  data/
    models/                     Course, Lesson, Chapter, User, Category (đã có fromJson), AuthSession
    repositories/               Mỗi file một nhóm API trong tài liệu:
      auth_repository.dart          A1–A7, A12
      profile_repository.dart       A8–A11
      course_repository.dart        B1–B8
      recommendation_repository.dart C1–C4
      favorite_repository.dart      D1–D2
      review_repository.dart        E1
      order_repository.dart         F1–F6
      learning_repository.dart      G1–G4
      quiz_repository.dart          H1–H7
    mock_data.dart              Dữ liệu giả của bộ UI (bỏ dần khi màn hình dùng API thật)
  presentation/
    providers/auth_provider.dart    Trạng thái đăng nhập: login, register, restoreSession, logout
    providers/cart_provider.dart    Giỏ hàng lưu trên máy (giá thật luôn lấy lại bằng F1)
    navigation/app_navigator.dart   Về màn Đăng nhập khi hết phiên, hiện SnackBar không cần context
    widgets/state_views.dart        LoadingView, EmptyView, ErrorView (nút "Thử lại"), showErrorSnackBar
    widgets/under_construction.dart Khung tạm cho màn chưa làm
    screens/                    14 màn hình từ bộ UI + màn mới (đang là khung tạm):
      payment/      Thanh toán VNPay (WebView), Kết quả thanh toán   – Thư, T-7
      interests/    Chọn lĩnh vực quan tâm                          – Thư, T-3
      quiz/         Giới thiệu, Làm bài, Kết quả quiz               – Ngọc, N-5
      favorites/    Khóa học yêu thích                              – Ngọc, N-8
      orders/       Lịch sử đơn hàng                                – Ngọc, N-8
docs/                           Quy chuẩn thiết kế và đặc tả giao diện (Tuần 04)
```

## Màn hình gọi API thế nào

Màn hình **không** gọi `ApiClient` trực tiếp, mà gọi qua repository. Mỗi màn hình có đủ 3 trạng thái:
đang tải, rỗng, lỗi.

```dart
class _MyCoursesTabState extends State<MyCoursesTab> {
  final _repo = LearningRepository();
  late Future<PagedResult<Course>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.myCourses(status: MyCourseStatus.inProgress);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PagedResult<Course>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingView();
        if (snap.hasError) {
          return ErrorView(
            error: snap.error,
            onRetry: () => setState(() => _future = _repo.myCourses()),
          );
        }
        final page = snap.data!;
        if (page.isEmpty) {
          return const EmptyView(title: 'Bạn chưa sở hữu khóa học nào');
        }
        return ListView(
          children: page.items.map((c) => CourseCard(course: c, onTap: () => _open(c))).toList(),
        );
      },
    );
  }
}
```

Thao tác bấm nút (đăng nhập, thả tim, nộp bài…) thì bắt `ApiException` để hiện `message`:

```dart
try {
  await context.read<AuthProvider>().login(email, password);
} on ApiException catch (e) {
  setState(() => _error = e.message);           // hoặc e.fieldError('email') để tô đỏ từng ô
}
```

## Quy ước làm việc

- Mỗi bạn làm trên nhánh riêng (`thu-...`, `ngoc-...`), gộp vào nhánh chính qua Pull Request, người còn lại xem trước khi gộp.
- **Không sửa chung file**: `lib/core`, `lib/data/repositories`, `lib/presentation/providers` do Thư sửa; Ngọc cần thêm gì thì nhắn Thư.
- Cần API mới hoặc đổi dữ liệu trả về: nhắn Phú, không tự đoán. Phú cập nhật tài liệu rồi mới đổi code.
- Thêm thư viện mới thì báo cả nhóm.
- Quy tắc nghiệp vụ (hoàn thành bài ≥ 80%, điều kiện đánh giá, quiz, thanh toán chỉ Thẻ ATM nội địa…) làm theo
  mục 7 của tài liệu, server là bên quyết định; app chỉ hiển thị theo dữ liệu server trả về.
