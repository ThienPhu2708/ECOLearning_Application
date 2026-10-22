import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HelpTermsScreen extends StatelessWidget {
  const HelpTermsScreen({super.key});

  static const _questions = <(String, String)>[
    (
      'Tiếp tục học khóa đã đăng ký ở đâu?',
      'Mở tab Khóa học, chọn Đang học rồi bấm Tiếp tục học. Các khóa đã học đủ bài nằm ở tab Đã học đủ bài và có thể mở lại để ôn tập.',
    ),
    (
      'Vì sao xem video rồi mà bài chưa hoàn thành?',
      'Bạn cần xem đủ thời lượng yêu cầu của bài học. Tiến độ được gửi khi đang học, tạm dừng hoặc rời bài; kết quả hoàn thành do hệ thống xác nhận. Nếu tiến độ chưa cập nhật, kiểm tra kết nối rồi mở lại khóa học.',
    ),
    (
      'Khi nào tôi được làm quiz cuối khóa?',
      'Bạn cần học đủ các bài và khóa học đã mở quiz. Mở khóa học đã học đủ bài, chọn Làm quiz cuối khóa để xem thời gian, ngưỡng đạt và số lượt được phép trước khi bắt đầu.',
    ),
    (
      'Thoát trang quiz thì thời gian có dừng không?',
      'Không. Đồng hồ bắt đầu khi bạn xác nhận vào bài và vẫn tính khi rời trang. Hãy quay lại bài đang làm trước khi hết giờ. Bạn nên kiểm tra trạng thái lưu đáp án trước khi thoát.',
    ),
    (
      'Làm sao nhận và xem chứng chỉ?',
      'Học đủ bài và đạt quiz theo yêu cầu của khóa học, sau đó chọn nhận chứng chỉ trên trang kết quả. Các chứng chỉ đã nhận nằm trong Hồ sơ → Chứng chỉ của tôi. Học đủ bài chưa đồng nghĩa đã có chứng chỉ.',
    ),
    (
      'Khi nào tôi có thể đánh giá khóa học?',
      'Bạn cần hoàn thành các bài học và đạt quiz cuối khóa. Khi đủ điều kiện, chức năng đánh giá sẽ được mở trong không gian học tập.',
    ),
    (
      'Khóa học yêu thích và đơn hàng nằm ở đâu?',
      'Ở tab Khóa học, bấm trái tim để xem khóa học yêu thích hoặc icon hóa đơn bên cạnh để mở lịch sử đơn hàng. Bạn cũng có thể mở các mục này từ Hồ sơ.',
    ),
    (
      'Cập nhật hồ sơ và ảnh đại diện như thế nào?',
      'Trong Hồ sơ, chọn Chỉnh sửa thông tin cá nhân. Để đổi ảnh, bấm avatar hoặc icon máy ảnh rồi chọn từ thư viện hoặc chụp ảnh mới. Khi dùng bản thử nghiệm chưa nối dịch vụ, thay đổi chỉ được giữ trong phiên đang mở.',
    ),
    (
      'Tôi gặp lỗi tải nội dung thì làm gì?',
      'Kiểm tra kết nối, kéo xuống để làm mới hoặc bấm Thử lại. Nếu lỗi vẫn còn, ghi lại màn hình, tên khóa học và thời điểm xảy ra để cung cấp cho người quản trị. Không gửi mật khẩu hay mã xác thực.',
    ),
  ];
  static const _terms = <(String, String)>[
    (
      'Tài khoản cá nhân',
      'Sử dụng thông tin chính xác khi đăng ký và cập nhật hồ sơ. Giữ riêng mật khẩu, mã xác thực và quyền truy cập tài khoản; không dùng tài khoản của người khác.',
    ),
    (
      'Sử dụng nội dung học tập',
      'Sử dụng bài giảng, tài liệu và câu hỏi đúng mục đích học tập. Tôn trọng quyền của tác giả; không tự ý sao chép, phát tán hoặc bán lại nội dung khi chưa được cho phép.',
    ),
    (
      'Quiz và chứng chỉ',
      'Thực hiện bài kiểm tra trung thực. Xem điều kiện, thời gian và số lượt của từng quiz trước khi bắt đầu. Chứng chỉ ghi nhận kết quả được hệ thống xác nhận theo điều kiện của khóa học.',
    ),
    (
      'Tương tác trong khóa học',
      'Trao đổi lịch sự, đúng chủ đề. Không đăng nội dung xúc phạm, spam hoặc chia sẻ thông tin cá nhân của người khác khi chưa có sự đồng ý.',
    ),
    (
      'Thông tin và quyền riêng tư',
      'Chỉ cung cấp thông tin cần thiết khi sử dụng ứng dụng. Nội dung chính sách về thu thập, lưu trữ, chia sẻ và xử lý dữ liệu cá nhân cần được đơn vị vận hành xác nhận trong bản chính thức.',
    ),
    (
      'Thanh toán và hỗ trợ',
      'Kiểm tra thông tin khóa học, giá và đơn hàng trước khi thanh toán. Các quy định về thanh toán, hủy đơn, hoàn tiền và kênh hỗ trợ cần được đơn vị vận hành công bố trong bản chính thức.',
    ),
  ];

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trợ giúp & Điều khoản'),
        bottom: const TabBar(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Trợ giúp'),
            Tab(text: 'Điều khoản'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _intro(
                Icons.help_outline_rounded,
                'Bạn cần hỗ trợ điều gì?',
                'Hướng dẫn nhanh cho quá trình học tập và sử dụng tài khoản.',
              ),
              const SizedBox(height: 20),
              for (final item in _questions) _question(item.$1, item.$2),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _intro(
                Icons.description_outlined,
                'Điều khoản sử dụng',
                'Các nguyên tắc sử dụng nền tảng E-Learning.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BẢN DỰ THẢO\nNội dung dùng để xem trước trong bản thử nghiệm. Điều khoản và chính sách chính thức sẽ được đơn vị vận hành xác nhận trước khi áp dụng.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _terms.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${_terms[i].$1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _terms[i].$2,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.7,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _intro(IconData icon, String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textHeading,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.6,
          fontSize: 14,
        ),
      ),
    ],
  );

  Widget _question(String title, String answer) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
