# Chat học viên – giáo viên

## Mở trên app

- Vào bài học → **Hỏi giáo viên**. Video tạm dừng khi mở hội thoại.
- Hồ sơ → **Tin nhắn của tôi** để xem các hội thoại, tìm theo người nhắn/khóa học và lọc chưa đọc.
- Hỗ trợ chữ, biểu cảm, ảnh JPG/PNG, xem ảnh lớn, thu hồi trong 5 phút và báo cáo hội thoại.
- Khóa học/hội thoại bị khóa sẽ chỉ cho xem; máy chủ vẫn quyết định quyền gửi và thu hồi.

## Kết nối

`TeacherChatRepository` gọi `/api/v1/chat`, dùng `ApiClient` với Bearer token đăng nhập chung.
Ảnh được tải qua API riêng tư theo mã tin nhắn. Không gắn token vào URL, không gửi token sang redirect và không lưu ảnh chat vào cache trên đĩa.

Hội thoại kiểm tra tin mới mỗi 5 giây; danh sách và số chưa đọc kiểm tra mỗi 15 giây.
Không kiểm tra khi app chạy nền hoặc màn hình khác đang che màn chat. Không có push notification khi app đã tắt.
Nội dung chưa gửi vẫn giữ khi lỗi mạng trong lúc màn chat còn mở; không lưu bản nháp khi đóng app.

## Backend

Đã ghép `origin/phu` commit `23c1f79` vào web `ngoc`. Backend dùng bảng `HoiThoai` và `TinNhan` của migration `024_Chat_HoiThoai_TinNhan.sql`; không thêm bảng mới cho phần app.
Máy chủ cần publish `ChatApiController` và các thay đổi `ChatService` tương ứng.

## Kiểm tra

```powershell
flutter analyze --no-pub
flutter test --no-pub test/teacher_chat_test.dart
```

Kiểm tra thực tế: đăng nhập học viên đã ghi danh → gửi câu hỏi/ảnh trên app → giáo viên trả lời trên web → kiểm tra số chưa đọc và mở lại hội thoại trên app.
Các bài kiểm tra tự động dùng API giả lập; không gửi tin vào tài khoản thật.
