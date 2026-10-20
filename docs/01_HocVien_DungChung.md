# ĐẶC TẢ GIAO DIỆN: PHÂN HỆ DÙNG CHUNG VÀ HỌC VIÊN
*Tài liệu bám sát đặc tả Use Case từ UC1 đến UC8*[cite: 2]

---

## I. MỤC 3.3.1.1: GIAO DIỆN DÙNG CHUNG CHO HỆ THỐNG[cite: 2]

### 1. Chức năng Đăng ký và Đăng nhập tài khoản (UC1)[cite: 2]
* **Màn hình Đăng nhập (Mọi tác nhân)[cite: 2]:**
  * Form đăng nhập: Ô nhập Email và Mật khẩu[cite: 2].
  * Nút hành động: "Đăng nhập" (Nền `#434CE8`, bo góc 12px)[cite: 2].
  * Khối tùy chọn đăng nhập bằng Google[cite: 2].
  * Liên kết "Quên mật khẩu": Kích hoạt luồng nhập Email để nhận link/form xác thực thiết lập lại mật khẩu[cite: 2].
  * Phản hồi lỗi: Viền đỏ và hiển thị cảnh báo khi tài khoản/mật khẩu không chính xác hoặc để trống[cite: 2].
* **Màn hình Đăng ký tài khoản (Học viên mới)[cite: 2]:**
  * Bước 1: Form điền Họ và tên, Email, nút "Tiếp tục"[cite: 2]. Hỗ trợ nút đăng ký nhanh qua Google[cite: 2].
  * Phản hồi kiểm tra: Cảnh báo "Email này đã được đăng ký" nếu trùng lặp[cite: 2].
  * Bước 2: Khung nhập mã xác thực OTP gửi về email đăng ký[cite: 2].
  * Bước 3: Màn hình thiết lập mật khẩu và xác nhận mật khẩu (Hiển thị thanh đo độ mạnh mật khẩu, cảnh báo nếu dưới 8 ký tự hoặc thiếu chữ/số/ký tự đặc biệt)[cite: 2].

### 2. Chức năng Đăng xuất tài khoản (UC2)[cite: 2]
* **Giao diện Modal Popup xác nhận[cite: 2]:**
  * Vị trí: Hiển thị dạng hộp thoại nổi giữa màn hình khi bấm chọn "Đăng xuất" từ menu tài khoản[cite: 2].
  * Nội dung: Tiêu đề "Xác nhận đăng xuất", lời nhắc "Bạn có chắc chắn muốn kết thúc phiên làm việc?"[cite: 2].
  * Cụm nút: Nút "Hủy" (viền xám) và nút "Đăng xuất" (màu `#EF4444` hoặc `#434CE8`)[cite: 2].
  * Điều hướng: Chuyển hướng về Trang chủ đối với Học viên/Khách, chuyển về form Đăng nhập đối với nhóm Quản lý[cite: 2].

---

## II. MỤC 3.3.1.2: GIAO DIỆN NHÓM HỌC VIÊN[cite: 2]

### 3. Trang chủ hệ thống[cite: 2]
* **Khối Hero Banner:**
  * Tag nổi bật: `✨ LEARNING, MADE PERSONAL` (nền `#EEF2FF`, chữ `#434CE8`).
  * Headline: "Find the right course for your learning journey".
  * Nút bấm chính "Explore Courses" dẫn đến danh mục[cite: 2].
  * Khung minh họa 3D kèm Card nổi: `YOUR TOP MATCH: 98% course fit`.
* **Khối Khóa học nổi bật & Danh mục:** Lưới các thẻ danh mục xu hướng và khóa học bán chạy (Top Trending)[cite: 2].

### 4. Chức năng Tìm mua khóa học (UC4)[cite: 2]
* **Trang Kết quả tìm kiếm & Bộ lọc nâng cao[cite: 2]:**
  * Thanh tìm kiếm có hiển thị danh sách kỹ năng đang thịnh hành[cite: 2].
  * Cột trái (Sidebar Filter): Bộ lọc đa tiêu chí gồm Số sao (3-5 sao), Cấp độ, Thời lượng, Mức giá (Có checkbox lọc khóa Miễn phí)[cite: 2].
  * Cột phải: Lưới danh sách khóa học. Trạng thái rỗng: Hiển thị "Không tìm thấy kết quả" kèm đề xuất từ khóa khác[cite: 2].
