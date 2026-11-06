# 4.4. Thiết kế chức năng hệ thống

Các sơ đồ dưới đây mô tả luồng chính trên website ASP.NET MVC. Sao chép từng khối vào PlantUML để xuất hình. Tên phương thức trong sơ đồ lớp là các phương thức tiêu biểu; thông điệp mô tả nghiệp vụ được ghi bằng tiếng Việt không nhất thiết là tên hàm trong mã nguồn. `CSDL` là đối tượng thể hiện SQL Server và Entity Framework để sơ đồ dễ đọc.

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
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Sơ đồ tuần tự - Tìm mua khóa học
actor "Khách / học viên" as HV
boundary "Giao diện website" as UI
control SearchController as SC
control SearchService as SS
control CourseController as CC
control CartController as Cart
control PromotionService as Promo
control PaymentController as PC
control PaymentService as Pay
database "CSDL SQL Server" as DB
HV -> UI: Nhập từ khóa, bộ lọc
UI -> SC: Index(...)
SC -> SS: TimKiem(bộ lọc, userId)
SS -> DB: Lấy dữ liệu khóa học
DB --> SS: Dữ liệu khóa học
SS --> SC: Kết quả tìm kiếm
SC --> UI: Danh sách khóa học
HV -> UI: Chọn khóa học
UI -> CC: Details(id)
CC -> DB: Lấy chi tiết khóa học
DB --> CC: Thông tin khóa học
CC --> UI: Hiển thị chi tiết
alt Đăng ký khóa học miễn phí
  HV -> UI: Chọn đăng ký
  UI -> CC: EnrollFree(courseId)
  CC -> DB: Kiểm tra điều kiện và ghi danh
  DB --> CC: Kết quả
  CC --> UI: Hiển thị kết quả
else Mua qua giỏ hàng
  HV -> UI: Thêm khóa vào giỏ
  UI -> Cart: AddToCart(courseId)
  Cart --> UI: Cập nhật giỏ trong phiên
  opt Áp dụng mã giảm giá
    HV -> UI: Nhập mã giảm giá
    UI -> Cart: ApplyCoupon(couponCode)
    Cart -> Promo: Kiểm tra mã và điều kiện
    Promo --> Cart: Kết quả ưu đãi
    Cart --> UI: Hiển thị kết quả
  end
  HV -> UI: Xác nhận thanh toán
  UI -> Cart: Checkout(paymentMethod, couponCode)
  Cart -> DB: Kiểm tra tài khoản, khóa học và giá
  alt Không hợp lệ hoặc chưa đăng nhập
    Cart --> UI: Thông báo lỗi / yêu cầu đăng nhập
  else Hợp lệ
    opt Có mã giảm giá
      Cart -> Promo: Kiểm tra lại mã
      Promo --> Cart: Kết quả kiểm tra
    end
    Cart -> DB: Tạo đơn và chi tiết đơn
    Cart --> UI: Kết quả tạo đơn
    alt Tổng tiền bằng 0
      Cart -> Pay: XacNhanDonMienPhi(orderId)
      Pay -> DB: Ghi nhận thanh toán và ghi danh
      Pay --> UI: Kết quả
    else Tổng tiền lớn hơn 0
      UI -> PC: Gateway(orderId)
      PC --> UI: Cổng thử nghiệm / VNPay Sandbox
      HV -> UI: Thực hiện thanh toán thử nghiệm
      UI -> PC: Trả kết quả thanh toán
      PC -> Pay: Xử lý kết quả hợp lệ
      alt Thành công
        Pay -> DB: Cập nhật thanh toán và đơn
        DB -> DB: Trigger ghi danh học viên
        Pay --> UI: Thông báo thành công
      else Thất bại hoặc không hợp lệ
        Pay --> UI: Thông báo kết quả / lỗi
      end
    end
  end
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
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Sơ đồ tuần tự - Tạo và quản lý khóa học
actor "Giáo viên" as GV
boundary "Giao diện giảng viên" as UI
control "Instructor/CourseController" as IC
control TeacherSpecialtyService as Specialty
control CourseContentService as Content
control CourseRevisionService as Revision
control CourseLifecycleService as Lifecycle
database "CSDL SQL Server" as DB
GV -> UI: Chọn tạo khóa học
UI -> IC: Create()
IC --> UI: Biểu mẫu khóa học
GV -> UI: Nhập thông tin, nội dung
GV -> UI: Chọn lưu nháp hoặc gửi duyệt
UI -> IC: Create(model, actionType)
IC -> Specialty: Kiểm tra chuyên môn / danh mục
Specialty --> IC: Kết quả kiểm tra
alt Dữ liệu không hợp lệ
  IC --> UI: Hiển thị lỗi và biểu mẫu
