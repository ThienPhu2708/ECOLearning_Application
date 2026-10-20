# QUY CHUẨN THIẾT KẾ & ĐẶC TẢ GIAO DIỆN APP MOBILE E-LEARNING (FLUTTER / DART)
> **Tài liệu đặc tả giao diện và trải nghiệm người dùng dành riêng cho phân hệ Học viên (Learner)**  
> **Dự án Khóa luận Tốt nghiệp CNTT — KLCN044 (Tuần 04)**  
> **Nền tảng mục tiêu:** Flutter Cross-Platform (iOS & Android) — Ứng dụng tĩnh (Static UI Prototype / Mock Data)

---

## 1. MỤC TIÊU & PHẠM VI DỰ ÁN MOBILE APP

### 1.1. Mục tiêu
1. Xây dựng một ứng dụng di động đa nền tảng (Cross-Platform) bằng **Flutter & Dart** phục vụ đối tượng **Học viên (Learner)**.
2. Bản thử nghiệm ở giai đoạn này là **App tĩnh (Static UI Prototype)**:
   * Tập trung 100% vào trải nghiệm thị giác (Visual Quality), luồng chuyển trang mượt mà (Smooth Navigation), trạng thái tương tác (Interaction States) và bố cục responsive trên nhiều kích thước màn hình smartphone.
   * Sử dụng nguồn dữ liệu giả lập chuẩn ([mockData](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/assets/js/data.js)) sẵn có trong hệ thống, chưa kết nối trực tiếp cơ sở dữ liệu backend.
3. Kế thừa và đồng bộ hóa 100% bản sắc thương hiệu (Brand Identity) từ phiên bản Website đã hoàn thiện tại [QuyChuanThietKe.md](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/QuyChuanThietKe.md).

### 1.2. Phạm vi chức năng (Use Case trọng tâm cho Học viên)
* **Nhóm Xác thực & Tài khoản:** Đăng nhập, Đăng ký 3 bước (OTP/Password Strength), Đăng xuất, Hồ sơ cá nhân (UC1, UC2, UC3).
* **Nhóm Khám phá & Gợi ý:** Trang chủ có khối gợi ý cá nhân hóa Collaborative Filtering ("98% Fit"), Tìm kiếm & Bộ lọc khóa học nâng cao (UC4, UC7).
* **Nhóm Mua sắm & Thanh toán:** Chi tiết khóa học (xem thử video preview), Giỏ hàng, Nhập Coupon, Thanh toán mô phỏng (UC4).
* **Nhóm Học tập & Tương tác:** Không gian xem video bài giảng (Player tua 10s, tốc độ 0.75x–2x), Cây bài học Accordion, Tích xanh hoàn thành $\ge 80\%$, Đánh giá 5 sao $\ge 70\%$ (UC5, UC6).
* **Nhóm Quản lý tiến độ:** Danh sách "Khóa học của tôi" (Đang học / Đã hoàn thành), Xem và Tải chứng chỉ tốt nghiệp điện tử (UC8).

---

## 2. HỆ THỐNG DESIGN SYSTEM CHO FLUTTER (DESIGN TOKENS)

Toàn bộ thông số thiết kế được quy đổi trực tiếp từ CSS Variables sang mã nguồn Dart / Flutter Theme.

### 2.1. Bảng màu (Color Palette)

