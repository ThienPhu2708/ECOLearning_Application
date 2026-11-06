# Mã PlantUML chương 4.4 — Phần 1

Gồm chức năng 4.4.1 đến 4.4.9; mỗi chức năng có một sơ đồ lớp và một sơ đồ tuần tự. Sao chép từng khối từ @startuml đến @enduml vào PlantUML. Các sơ đồ bổ sung là khung tổng quan và cần đối chiếu mã trước khi đưa vào báo cáo; tên giao diện trong sơ đồ là cách biểu diễn.

## 4.4.1. Thiết kế chức năng tìm mua khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Sơ đồ lớp thiết kế - Tìm mua khóa học
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
  class SearchController <<controller>> {
    +Index(q, danhMuc, capDo, gia, diem, sapXep, trang): ActionResult
  }
  class SearchService <<service>> {
    +TimKiem(f, userId): TimKiemViewModel
  }
  class CourseController <<controller>> {
    +Details(id: string): ActionResult
    +EnrollFree(courseId: string): ActionResult
  }
  class CartController <<controller>> {
    +AddToCart(courseId: string): JsonResult
    +ApplyCoupon(couponCode: string): JsonResult
    +Checkout(paymentMethod: string, couponCode: string): JsonResult
  }
  class PaymentController <<controller>> {
    +Gateway(orderId: string): ActionResult
    +VnpayReturn(): ActionResult
    +Pay(orderId: string, outcome: string): ActionResult
  }
  class PromotionService <<service>> {
    +KiemTraCoupon(...)
  }
  class PaymentService <<service>> {
    +GhiNhanKetQua(...)
    +XacNhanDonMienPhi(maDonHang: string): void
  }
  class VnPayService <<service>> {
    +TaoUrlThanhToan(...)
    +XuLyKetQua(...)
  }
}
package "Dữ liệu" {
  class KhoaHoc <<entity>> {
    maKhoaHoc: string
    tenKhoaHoc: string
    giaBan: decimal
    trangThai: string
  }
  class DonHang <<entity>> {
    maDonHang: string
    tongTien: decimal
    trangThai: string
  }
  class ChiTietDonHang <<entity>> {
    maChiTiet: string
    donGia: decimal
  }
  class DangKyKhoaHoc <<entity>> {
    maDangKy: string
    maHocVien: int
    maKhoaHoc: string
  }
}
BoundaryUI --> SearchController
SearchController --> SearchService
SearchService ..> KhoaHoc
CourseController ..> KhoaHoc
CourseController ..> DangKyKhoaHoc
CartController --> PromotionService
CartController --> PaymentService
CartController ..> KhoaHoc
CartController ..> DonHang
CartController ..> ChiTietDonHang
PaymentController --> PaymentService
PaymentController --> VnPayService
PaymentService ..> DonHang
PaymentService ..> DangKyKhoaHoc : ghi nhận qua CSDL
DonHang "1" -- "0..*" ChiTietDonHang
KhoaHoc "1" -- "0..*" ChiTietDonHang
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Tìm kiếm và mua khóa học
actor "Học viên" as A
boundary "Giao diện" as UI
control SearchController as SC
control CartController as CC
control PaymentController as PC
database "CSDL" as DB
A -> UI: Nhập từ khóa
UI -> SC: Index(...)
SC --> UI: Danh sách khóa học
A -> UI: Chọn khóa và thêm vào giỏ
UI -> CC: AddToCart(courseId)
A -> UI: Xác nhận mua
UI -> CC: Checkout(paymentMethod, couponCode)
CC -> DB: Kiểm tra và tạo đơn
DB --> CC: Kết quả tạo đơn
alt Đơn cần thanh toán
  CC --> UI: Thông tin chuyển đến cổng
  UI -> PC: Gateway(orderId)
  PC --> UI: Hiển thị cổng thử nghiệm
else Tổng tiền bằng 0
  CC --> UI: Ghi nhận kết quả ghi danh