else Dữ liệu hợp lệ
  IC -> DB: Lưu khóa học và nội dung
  alt Lưu nháp
    IC --> UI: Khóa học ở trạng thái Bản nháp
  else Gửi duyệt khi tạo
    IC -> DB: Ghi trạng thái Chờ duyệt và bản ghi kiểm duyệt
    IC --> UI: Thông báo đã gửi duyệt
  end
end
opt Chỉnh sửa khóa học
  GV -> UI: Chọn chỉnh sửa và lưu
  UI -> IC: Edit(model, actionType)
  alt Khóa đã xuất bản / có bản sửa
    IC -> Revision: Save(...)
    Revision -> DB: Lưu bản sửa theo quy trình
    Revision --> IC: Kết quả
  else Khóa nháp đủ điều kiện sửa
    IC -> DB: Cập nhật thông tin khóa học
  end
  IC --> UI: Hiển thị kết quả
end
opt Gửi duyệt khóa nháp đã tạo
  GV -> UI: Chọn gửi duyệt
  UI -> IC: SubmitForApproval(id)
  IC -> Content: KiemTraKhoaHoc(id)
  Content --> IC: Danh sách nội dung còn thiếu
  alt Chưa đủ điều kiện
    IC --> UI: Thông báo nội dung cần bổ sung
  else Đủ điều kiện
    IC -> DB: Cập nhật Chờ duyệt và bản ghi kiểm duyệt
    IC --> UI: Thông báo đã gửi duyệt
  end
end
opt Tạm ngưng / mở bán lại / xóa
  GV -> UI: Chọn thao tác quản lý
  UI -> IC: Pause(id) / Resume(id) / Delete(id)
  IC -> Lifecycle: Kiểm tra và thực hiện thao tác
  Lifecycle -> DB: Đọc và cập nhật trạng thái
  Lifecycle --> IC: Kết quả
  IC --> UI: Hiển thị kết quả
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
skinparam sequence {
  ArrowColor black
  LifeLineBorderColor black
  ParticipantBorderColor black
  ParticipantBackgroundColor white
  ActorBorderColor black
  ActorBackgroundColor white
}
title Sơ đồ tuần tự - Kiểm duyệt khóa học
actor "Quản trị viên" as Admin
boundary "Giao diện quản trị" as UI
control "Admin/CourseApprovalController" as AC
database "CSDL SQL Server" as DB
Admin -> UI: Mở danh sách khóa học chờ duyệt
UI -> AC: Index(...)
AC -> DB: Truy vấn khóa học và trạng thái
DB --> AC: Danh sách
AC --> UI: Hiển thị danh sách
Admin -> UI: Chọn một khóa học
UI -> AC: GetDetails(id)
AC -> DB: Lấy thông tin, chương và bài học
DB --> AC: Chi tiết khóa học
AC --> UI: Hiển thị nội dung để kiểm duyệt
alt Phê duyệt
  Admin -> UI: Chọn phê duyệt
  UI -> AC: Approve(id)
  AC -> DB: Kiểm tra khóa học và điều kiện duyệt
  alt Đủ điều kiện
    AC -> DB: Cập nhật khóa học Đã xuất bản
    AC -> DB: Cập nhật bản ghi Đã duyệt
    AC --> UI: Thông báo phê duyệt thành công
  else Không đủ điều kiện
    AC --> UI: Thông báo lý do không thể duyệt
  end
else Từ chối
  Admin -> UI: Nhập lý do và chọn từ chối
  UI -> AC: Reject(id, reason)
  AC -> DB: Kiểm tra điều kiện từ chối
  alt Hợp lệ
    AC -> DB: Cập nhật khóa học Cần sửa đổi
    AC -> DB: Ghi trạng thái Từ chối và lý do
    AC --> UI: Thông báo đã từ chối
  else Không hợp lệ
    AC --> UI: Thông báo lỗi
  end
end
@enduml
```

Sơ đồ trên tập trung luồng duyệt xuất bản khóa học mới. Bản sửa của khóa học đã xuất bản có quy trình riêng (`CourseRevisionService` và `CourseRevisionController`); cần bổ sung sơ đồ riêng nếu báo cáo trình bày chi tiết nghiệp vụ đó.

## 4.5. Kết chương 4

Chương 4 đã trình bày thiết kế các thành phần và chức năng chính của hệ thống ECOLearning dựa trên kết quả phân tích ở chương trước. Các sơ đồ lớp mức thiết kế thể hiện những controller, service và lớp dữ liệu tham gia xử lý; các sơ đồ tuần tự mô tả sự tương tác giữa người dùng, giao diện, các thành phần xử lý và cơ sở dữ liệu trong từng luồng nghiệp vụ.

Ba chức năng được trình bày gồm tìm mua khóa học, tạo và quản lý khóa học, kiểm duyệt khóa học. Thiết kế này là cơ sở để triển khai, kiểm thử và đánh giá hoạt động của hệ thống trong chương tiếp theo.
