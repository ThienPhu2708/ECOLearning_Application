# Quiz trên app — cập nhật dùng chung với web

App đã ghép `origin/thu` commit `fb9ea90` (popup quảng cáo) vào nhánh local `ngoc`, giữ các sửa đổi quiz trước đó.

## Chức năng học viên

- Báo lỗi ngay tại câu hỏi, xem phản hồi của giáo viên.
- Phúc khảo một lần cho mỗi khóa học; xem lịch sử phản hồi và thông báo điều chỉnh điểm.
- Xem yêu cầu làm lại, mở/tiếp tục bài làm lại và xem lịch sử từng lượt.
- Xem ngưỡng kỹ năng trước khi thi và kết quả từng kỹ năng sau khi được công nhận.
- Rời ứng dụng từ 3 lần: kết quả chờ giáo viên xem xét, khóa nhận chứng chỉ.
- Lượt được yêu cầu làm lại thay thế kết quả cũ. Kết quả hết hiệu lực không được dùng để nhận chứng chỉ.
- Ba tab khóa học độc lập: Đang học, Đã học đủ bài, Đã nhận chứng chỉ.
- Giữ đáp án/thời gian khi quay lại; xác nhận rõ trước khi chuyển quyền sửa từ phiên khác.

Giáo viên tiếp tục biên soạn câu hỏi, nhập Excel, cấu hình ma trận, xử lý báo lỗi/phúc khảo và duyệt kết quả trên web.

## Backend cần triển khai

Các API bổ sung nằm trong repo web, nhánh `ngoc`:
`Controllers/Api/QuizApiController.cs` và `Controllers/Api/LearningApiController.cs`.
Phải publish bản API này lên cùng máy chủ app sử dụng (`https://ecolearning.runasp.net`). Chỉ sửa Flutter không tạo được endpoint trên máy chủ.
Database máy chủ cần đủ migration 024–031 theo thứ tự; đợt nối app này không thêm migration mới.

Tất cả endpoint bên dưới có tiền tố `/api/v1`, dùng `Authorization: Bearer <token>` và khung JSON `{success,message,data}` hiện có.

| Method | Đường dẫn | Nội dung |
|---|---|---|
| GET | `/courses/{id}/quiz` | Có `supportsQuizReview`, `pendingReview`, `retakeRequired`, `skillMatrix` |
| POST | `/courses/{id}/quiz/start` | Nhận `clientKey`, `takeover`; trả `writerToken`, ID câu hỏi và nhật ký đã ghi nhận |
| GET | `/courses/{id}/quiz/history` | Lịch sử riêng của học viên |
| POST | `/quiz-attempts/{attemptId}/resume` | Chỉ tiếp tục lượt hiện có, không tạo lượt mới khi bài đã hết giờ |
| GET | `/quiz-attempts/{attemptId}/result` | Kết quả hiện hành; không lộ đáp án khi chờ duyệt/hết hiệu lực |
| POST | `/quiz-attempts/{attemptId}/reports` | `questionId`, `reason`, `content` |
| POST | `/courses/{id}/quiz/appeals` | `attemptId`, `content` |
| GET | `/courses/{id}/quiz/support` | Báo lỗi, phúc khảo, phản hồi, yêu cầu làm lại, điều chỉnh điểm |
| POST | `/courses/{id}/quiz/retakes/{reviewId}/start` | `clientKey`, `takeover`; cấp token cho lượt làm lại |
| POST | `/quiz-attempts/{attemptId}/visibility` | `writerToken`, `eventKey` GUID, `returned`; trả số lần ghi nhận |
| POST | `/quiz-attempts/{attemptId}/writer/check` | `writerToken`; kiểm tra phiên còn quyền sửa |
| GET | `/my-courses?status=certified&separateCertificates=true` | Tab đã nhận chứng chỉ; app mới gửi `separateCertificates=true` để `completed` chỉ giữ khóa đủ bài chưa có chứng chỉ. Bản app cũ không gửi cờ này vẫn giữ hành vi trước đây |

`inactive/paused/hidden` của cùng một lần rời app dùng chung một eventKey; `resumed` gửi lần quay lại cùng key. Lỗi gửi nhật ký được giữ để thử lại trước khi nộp. Chỉ ghi nhận các tín hiệu app gửi được; không xác định ứng dụng khác đã mở hay tự kết luận gian lận.

Kết quả `pendingReview=true` hoặc `isVoided=true` không được hiển thị là đạt, không có nút nhận chứng chỉ.

## Kiểm tra

- `flutter analyze --no-pub`
- `flutter test --no-pub`
- Repo web: `Tests/Run-QuizMobileApiTests.ps1` (tạo fixture riêng, tự dọn sau kiểm thử).
- Trên thiết bị: bắt đầu bài, chuyển app rồi quay lại 3 lần, nộp, kiểm tra chờ duyệt. Giáo viên duyệt trên web; app cập nhật kết quả khi tải lại/quay về hoặc sau chu kỳ kiểm tra.
- Gửi báo lỗi và phúc khảo, giáo viên phản hồi trên web, mở trang Phản hồi & yêu cầu quiz trên app để đối chiếu.