end
@enduml
```

## 4.4.2. Thiết kế chức năng tạo và quản lý khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Sơ đồ lớp thiết kế - Tạo và quản lý khóa học
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
  class InstructorCourseController as IC <<controller>> {
    +Index(search, status): ActionResult
    +Create(model, actionType): ActionResult
    +Edit(model, actionType): ActionResult
    +SubmitForApproval(id: string): ActionResult
    +Pause(id: string): ActionResult
    +Resume(id: string): ActionResult
    +Delete(id: string): ActionResult
  }
  class CourseContentService <<service>> {
    +KiemTraKhoaHoc(maKhoaHoc)
  }
  class CourseRevisionService <<service>> {
    +Get(courseId)
    +Save(...)
  }
  class CourseLifecycleService <<service>> {
    +TamNgung(maKhoaHoc, maGiaoVien)
    +MoBanLai(maKhoaHoc, maGiaoVien)
    +Xoa(maKhoaHoc, maGiaoVien)
  }
  class TeacherSpecialtyService <<service>> {
    +Require(...)
  }
}
package "Dữ liệu" {
  class KhoaHoc <<entity>> {
    maKhoaHoc: string
    tenKhoaHoc: string
    maGiaoVien: int
    trangThai: string
  }
  class ChuongHoc <<entity>> {
    maChuong: string
    tenChuong: string
    maKhoaHoc: string
  }
  class BaiHoc <<entity>> {
    maBaiHoc: string
    tenBaiHoc: string
    maChuong: string
  }
  class KiemDuyetKhoaHoc <<entity>> {
    maKiemDuyet: string
    maKhoaHoc: string
    trangThai: string
  }
}
BoundaryUI --> IC
IC --> TeacherSpecialtyService
IC --> CourseContentService
IC --> CourseRevisionService
IC --> CourseLifecycleService
IC ..> KhoaHoc
IC ..> KiemDuyetKhoaHoc
CourseContentService ..> ChuongHoc
CourseContentService ..> BaiHoc
KhoaHoc "1" -- "0..*" ChuongHoc
ChuongHoc "1" -- "0..*" BaiHoc
KhoaHoc "1" -- "0..*" KiemDuyetKhoaHoc
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Tạo và quản lý khóa học
actor "Giáo viên" as A
boundary "Giao diện" as UI
control "Instructor/CourseController" as C
control CourseContentService as S
database "CSDL" as DB
A -> UI: Nhập thông tin khóa học
UI -> C: Create(model, actionType)
C -> DB: Lưu khóa học và nội dung
DB --> C: Kết quả lưu
C --> UI: Hiển thị khóa học
A -> UI: Chọn gửi duyệt khóa nháp
UI -> C: SubmitForApproval(id)
C -> S: KiemTraKhoaHoc(id)
S --> C: Kết quả kiểm tra
alt Đủ điều kiện
  C -> DB: Chuyển trạng thái Chờ duyệt
  C --> UI: Thông báo đã gửi duyệt
else Chưa đủ điều kiện
  C --> UI: Thông báo nội dung cần bổ sung
end
@enduml
```

