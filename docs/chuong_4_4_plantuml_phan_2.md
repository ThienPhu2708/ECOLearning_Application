# Mã PlantUML chương 4.4 — Phần 2

Gồm chức năng 4.4.10 đến 4.4.18; mỗi chức năng có một sơ đồ lớp và một sơ đồ tuần tự. Sao chép từng khối từ @startuml đến @enduml vào PlantUML. Các sơ đồ bổ sung là khung tổng quan và cần đối chiếu mã trước khi đưa vào báo cáo; tên giao diện trong sơ đồ là cách biểu diễn.

## 4.4.10. Thảo luận bài học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Thảo luận bài học - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "LessonDiscussionController" as C <<controller>> {
    +Get(...)
    +Create(...)
    +ToggleLike(...)
  }
  class "LessonDiscussionService" as S <<service>>
}
package "Dữ liệu" {
  class "ThaoLuanBaiHoc" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C --> S
S ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Thảo luận bài học - Sơ đồ tuần tự
actor "Học viên / giáo viên" as A
boundary "Giao diện website" as UI
control "LessonDiscussionController" as C
control "LessonDiscussionService" as S
database "CSDL SQL Server" as DB
A -> UI: Mở thảo luận, gửi nội dung hoặc chọn thích
UI -> C: Yêu cầu chức năng
C -> S: lấy và lưu thảo luận
S -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> S: Kết quả
S --> C: Kết quả xử lý
note over C: Kiểm tra quyền truy cập và nội dung trước khi lưu
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Không có quyền hoặc nội dung không hợp lệ
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.11. Làm bài kiểm tra và nhận chứng chỉ

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Làm bài kiểm tra và nhận chứng chỉ - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "QuizController" as C <<controller>> {
    +Index(...)
    +Start(...)
    +Submit(...)
    +ClaimCertificate(...)
  }
  class "QuizService" as S <<service>>
}
package "Dữ liệu" {
  class "QuizAttempt" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C --> S
S ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Làm bài kiểm tra và nhận chứng chỉ - Sơ đồ tuần tự
actor "Học viên" as A
boundary "Giao diện website" as UI
control "QuizController" as C
control "QuizService" as S
database "CSDL SQL Server" as DB
A -> UI: Bắt đầu làm bài, nộp bài và yêu cầu nhận chứng chỉ
UI -> C: Yêu cầu chức năng
C -> S: kiểm tra điều kiện, lưu lượt làm và cấp chứng chỉ
S -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> S: Kết quả
S --> C: Kết quả xử lý
note over C: Kiểm tra điều kiện, chấm điểm và xét cấp chứng chỉ
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Chưa đủ điều kiện hoặc lượt làm không hợp lệ
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.12. Đánh giá khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Đánh giá khóa học - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "ReviewController" as C <<controller>> {
    +SubmitReview(...)
    +GetCourseReviews(...)
    +Helpful(...)
    +Reply(...)
  }
  class "CourseReviewService" as S <<service>>
}
package "Dữ liệu" {
  class "DanhGiaKhoaHoc" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C --> S
S ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Đánh giá khóa học - Sơ đồ tuần tự
actor "Học viên" as A
boundary "Giao diện website" as UI
control "ReviewController" as C
control "CourseReviewService" as S
database "CSDL SQL Server" as DB
A -> UI: Chọn số sao, nhập nội dung hoặc xem đánh giá
UI -> C: Yêu cầu chức năng
C -> S: xử lý dữ liệu đánh giá
S -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> S: Kết quả
S --> C: Kết quả xử lý
note over C: Kiểm tra quyền và dữ liệu rồi xử lý đánh giá
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Chưa đủ điều kiện hoặc dữ liệu đánh giá không hợp lệ
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.13. Giáo viên quản lý bài kiểm tra

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Giáo viên quản lý bài kiểm tra - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "InstructorQuizController" as C <<controller>> {
    +Edit(...)
    +Configure(...)
    +Preview(...)
    +Results(...)
  }
  class "QuizService" as S <<service>>
}
package "Dữ liệu" {
  class "QuizConfig" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C --> S
S ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Giáo viên quản lý bài kiểm tra - Sơ đồ tuần tự
actor "Giáo viên" as A
boundary "Giao diện website" as UI
control "InstructorQuizController" as C
control "QuizService" as S
database "CSDL SQL Server" as DB
A -> UI: Tạo câu hỏi, cấu hình và xem kết quả quiz
UI -> C: Yêu cầu chức năng
C -> S: lưu câu hỏi và cấu hình quiz
S -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> S: Kết quả
S --> C: Kết quả xử lý
note over C: Kiểm tra quyền sở hữu, dữ liệu và lưu cấu hình
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Không có quyền hoặc nội dung cấu hình không hợp lệ
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.14. Giáo viên yêu cầu nhận doanh thu

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Giáo viên yêu cầu nhận doanh thu - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "PayoutController" as C <<controller>> {
    +Index(...)
    +UpdatePaymentInfo(...)
    +RequestPayout(...)
  }
}
package "Dữ liệu" {
  class "NhanThanhToan" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Giáo viên yêu cầu nhận doanh thu - Sơ đồ tuần tự
actor "Giáo viên" as A
boundary "Giao diện website" as UI
control "PayoutController" as C
database "CSDL SQL Server" as DB
A -> UI: Xem số dư, cập nhật tài khoản và gửi yêu cầu
UI -> C: Yêu cầu chức năng
C -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> C: Kết quả
note over C: Kiểm tra thông tin, số tiền và tạo yêu cầu chi trả
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Thông tin nhận tiền hoặc số tiền không hợp lệ
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.15. Quản trị viên xử lý yêu cầu chi trả

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Quản trị viên xử lý yêu cầu chi trả - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "PayoutRequestController" as C <<controller>> {
    +Index(...)
    +Approve(...)
    +Reject(...)
  }
}
package "Dữ liệu" {
  class "NhanThanhToan" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Quản trị viên xử lý yêu cầu chi trả - Sơ đồ tuần tự
actor "Quản trị viên" as A
boundary "Giao diện website" as UI
control "PayoutRequestController" as C
database "CSDL SQL Server" as DB
A -> UI: Xem và duyệt hoặc từ chối yêu cầu chi trả
UI -> C: Yêu cầu chức năng
C -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> C: Kết quả
note over C: Kiểm tra trạng thái, ghi nhận kết quả thử nghiệm hoặc lý do
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Yêu cầu không hợp lệ hoặc đã được xử lý
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.16. Duyệt đăng ký giáo viên

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Duyệt đăng ký giáo viên - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "TeacherApprovalController" as C <<controller>> {
    +Index(...)
    +Review(...)
    +Approve(...)
    +Reject(...)
  }
  class "TeacherApplicationService" as S <<service>>
}
package "Dữ liệu" {
  class "TeacherApplication" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C --> S
S ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Duyệt đăng ký giáo viên - Sơ đồ tuần tự
actor "Quản trị viên" as A
boundary "Giao diện website" as UI
control "TeacherApprovalController" as C
control "TeacherApplicationService" as S
database "CSDL SQL Server" as DB
A -> UI: Xem hồ sơ, phê duyệt hoặc từ chối
UI -> C: Yêu cầu chức năng
C -> S: xử lý hồ sơ đăng ký giáo viên
S -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> S: Kết quả
S --> C: Kết quả xử lý
note over C: Kiểm tra hồ sơ và ghi nhận quyết định
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Hồ sơ không hợp lệ hoặc không còn chờ duyệt
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.17. Quản lý người dùng

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Quản lý người dùng - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "AdminUserController" as C <<controller>> {
    +Index(...)
    +Details(...)
    +Lock(...)
    +Unlock(...)
    +Warn(...)
  }
  class "AdminUserQueryService" as S <<service>>
}
package "Dữ liệu" {
  class "NguoiDung" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C --> S
S ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Quản lý người dùng - Sơ đồ tuần tự
actor "Quản trị viên" as A
boundary "Giao diện website" as UI
control "AdminUserController" as C
control "AdminUserQueryService" as S
database "CSDL SQL Server" as DB
A -> UI: Tìm, xem và xử lý tài khoản
UI -> C: Yêu cầu chức năng
C -> S: truy vấn dữ liệu người dùng
S -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> S: Kết quả
S --> C: Kết quả xử lý
note over C: Kiểm tra quyền quản trị và yêu cầu xử lý
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Tài khoản hoặc yêu cầu xử lý không hợp lệ
  UI --> A: Hiển thị thông báo
end
@enduml
```

## 4.4.18. Quản lý danh mục khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Quản lý danh mục khóa học - Sơ đồ lớp
left to right direction
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam classAttributeIconSize 0
skinparam linetype ortho
skinparam nodesep 35
skinparam ranksep 55
skinparam class {
  BackgroundColor white
  BorderColor black
  ArrowColor black
  FontSize 12
}
package "Giao diện" {
  class "Giao diện chức năng" as BoundaryUI <<boundary>>
}
package "Xử lý" {
  class "AdminCategoryController" as C <<controller>> {
    +Index(...)
    +Create(...)
    +Edit(...)
    +SetStatus(...)
    +Delete(...)
  }
}
package "Dữ liệu" {
  class "DanhMuc" as E <<entity / dữ liệu>>
}
BoundaryUI --> C
C ..> E
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Quản lý danh mục khóa học - Sơ đồ tuần tự
actor "Quản trị viên" as A
boundary "Giao diện website" as UI
control "AdminCategoryController" as C
database "CSDL SQL Server" as DB
A -> UI: Xem, tạo, sửa hoặc thay đổi trạng thái danh mục
UI -> C: Yêu cầu chức năng
C -> DB: Tra cứu / cập nhật dữ liệu liên quan
DB --> C: Kết quả
note over C: Kiểm tra dữ liệu và điều kiện trước khi lưu
alt Hợp lệ
  C --> UI: Hiển thị kết quả
  UI --> A: Thông tin / trạng thái cập nhật
else Không hợp lệ
  C --> UI: Thông báo: Thông tin không hợp lệ hoặc danh mục không thể xóa
  UI --> A: Hiển thị thông báo
end
@enduml
```