| Tên Token (CSS) | Flutter Hex Code | Vai trò & Vị trí ứng dụng trên App Mobile |
| :--- | :--- | :--- |
| `primary` | `Color(0xFF434CE8)` | **Electric Indigo** — Nút bấm chính (CTA), Tabbar active icon, thanh tiến độ học tập, viền active. |
| `primaryHover` | `Color(0xFF353EC4)` | **Deep Indigo** — Trạng thái nhấn nút (Splash/Highlight color). |
| `primaryLight` | `Color(0xFFEEF2FF)` | **Indigo Tint** — Nền Badge danh mục, tag nổi bật, khung thông báo nhẹ, icon wrapper nền. |
| `bgCanvas` | `Color(0xFFF8FAFC)` | **Slate 50** — Màu nền Scaffold (toàn bộ các màn hình hiển thị). |
| `bgSurface` | `Color(0xFFFFFFFF)` | **Pure White** — Nền Thẻ khóa học (Card), Bottom Sheet, AppBar, Bottom Navigation Bar. |
| `bgSubtle` | `Color(0xFFF1F5F9)` | **Slate 100** — Nền các ô Input TextField, thanh track tiến độ chưa hoàn thành. |
| `textHeading` | `Color(0xFF0F172A)` | **Slate 900** — Tiêu đề AppBar, tên khóa học, giá bán chính, tên giảng viên. |
| `textBody` | `Color(0xFF334155)` | **Slate 700** — Nội dung văn bản mô tả, ghi chú bài học, nhãn form. |
| `textSecondary` | `Color(0xFF64748B)` | **Slate 500** — Thời lượng video, số lượng học viên, giá gốc gạch ngang, sub-label. |
| `textMuted` | `Color(0xFF94A3B8)` | **Slate 400** — Placeholder ô tìm kiếm, icon chưa active trên thanh điều hướng. |
| `borderColor` | `Color(0xFFE2E8F0)` | **Slate 200** — Đường kẻ phân cách (Divider), viền mỏng thẻ card, viền input. |
| `statusSuccess` | `Color(0xFF10B981)` | **Emerald** (Nền `0xFFECFDF5`) — Tích xanh bài học đã hoàn thành $\ge 80\%$, badge đã mua. |
| `statusWarning` | `Color(0xFFF59E0B)` | **Amber** (Nền `0xFFFFFBEB`) — Cụm sao đánh giá (1-5★), huy hiệu "Bán chạy", cảnh báo tiến độ. |
| `statusDanger` | `Color(0xFFEF4444)` | **Rose Red** (Nền `0xFFFEF2F2`) — Thông báo lỗi nhập form, coupon sai hạn, nút Đăng xuất. |

```dart
// Gợi ý định nghĩa hằng số màu trong lib/core/constants/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFF434CE8);
  static const Color primaryHover = Color(0xFF353EC4);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textHeading = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
```

---

### 2.2. Quy chuẩn Typography (Google Fonts: Plus Jakarta Sans)

Áp dụng gói `google_fonts: ^6.1.0` với phông chữ **Plus Jakarta Sans**.

| Kiểu chữ TextTheme | Size (sp) | Font Weight | Line Height | Ứng dụng thực tế trên Mobile |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | `28.0` | `FontWeight.w800` | `34.0` | Hero Title chào mừng, Màn hình Onboarding. |
| `headlineMedium` | `22.0` | `FontWeight.w700` | `28.0` | Tiêu đề phân mục trang chủ, Tên khóa học chi tiết. |
| `titleMedium` | `16.0` | `FontWeight.w600` | `22.0` | Tên thẻ khóa học, Tiêu đề chương học (Accordion). |
| `bodyLarge` | `15.0` | `FontWeight.w400` | `22.0` | Đoạn mô tả khóa học, bài học, giới thiệu giảng viên. |
| `bodyMedium` | `14.0` | `FontWeight.w500` | `20.0` | Nhãn Input Form, Tiêu đề bài học nhỏ, Text trong nút bấm. |
| `labelSmall` | `12.0` | `FontWeight.w600` | `16.0` | Huy hiệu (Badge), Thời lượng (12:40), Số sao đánh giá. |
| `captionTiny` | `10.0` | `FontWeight.w700` | `12.0` | Nhãn Bottom Nav Bar, Tag trạng thái mini. |

---

### 2.3. Quy chuẩn Bo góc & Đổ bóng (Border Radius & Elevation)

1. **Border Radius:**
   * `BorderRadius.circular(9999.0)`: Avatar tròn, Pill Badge, Chip chọn danh mục.
   * `BorderRadius.circular(12.0)`: Nút bấm (`ElevatedButton`), Ô nhập (`TextFormField`), Ô tìm kiếm.
   * `BorderRadius.circular(16.0)`: Thẻ khóa học (`CourseCard`), Container thống kê, Card giỏ hàng.
   * `BorderRadius.vertical(top: Radius.circular(24.0))`: Hộp thoại trượt từ dưới lên (`ModalBottomSheet`).
2. **Elevation / Box Shadow:**
   * Hạn chế dùng `elevation` gắt của Material cũ. Sử dụng `BoxShadow` mềm tương thích Design System:
   ```dart
   static final List<BoxShadow> cardShadow = [
     BoxShadow(
       color: const Color(0xFF0F172A).withOpacity(0.04),
       offset: const Offset(0, 4),
       blurRadius: 16,
       spreadRadius: -2,
     ),
   ];
   ```

