# Quảng cáo popup ưu đãi: API dùng chung với website

Backend: `Controllers/Api/CouponApiController.cs` (repo web). Cần chạy migration `023_QuangCaoPopup.sql` trên CSDL trước.
App: `PromoAdRepository`, `PromoAdPresenter` (popup trang chủ), `PromoAdScreen` (trang ưu đãi).

| API | Token | Mô tả |
|---|---|---|
| `GET /api/v1/ads` | tùy chọn | Ảnh quảng cáo đang chạy: `items[] { type, id, title, imageUrl, expiresAt }`. `type` = `campaign` hoặc `promotion`. Ưu đãi thân thiết chỉ có khi đã đăng nhập và đủ điều kiện. |
| `GET /api/v1/ads/{type}/{id}` | tùy chọn | Trang ưu đãi: `title, description, imageUrl, startsAt, endsAt, offers[]`. 404 `OFFER_NOT_FOUND` khi hết hiệu lực. |
| `GET /api/v1/coupons/loyalty-popup` | bắt buộc | Popup ưu đãi thân thiết: `show`, `kind` (`eligible`), `promotionId`, `code`, `title`, `discountText`, `note`, `description`, `conditions[]`, `expiresAt`. Chỉ `show = true` khi học viên đã đủ điều kiện. |
| `POST /api/v1/coupons/{code}/save` | bắt buộc | Lưu mã vào ví (đã có). |

`offers[]`: `id, title, discountText, note, conditions[], expiresAt, isDirectDiscount, isLoyalty, code, canSave, saved, message, appliesToAll, totalCourses, courses[]`.
`courses[]` cùng cấu trúc thẻ khóa học của catalog (`price` là giá đã giảm, `originalPrice` là giá gốc, `promotion`).
`code` là `null` với giảm trực tiếp (không có mã) và với ưu đãi thân thiết mà người dùng chưa đủ điều kiện; khi đó `message` giải thích.

## Quy tắc hiển thị (giống web)

1. Mỗi lượt truy cập (mở app, đăng nhập / đăng xuất) hiện **một** ảnh chưa xem. Đóng bằng dấu X; bấm ảnh hoặc "Xem ưu đãi" mở trang ưu đãi.
2. Hết ảnh để chiếu mới tới popup ưu đãi thân thiết (người đã đủ điều kiện): mỗi ngày một lần, có "Không hiện lại" (lưu `SharedPreferences`).
3. Lỗi mạng hoặc API chưa triển khai thì im lặng bỏ qua, không ảnh hưởng trang chủ.