* **Trang Chi tiết khóa học[cite: 2]:**
  * Vùng nội dung bên trái: Tên khóa học, mục tiêu đầu ra, đề cương chi tiết các bài học kèm video xem thử (Preview), điểm đánh giá trung bình và các nhận xét[cite: 2].
  * Khối Sticky cố định bên phải: Giá bán gốc và giá ưu đãi, Nút "Thêm vào giỏ hàng" và "Mua ngay" (Đối với khóa học miễn phí hiển thị nút "Đăng ký khóa học" để kích hoạt ngay)[cite: 2].
* **Trang Giỏ hàng & Thanh toán[cite: 2]:**
  * Bảng danh sách khóa học đăng ký mua và tổng tiền tạm tính[cite: 2].
  * Ô nhập mã khuyến mãi/Coupon: Có nút "Áp dụng", chữ báo đỏ "Mã khuyến mãi không hợp lệ" nếu sai/hết hạn[cite: 2].
  * Vùng chọn cổng thanh toán: Thẻ ATM/Visa, Ví điện tử MoMo/VNPay[cite: 2].
  * Nút "Xác nhận thanh toán" và Modal thông báo xử lý thành công/thất bại[cite: 2].

### 5. Chức năng Theo dõi tiến độ học tập (UC5)[cite: 2]
* **Không gian học tập (Learning Space)[cite: 2]:**
  * Khung trình phát video chính: Có thanh tua, điều chỉnh tốc độ xem (0.75x, 1x, 1.25x, 1.5x, 2x), nút phát lại 10 giây, chế độ toàn màn hình[cite: 2].
  * Cột danh sách đề cương bên phải (Accordion): Cây thư mục Chương $\rightarrow$ Bài học[cite: 2].
  * Nhãn tiến độ: Icon dấu tích xanh `#10B981` tự động xuất hiện khi học viên xem đạt $\ge 80\%$ thời lượng video[cite: 2].
  * Thanh tiến độ tổng thể (Progress bar): Hiển thị phần trăm hoàn thành của toàn khóa[cite: 2].
  * Banner thông báo mất mạng: Popup mờ "Lỗi kết nối mạng", tự động lưu mốc thời gian xem gần nhất[cite: 2].

### 6. Chức năng Đánh giá khóa học (UC6)[cite: 2]
* **Biểu mẫu Đánh giá (Tự động mở khi tiến độ đạt $\ge 70\%$ hoặc click nút Đánh giá)[cite: 2]:**
  * Thang điểm 5 ngôi sao: Cho phép chọn số sao từ 1 đến 5 (Màu vàng `#F59E0B`)[cite: 2].
  * Khung nhập văn bản: "Cảm nhận của bạn về khóa học..." (cho phép để trống nhận xét nếu chỉ chấm sao)[cite: 2].
  * Nút "Gửi đánh giá": Báo lỗi nếu nhấn gửi mà chưa chọn sao[cite: 2].
  * Hỗ trợ tải lại số sao và nhận xét cũ để chỉnh sửa nếu học viên từng đánh giá trước đó[cite: 2].

### 7. Chức năng Xem khóa học gợi ý (UC7)[cite: 2]
* **Khối đề xuất trên Trang chủ:** Section mang tên "Khóa học dành riêng cho bạn" hiển thị danh sách từ thuật toán Lọc cộng tác dựa trên lịch sử xem, lịch sử mua[cite: 2].
* **Xử lý tài khoản mới (Cold Start):** Tự động hiển thị các khóa học có lượt mua cao nhất (Top Trending) hoặc theo chủ đề người dùng đã quan tâm[cite: 2].
* **Khối gợi ý tại Trang chi tiết:** Khối "Các khóa học tương tự" đặt ở cuối trang dựa trên tag và danh mục[cite: 2].

### 8. Chức năng Quản lý lịch sử khóa học (UC8)[cite: 2]
* **Trang "Khóa học của tôi" (My Learning) chia 2 tab[cite: 2]:**
  * Tab "Đang học": Danh sách các khóa học đã ghi danh kèm thanh tiến độ %, nút "Tiếp tục học" đưa thẳng về video đang xem dở[cite: 2]. Trạng thái chưa có khóa học hiển thị thông báo "Bạn chưa sở hữu khóa học nào" kèm nút "Khám phá khóa học ngay"[cite: 2].
  * Tab "Đã hoàn thành": Hiển thị các khóa học đạt 100% tiến độ kèm nút "Xem chứng chỉ"[cite: 2].
  * Màn hình xem chứng chỉ: Khung hiển thị chứng chỉ định dạng PDF có nút "Tải xuống"[cite: 2].