## 4.4.3. Thiết kế chức năng kiểm duyệt khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Sơ đồ lớp thiết kế - Kiểm duyệt khóa học
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
  class AdminCourseApprovalController as AC <<controller>> {
    +Index(...): ActionResult
    +GetDetails(id: string): ActionResult
    +Approve(id: string): ActionResult
    +Reject(id: string, reason: string): ActionResult
  }
  class CourseRevisionService <<service>> {
    +Published(trangThai): bool
  }
}
package "Dữ liệu" {
  class KhoaHoc <<entity>> {
    maKhoaHoc: string
    tenKhoaHoc: string
    trangThai: string
    maGiaoVien: int
  }
  class KiemDuyetKhoaHoc <<entity>> {
    maKiemDuyet: string
    ngayGui: DateTime?
    ngayKiemDuyet: DateTime?
    trangThai: string
    lyDoTuChoi: string
    maAdmin: int?
  }
  class NguoiDung <<entity>> {
    maNguoiDung: int
    hoTen: string
    vaiTro: string
    trangThai: bool?
  }
  class ChuongHoc <<entity>>
  class BaiHoc <<entity>>
}
BoundaryUI --> AC
AC ..> CourseRevisionService
AC ..> KhoaHoc
AC ..> KiemDuyetKhoaHoc
AC ..> NguoiDung
AC ..> ChuongHoc
AC ..> BaiHoc
KhoaHoc "1" -- "0..*" KiemDuyetKhoaHoc
NguoiDung "0..1" -- "0..*" KiemDuyetKhoaHoc : người kiểm duyệt
KhoaHoc "1" -- "0..*" ChuongHoc
ChuongHoc "1" -- "0..*" BaiHoc
@enduml
```

### Sơ đồ tuần tự chức năng hệ thống

```plantuml
@startuml
skinparam backgroundColor white
skinparam shadowing false
skinparam defaultFontName Arial
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Kiểm duyệt khóa học
actor "Quản trị viên" as A
boundary "Giao diện" as UI
control "Admin/CourseApprovalController" as C
database "CSDL" as DB
A -> UI: Mở danh sách chờ duyệt
UI -> C: Index(...)
C -> DB: Lấy danh sách
DB --> C: Danh sách khóa học
A -> UI: Chọn xem chi tiết
UI -> C: GetDetails(id)
C --> UI: Thông tin và nội dung khóa học
alt Phê duyệt
  A -> UI: Chọn duyệt
  UI -> C: Approve(id)
  C -> DB: Cập nhật Đã xuất bản
else Từ chối
  A -> UI: Nhập lý do từ chối
  UI -> C: Reject(id, reason)
  C -> DB: Cập nhật Cần sửa đổi và lý do
end
C --> UI: Thông báo kết quả
@enduml
```

Sơ đồ trên tập trung luồng duyệt xuất bản khóa học mới. Bản sửa của khóa học đã xuất bản có quy trình riêng (`CourseRevisionService` và `CourseRevisionController`); cần bổ sung sơ đồ riêng nếu báo cáo trình bày chi tiết nghiệp vụ đó.

## 4.4.4. Đăng ký tài khoản

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Đăng ký tài khoản - Sơ đồ lớp
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
  class "AccountController" as C <<controller>> {
    +SendOtp(...)
    +VerifyRegisterOtp(...)
    +VerifyOtpAndRegister(...)
  }
  class "EmailService" as S <<service>>
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
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Đăng ký tài khoản
actor "Người dùng" as A
boundary "Giao diện" as UI
control AccountController as C
control EmailService as E
database "CSDL" as DB
A -> UI: Nhập họ tên và email
UI -> C: SendOtp(fullName, email)
C -> E: Gửi mã OTP
E --> A: Email chứa OTP
A -> UI: Nhập OTP
UI -> C: VerifyRegisterOtp(email, otp)
C --> UI: Kết quả xác thực
A -> UI: Nhập mật khẩu và đăng ký
UI -> C: VerifyOtpAndRegister(...)
C -> DB: Kiểm tra và lưu tài khoản
DB --> C: Kết quả
C --> UI: Thông báo đăng ký
@enduml
```

## 4.4.5. Đăng nhập và đăng xuất

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Đăng nhập và đăng xuất - Sơ đồ lớp
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
  class "AccountController" as C <<controller>> {
    +Login(...)
    +GoogleLogin(...)
    +Logout(...)
  }
  class "PhienDocQuyenService" as S <<service>>
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
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Đăng nhập tài khoản
actor "Người dùng" as A
boundary "Giao diện" as UI
control AccountController as C
database "CSDL" as DB
A -> UI: Nhập email và mật khẩu
UI -> C: Login(model)
C -> DB: Tra cứu và xác thực tài khoản
DB --> C: Thông tin tài khoản
alt Đăng nhập hợp lệ
  C --> UI: Tạo phiên và chuyển trang
else Không hợp lệ
  C --> UI: Thông báo lỗi