---

## 3. CẤU TRÚC ĐIỀU HƯỚNG & CÁC LUỒNG MÀN HÌNH CHÍNH

### 3.1. Sơ đồ Cây Điều Hướng (Navigation Tree)

```text
[Khởi động: Splash Screen]
         │
         ▼
[Màn hình Onboarding 3 bước]
         │
         ▼
[Xác thực: Đăng nhập / Đăng ký] (pages/common/auth.html)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│               MAIN NAVIGATION: BOTTOM NAVBAR                │
├─────────────┬─────────────┬─────────────┬───────────────────┤
│   Tab 1:    │   Tab 2:    │   Tab 3:    │      Tab 4:       │
│  Trang chủ  │  Khám phá   │ Khóa học    │  Tài khoản cá nhân│
│   (Home)    │  (Search)   │  (Learning) │     (Profile)     │
└──────┬──────┴──────┬──────┴──────┬──────┴─────────┬─────────┘
       │             │             │                │
       ▼             ▼             ▼                ▼
[Chi tiết khóa] [Bộ lọc Filter] [Không gian học] [Đổi mật khẩu]
       │       (Bottom Sheet)  (Video Player)   [Lịch sử đơn]
       ▼                           │             [Đăng xuất Dialog]
[Giỏ hàng & Checkout]          [Đánh giá 5★]
(pages/learner/cart.html)      [Xem chứng chỉ]
```

---

### 3.2. Cấu trúc Thanh điều hướng đáy (Bottom Navigation Bar)
Cố định ở đáy màn hình với 4 Tab chức năng chính, chiều cao chuẩn `64dp` (chưa tính vùng Safe Area đáy):
1. **Trang chủ (`Home`):** Icon `Icons.home_rounded` — Màn hình trung tâm tổng hợp, gợi ý Top Match.
2. **Khám phá (`Explore`):** Icon `Icons.explore_rounded` — Danh mục, bộ lọc, tìm kiếm từ khóa kỹ năng.
3. **Khóa học của tôi (`My Courses`):** Icon `Icons.play_lesson_rounded` — Quản lý các khóa học đang sở hữu, tiếp tục học.
4. **Hồ sơ (`Profile`):** Icon `Icons.person_rounded` — Thông tin học viên, tiến độ hoàn thành, đăng xuất.

> **Lưu ý Giỏ hàng (`Cart`):** Đặt nút icon Giỏ hàng có Badge số lượng (`Badge(label: Text('2'))`) trên thanh `AppBar` ở góc trên bên phải của Trang chủ và Trang Khám phá để tiết kiệm không gian Bottom Bar.

---

## 4. ĐẶC TẢ CHI TIẾT CÁC MÀN HÌNH ỨNG DỤNG (SCREEN SPECS)

### 4.1. Nhóm Xác thực (Onboarding & Authentication)

#### 1. Onboarding Screen
* **Mục đích:** Tạo ấn tượng đầu tiên (First Impression) với hiệu ứng thị giác hiện đại.
* **Thành phần:**
  * PageView trượt 3 trang minh họa tính năng nổi bật:
    1. *Khám phá hàng ngàn khóa học chất lượng cao từ các chuyên gia hàng đầu.*
    2. *Học tập thông minh với thuật toán gợi ý khóa học cá nhân hóa (Collaborative Filtering).*
    3. *Theo dõi tiến độ trực quan, nhận chứng chỉ hoàn thành chuẩn quốc tế.*
  * Cụm chỉ báo trang (Page Indicator dạng viên thuốc bo tròn màu `#434CE8`).
  * Nút "Bắt đầu ngay" dẫn tới màn hình Đăng nhập.

#### 2. Màn hình Đăng nhập & Đăng ký ([auth.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/common/auth.html))
* **Đăng nhập:**
  * Form: Ô Email (`TextFormField`), Ô Mật khẩu có icon mắt ẩn/hiện (`obscureText`).
  * Nút "Đăng nhập" (Nền `#434CE8`, chiều cao 50dp, chữ trắng đậm).
  * Khối "Đăng nhập nhanh với Google" (Icon Google, viền mỏng Slate 200).
  * Liên kết "Quên mật khẩu?" mở Bottom Sheet nhập email nhận mã OTP.