end
@enduml
```

## 4.4.6. Quản lý hồ sơ cá nhân

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Quản lý hồ sơ cá nhân - Sơ đồ lớp
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
  class "ProfileController" as C <<controller>> {
    +Index(...)
    +UpdateInfo(...)
    +UploadAvatar(...)
    +ChangePassword(...)
  }
}
package "Dữ liệu" {
  class "NguoiDung" as E <<entity / dữ liệu>>
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
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Cập nhật hồ sơ cá nhân
actor "Người dùng" as A
boundary "Giao diện" as UI
control ProfileController as C
database "CSDL" as DB
A -> UI: Mở hồ sơ cá nhân
UI -> C: Index()
C -> DB: Lấy thông tin hồ sơ
DB --> C: Dữ liệu hồ sơ
C --> UI: Hiển thị thông tin
A -> UI: Sửa thông tin và lưu
UI -> C: UpdateInfo(...)
C -> DB: Kiểm tra và cập nhật
DB --> C: Kết quả
C --> UI: Thông báo cập nhật
@enduml
```

## 4.4.7. Khuyến nghị khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Khuyến nghị khóa học - Sơ đồ lớp
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
  class "RecommendationController" as C <<controller>> {
    +Index(...)
    +Refresh(...)
  }
  class "RecommendationService" as S <<service>>
}
package "Dữ liệu" {
  class "KhoaHocKhuyenNghi" as E <<entity / dữ liệu>>
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
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Xem gợi ý khóa học
actor "Học viên" as A
boundary "Giao diện" as UI
control RecommendationController as C
control RecommendationService as S
database "CSDL" as DB
A -> UI: Mở trang gợi ý
UI -> C: Index()
C -> S: GetPersonalizedPage(...)
S -> DB: Lấy dữ liệu gợi ý và tương đồng
DB --> S: Dữ liệu kết quả
S --> C: Danh sách hoặc thông báo
C --> UI: Hiển thị gợi ý
UI --> A: Khóa học phù hợp / thông báo
@enduml
```

## 4.4.8. Yêu thích khóa học

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Yêu thích khóa học - Sơ đồ lớp
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
  class "FavoriteController" as C <<controller>> {
    +Toggle(...)
    +State(...)
  }
  class "FavoriteService" as S <<service>>
}
package "Dữ liệu" {
  class "KhoaHoc" as E <<entity / dữ liệu>>
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
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Yêu thích khóa học
actor "Học viên" as A
boundary "Giao diện" as UI
control FavoriteController as C
control FavoriteService as S
database "CSDL" as DB
A -> UI: Chọn hoặc bỏ yêu thích
UI -> C: Toggle(courseId)
C -> S: Toggle(userId, courseId)
S -> DB: Kiểm tra và cập nhật tương tác
DB --> S: Trạng thái mới
S --> C: Kết quả
C --> UI: Cập nhật nút yêu thích
@enduml
```

## 4.4.9. Học bài và theo dõi tiến độ

### Sơ đồ lớp mức thiết kế

```plantuml
@startuml
title Học bài và theo dõi tiến độ - Sơ đồ lớp
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
  class "LearningController" as C <<controller>> {
    +Study(...)
    +UpdateProgress(...)
    +Notes(...)
    +AddNote(...)
  }
  class "LearningService" as S <<service>>
}
package "Dữ liệu" {
  class "TienDoBaiHoc" as E <<entity / dữ liệu>>
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
skinparam sequenceMessageAlign center
skinparam responseMessageBelowArrow true
title Ghi nhận tiến độ bài học
actor "Học viên" as A
boundary "Giao diện học tập" as UI
control LearningController as C
control LearningService as S
database "CSDL" as DB
A -> UI: Xem bài học
UI -> C: UpdateProgress(...)
C -> DB: Kiểm tra ghi danh
DB --> C: Kết quả kiểm tra
C -> S: LuuTienDo(...)
S -> DB: Lưu vị trí xem và tiến độ
DB --> S: Kết quả cập nhật
S --> C: Trạng thái hoàn thành
C --> UI: Cập nhật tiến độ
@enduml
```