* **Đăng ký (Quy trình 3 bước):**
  * *Bước 1:* Họ và tên, Email $\rightarrow$ Nút "Tiếp tục".
  * *Bước 2:* Ô nhập mã OTP 6 số (`Pinput` widget hoặc 6 ô ký tự riêng biệt) có đồng hồ đếm ngược 60s.
  * *Bước 3:* Mật khẩu & Xác nhận mật khẩu $\rightarrow$ Có thanh hiển thị độ mạnh mật khẩu (Yếu: Đỏ, Trung bình: Cam, Mạnh: Xanh lá).

---

### 4.2. Tab 1: Trang chủ Hệ thống (Home Screen)
*Mô phỏng từ [index.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/index-logged.html) của phân hệ Học viên.*

```text
┌─────────────────────────────────────────────────────────┐
│ [Avatar] Xin chào, Hải Yến 👋           [Search] [Cart: 2] │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ✨ LEARNING, MADE PERSONAL                          │ │
│ │ Nâng tầm kỹ năng nghề nghiệp của bạn                │ │
│ │ [Khám phá ngay →]                                  │ │
│ └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ GỢI Ý RIÊNG CHO BẠN (COLLABORATIVE FILTERING)            │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 🌟 YOUR TOP MATCH: 98% FIT                          │ │
│ │ [Ảnh 16:9] Machine Learning & Data Science với Python│ │
│ │ TS. Lê Hoàng Nam • 4.95 ★ (520)                     │ │
│ │ 1.190.000 đ  ~2.000.000 đ~          [Xem chi tiết] │ │
│ └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ DANH MỤC PHỔ BIẾN                                      │
│ [💻 Lập trình]  [🎨 UI/UX Design]  [🤖 AI/Data] [📢 MKT]│
├─────────────────────────────────────────────────────────┤
│ KHÓA HỌC BÁN CHẠY NHẤT 🔥               [Xem tất cả >] │
│ ┌───────────────┐ ┌───────────────┐                    │
│ │ [Ảnh 16:9]    │ │ [Ảnh 16:9]    │                    │
│ │ Web HTML/CSS  │ │ Figma UI/UX   │                    │
│ │ 699.000 đ     │ │ 849.000 đ     │                    │
│ └───────────────┘ └───────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

* **Khối Header:** Lời chào cá nhân hóa kèm Avatar tròn, nút kính lúp tìm kiếm và nút giỏ hàng có số lượng badge.
* **Khối Hero Banner:** Gradient chuyển tiếp từ `#1E1B4B` sang `#434CE8`, góc bo cong 20dp, tag trắng mờ.
* **Khối Recommendation ("Top Match"):** Card đặc biệt nổi bật với huy hiệu `✨ 98% Match`, minh họa trực tiếp thuật toán gợi ý của đề tài Khóa luận.
* **Khối Danh mục ngang (Horizontal Category List):** Danh sách các chip bo tròn có icon sinh động (`💻 Lập trình`, `🎨 UI/UX`, `🤖 AI/Data`).
* **Lưới Khóa học xu hướng (Top Trending):** Thẻ khóa học cuộn ngang (Horizontal ListView), hiển thị ảnh bìa 16:9 bo góc, badge "Bán chạy", tên khóa tối đa 2 dòng, rating kèm sao vàng `#F59E0B` và hàng giá tiền kép.

---

### 4.3. Tab 2: Khám phá & Tìm kiếm nâng cao (Explore Screen)
*Mô phỏng từ [courses.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/courses.html).*

* **Thanh tìm kiếm cố định (Sticky Search Bar):** Bo góc 12dp, nền xám nhạt `#F1F5F9`, tích hợp icon lọc ở đuôi ô tìm kiếm.
* **Từ khóa xu hướng (Trending Tags):** Cuộn ngang các từ khóa hot: `Flutter`, `Figma`, `Python AI`, `ReactJS`.
* **Bottom Sheet Bộ lọc (Filter Modal):**
  * Tiêu chí 1: Xếp hạng đánh giá (Checkbox từ 3.0★, 4.0★, 4.5★ trở lên).
  * Tiêu chí 2: Cấp độ học viên (Tất cả, Cơ bản, Trung cấp, Chuyên sâu).
  * Tiêu chí 3: Mức giá (Có Switch toggle: "Chỉ hiển thị khóa học Miễn phí").
  * Nút "Thiết lập lại" và Nút "Áp dụng bộ lọc" (Hiển thị số kết quả khớp).
* **Danh sách kết quả:** Dạng danh sách dọc (Vertical ListView), hiển thị card ngang gồm ảnh bìa 16:9 bên trái và thông tin giá/rating/thời lượng bên phải.
* **Trạng thái rỗng (Empty Search State):** Hình minh họa kính lúp xám, thông báo *"Không tìm thấy khóa học phù hợp"* kèm gợi ý từ khóa khác.

---

### 4.4. Màn hình Chi tiết Khóa học (Course Detail Screen)
*Mô phỏng từ [course-detail.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/course-detail.html).*

* **Vùng phát Video Trailer / Ảnh bìa (Header):**
  * Tỉ lệ 16:9 chuẩn, có nút Play tròn nổi bật ở giữa để mở video xem thử (Preview Mode).
  * Nút Back và Nút Chia sẻ (Share) dạng hình tròn mờ đè lên góc trên của ảnh bìa.
* **Vùng thông tin tổng quan:**
  * Tag danh mục màu tím nhạt, Tiêu đề khóa học to bản (`20sp/FontWeight.w700`).
  * Thông tin giảng viên (Avatar mini, Tên, Chức danh).
  * 3 Thẻ thống kê nhỏ (Metric Pills): Số bài học (VD: `45 bài`), Thời lượng (VD: `32 giờ`), Trình độ (VD: `Mọi cấp độ`).
* **Đề cương bài giảng dạng Accordion (`ExpansionTile`):**
  * Chia theo từng Chương (Chương 1, Chương 2, Chương 3...).
  * Từng bài học hiển thị tên bài, thời lượng (VD: `12:40`) và huy hiệu `[Xem thử]` (nếu bài học cho phép học thử miễn phí).
* **Khối Đánh giá & Nhận xét:** Điểm số trung bình to bản (VD: `4.9 / 5.0`), cụm 5 sao vàng và danh sách bình luận mới nhất của học viên.
* **Thanh thao tác cố định ở chân màn hình (Sticky Bottom Bar):**
  * Hiển thị giá tiền bên trái (Giá ưu đãi to màu tím `#434CE8`, giá gốc gạch ngang ở dưới).
  * Cụm nút bên phải: Nút Icon "Thêm vào giỏ" và Nút chính "Mua ngay" (Nếu là khóa miễn phí hiển thị nút to bản "Đăng ký học ngay").

---

### 4.5. Màn hình Giỏ hàng & Thanh toán (Cart & Checkout)
*Mô phỏng từ [cart-checkout.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/cart-checkout.html).*

* **Danh sách sản phẩm trong giỏ:** Card khóa học thu nhỏ kèm nút Xóa (Thùng rác đỏ).
* **Khung áp dụng Mã giảm giá (Coupon Section):**
  * Ô nhập mã chữ in hoa (VD: `CHAOMUNG2026`).
  * Nút "Áp dụng": Khi nhấn sẽ mô phỏng kiểm tra mã:
    * *Hợp lệ:* Hiện chữ xanh lá `-20% (-139.800 đ)`.
    * *Không hợp lệ / Hết hạn:* Báo viền đỏ và text lỗi *"Mã giảm giá không hợp lệ hoặc đã hết lượt dùng"*.
* **Bảng tính tiền chi tiết:** Tạm tính $\rightarrow$ Giảm giá khuyến mãi $\rightarrow$ Tổng thanh toán cuối cùng.
* **Chọn phương thức thanh toán:** Radio List chọn Ví MoMo, Cổng VNPay, Thẻ ATM Nội địa/Visa.
* **Nút "Xác nhận thanh toán":** Hiển thị loading spinner $\rightarrow$ Bật Dialog chúc mừng thành công kèm nút "Vào không gian học ngay".

---

### 4.6. Tab 3: Không gian Học tập & Video Player (Learning Space)
*Mô phỏng từ [learning-space.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/learning-space.html) (Màn hình quan trọng nhất về mặt kỹ thuật).*

```text
┌─────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────┐ │
│ │                    [▶ VIDEO PLAYER]                 │ │
│ │  [⏮ 10s]         [ ❚❚ Pause ]           [⏭ 10s]    │ │
│ │  05:20 ━━━━━━━━━━━●━━━━━━━━━━━━━━━ 12:40   [1.25x] [⛶]│
│ └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ Bài 1.2: Thiết lập Design System (Màu sắc, Typography) │
│ Tiến độ khóa học: 85% ████████████████░░░░             │
├─────────────────────────────────────────────────────────┤
│ [Danh sách bài học (45)]    [Tài liệu (3)]    [Hỏi đáp] │
├─────────────────────────────────────────────────────────┤
│ ▼ CHƯƠNG 1: TỔNG QUAN VÀ KHỞI TẠO (4 bài)              │
│   ✓ 1.1 Giới thiệu kiến trúc nền tảng          12:40   │
│   ► 1.2 Thiết lập Design System (Đang phát)    18:25   │
│   ○ 1.3 Tạo khung sườn HTML ngữ nghĩa          22:10   │
│   ○ 1.4 Xây dựng thẻ Course Card 16:9          21:50   │
│                                                         │
│ ► CHƯƠNG 2: XÂY DỰNG TRÌNH PHÁT VIDEO                  │
└─────────────────────────────────────────────────────────┘
```

* **Video Player Custom UI:**
  * Khung hình cố định tỉ lệ 16:9 (khi cầm dọc) và tự động Fullscreen Landscape khi xoay ngang máy.
  * Controls hiển thị khi chạm vào video: Nút Play/Pause, Tua lùi 10s, Tua tới 10s, Thanh Slider tua video.
  * Nút chọn tốc độ phát: `[0.75x, 1.0x, 1.25x, 1.5x, 2.0x]`.
* **Quy tắc Tích xanh hoàn thành (Theo Trigger T07 & CSDL):**
  * Khi người học xem đạt $\ge 80\%$ thời lượng bài giảng: Icon trạng thái tự động chuyển thành **Dấu tích xanh `#10B981`** kèm thông báo Toast nhẹ.
* **Cơ chế khôi phục mốc dừng (Resume Playback):**
  * Tự động lưu số giây xem gần nhất vào biến trạng thái. Khi mở lại bài học, tự động hỏi hoặc tiếp tục phát từ mốc đó.
* **Popup Đánh giá 5 sao (Theo Trigger T09 & UC6):**
  * Khi tổng tiến độ khóa học đạt $\ge 70\%$, hiển thị Modal Dialog chúc mừng và mời đánh giá.
  * Chọn từ 1 đến 5 sao (màu vàng `#F59E0B`), ô viết cảm nghĩ (tùy chọn) và nút "Gửi đánh giá".

---

### 4.7. Tab 3 (Phần 2): Khóa học của tôi & Chứng chỉ (My Learning & Certificate)
*Mô phỏng từ [my-learning.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/my-learning.html) & [certificate.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/learner/certificate.html).*

* **Tab Bar 2 mục:**
  * *Tab "Đang học":* Lưới các khóa học đã mua, hiển thị thanh tiến độ `%` kèm nút nổi bật **"Tiếp tục học"** (nhảy thẳng vào bài học đang dang dở).
  * *Tab "Đã hoàn thành":* Các khóa đạt `100%` tiến độ, hiển thị huy hiệu xanh lá kèm nút **"Xem chứng chỉ"**.
* **Màn hình Chứng chỉ tốt nghiệp (Certificate Viewer):**
  * Khung hiển thị mô phỏng bằng (Chứng nhận hoàn thành khóa học với viền hoa văn sang trọng, tên học viên in đậm, mã số xác thực QR/Code).
  * Nút hành động: "Tải chứng chỉ về máy (PDF/Ảnh)" và "Chia sẻ lên mạng xã hội".

---

### 4.8. Tab 4: Hồ sơ cá nhân & Cài đặt (Profile Screen)
*Mô phỏng từ [profile.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/common/profile.html).*

* **Khối Header:** Avatar to bản có icon máy ảnh để đổi ảnh, Họ tên, Email, Badge vai trò `Học viên`.
* **Danh sách tùy chọn (ListTile Settings):**
  * *Chỉnh sửa thông tin cá nhân* (Họ tên, ngày sinh, số điện thoại, giới tính).
  * *Đổi mật khẩu* (Mật khẩu cũ, mật khẩu mới có kiểm tra bảo mật).
  * *Lịch sử đơn hàng & Hóa đơn*.
  * *Cài đặt thông báo & Chế độ nền tối (Dark mode placeholder)*.
  * *Điều khoản sử dụng & Trợ giúp*.
* **Nút Đăng xuất ([logout-demo.html](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/pages/common/logout-demo.html)):**
  * Text đỏ `#EF4444`, khi bấm sẽ mở **AlertDialog** xác nhận: *"Bạn có chắc chắn muốn kết thúc phiên làm việc?"* $\rightarrow$ Nút Hủy và Nút Đăng xuất.

---

## 5. RÀNG BUỘC KỸ THUẬT & TRẢI NGHIỆM MOBILE (UX CONSTRAINTS)

1. **Vùng an toàn màn hình (Safe Area Management):**
   * Mọi màn hình phải được bao bọc bởi widget `SafeArea` hoặc tự xử lý `MediaQuery.of(context).padding` để tránh bị tai thỏ (Notch), Dynamic Island hoặc thanh cử chỉ đáy (Home Indicator) che lấp nội dung.
2. **Kích thước vùng chạm tối thiểu (Touch Target):**
   * Tất cả icon tương tác, nút bấm, checkbox, radio phải có kích thước vùng chạm tối thiểu **$48 \times 48\text{ dp}$** (theo tiêu chuẩn Material 3 & Apple Human Interface Guidelines).
3. **Tránh lỗi tràn màn hình khi bật bàn phím (Keyboard Overflow):**
   * Các màn hình chứa Form nhập liệu (Đăng nhập, Đăng ký, Đổi mật khẩu, Tìm kiếm) bắt buộc bọc trong `SingleChildScrollView` với thuộc tính `physics: ClampingScrollPhysics()` hoặc `BouncingScrollPhysics()`.
4. **Phản hồi rung nhẹ (Haptic Feedback):**
   * Kích hoạt `HapticFeedback.lightImpact()` khi học viên bấm nút Thêm giỏ hàng, chấm sao đánh giá hoặc khi video đạt mốc tích xanh $\ge 80\%$.
5. **Xử lý trạng thái tải & Rỗng (Loading & Empty States):**
   * Tuyệt đối không để màn hình trắng khi tải danh sách. Sử dụng khung hiệu ứng tải xương xám nhẹ (Shimmer / Skeleton loading) theo đúng hình dạng thẻ khóa học.
   * Tất cả các màn hình tìm kiếm, giỏ hàng, khóa học của tôi đều phải có UI Empty State đẹp mắt, có nút CTA dẫn về trang chủ.

---

## 6. CẤU TRÚC THƯ MỤC DỰ ÁN FLUTTER ĐỀ XUẤT

Tổ chức mã nguồn theo chuẩn **Feature-First / Clean Architecture thu gọn** để nhóm dễ dàng phân chia công việc mà không bị xung đột (conflict):

```text
my_elearning_app/
├── assets/
│   ├── icons/                 # Các SVG/PNG icon nếu có
│   └── images/                # Mock banner, placeholder, certificate background
│
├── lib/
│   ├── core/                  # Cấu hình dùng chung toàn app
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Bảng mã màu chuẩn Design System
│   │   │   ├── app_typography.dart    # Cấu hình Plus Jakarta Sans TextTheme
│   │   │   └── app_dimens.dart        # Padding, margin, corner radii
│   │   ├── theme/
│   │   │   └── app_theme.dart         # ThemeData chuẩn Material 3
│   │   └── utils/
│   │       └── formatters.dart        # Định dạng tiền tệ VNĐ, thời lượng video
│   │
│   ├── data/                  # Nguồn dữ liệu tĩnh (Mock Data)
│   │   ├── models/            # Course, Lesson, Category, User, Coupon
│   │   └── mock_data.dart     # Chuyển hóa toàn bộ mockData từ assets/js/data.js sang Dart
│   │
│   ├── presentation/          # Toàn bộ giao diện người dùng
│   │   ├── widgets/           # Widgets dùng lại nhiều nơi
│   │   │   ├── app_button.dart        # Nút bấm chuẩn #434CE8
│   │   │   ├── course_card.dart       # Card khóa học chuẩn 16:9
│   │   │   ├── rating_stars.dart      # Cụm sao đánh giá vàng #F59E0B
│   │   │   └── custom_app_bar.dart    # AppBar đồng bộ
│   │   │
│   │   └── screens/           # Các màn hình theo từng phân hệ
│   │       ├── splash/                # Splash & Onboarding
│   │       ├── auth/                  # Login, Register OTP, Forgot Password
│   │       ├── main_navigation.dart   # Bottom Navigation Bar (Shell)
│   │       ├── home/                  # Tab 1: Trang chủ & Top Match CF
│   │       ├── explore/               # Tab 2: Khám phá, Tìm kiếm, Bottom Sheet Lọc
│   │       ├── course_detail/         # Chi tiết khóa học & Video Preview
│   │       ├── cart/                  # Giỏ hàng, Áp dụng mã Coupon, Thanh toán
│   │       ├── learning/              # Không gian học: Video Player, Tích xanh, Popup Đánh giá
│   │       ├── my_courses/            # Tab 3: Khóa học của tôi & Chứng chỉ PDF
│   │       └── profile/               # Tab 4: Hồ sơ cá nhân, Đổi mật khẩu, Đăng xuất
│   │
│   └── main.dart              # Khởi tạo App & Thiết lập ThemeData
│
└── pubspec.yaml               # google_fonts, flutter_svg, pinput, video_player (nếu có)
```

---

## 7. MÔ HÌNH DỮ LIỆU GIẢ LẬP (DART MOCK DATA MODELS)

Để chuyển thể từ file JavaScript hiện tại ([data.js](file:///d:/Nam4_DH/KLTN/Tuan04/UI-Desgin-Project_Ver3/UI-Desgin-Project/assets/js/data.js)) sang Dart, các lớp Model tĩnh cần được xây dựng như sau:

```dart
// 1. Model Khóa học
class Course {
  final String id;
  final String title;
  final String category;
  final String instructor;
  final double rating;
  final int reviewCount;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final String tag;
  final String level;
  final String duration;
  final int lessonsCount;
  final double progress; // 0 - 100
  final bool isEnrolled;
  final bool isCompleted;

  Course({
    required this.id,
    required this.title,
    required this.category,
    required this.instructor,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.tag,
    required this.level,
    required this.duration,
    required this.lessonsCount,
    this.progress = 0,
    this.isEnrolled = false,
    this.isCompleted = false,
  });
}

// 2. Model Bài học & Video
class Lesson {
  final String id;
  final String title;
  final String duration; // "12:40"
  bool isCompleted;      // Tích xanh khi xem >= 80%
  final bool isFree;     // Cho xem thử Preview
  bool isCurrent;        // Đang phát

  Lesson({
    required this.id,
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.isFree = false,
    this.isCurrent = false,
  });
}
```

---

## 8. BỘ QUY TẮC NGHIỆM THU GIAO DIỆN (ACCEPTANCE CHECKLIST)

Khi các thành viên trong nhóm thực hiện code màn hình, cần đối chiếu với các tiêu chí nghiệm thu bắt buộc sau:

* [ ] **Nhận diện màu sắc:** Màu chủ đạo bắt buộc là `#434CE8` (Electric Indigo), nền toàn trang là `#F8FAFC`, thẻ màu trắng `#FFFFFF` bo góc mềm.
* [ ] **Phông chữ:** Đã tích hợp Google Font `Plus Jakarta Sans`, không dùng phông mặc định của thiết bị, hiển thị tiếng Việt hoàn hảo không lỗi dấu.
* [ ] **Responsive:** Đã kiểm tra giao diện trên cả màn hình nhỏ (iPhone SE/màn hình 4.7 inch) và màn hình lớn (iPhone 15 Pro Max/Android 6.7 inch) không bị lỗi tràn pixel vàng-đen (`A RenderFlex overflowed`).
* [ ] **Quy tắc Video $\ge 80\%$:** Khi bấm tua hoặc xem hết 80% thời lượng bài giảng, trạng thái bài học phải tự chuyển sang icon tích xanh `#10B981`.
* [ ] **Quy tắc Đánh giá $\ge 70\%$:** Có cơ chế bật Popup Dialog đánh giá 5 sao kèm các ngôi sao màu vàng cam `#F59E0B`.
* [ ] **Quy tắc Gợi ý cá nhân hóa (CF):** Trên trang chủ phải thể hiện rõ khối "Khóa học dành riêng cho bạn" kèm huy hiệu nổi bật `YOUR TOP MATCH: 98% FIT`.
* [ ] **Bottom Bar:** Chuyển đổi qua lại giữa các Tab mượt mà, giữ được trạng thái cuộn của từng trang.

---

> *Tài liệu này được lập ra nhằm thống nhất quy chuẩn giữa các thành viên lập trình ứng dụng di động Flutter, bảo đảm đồng bộ hoàn toàn với bản Web và bản báo cáo đồ án Khóa luận Tốt nghiệp KLCN044.*
