import 'package:ecolearning_app/core/utils/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tìm tên giảng viên không phân biệt dấu và hoa thường', () {
    expect(TextSearch.contains('Trần Minh Khoa', 'tran minh'), isTrue);
    expect(TextSearch.contains('Lê Thu Hà', 'THU hà'), isTrue);
    expect(TextSearch.contains('Phạm Quốc Bảo', 'khoa'), isFalse);
    expect(TextSearch.contains('Đặng Văn', 'dang'), isTrue);
  });

  test('chỉ khớp theo từ, không khớp giữa từ', () {
    expect(TextSearch.contains('Phạm Quốc Bảo', 'hà'), isFalse);
    expect(TextSearch.contains('Phạm Quốc Bảo', 'ha'), isFalse);
    expect(TextSearch.contains('Lê Thu Hà', 'hà'), isTrue);
    expect(TextSearch.contains('Lê Thu Hà', 'ha'), isTrue);
    expect(TextSearch.contains('Trần Minh Khoa', 'hà'), isFalse);
  });

  test('từ có dấu phải khớp nguyên từ và đúng dấu', () {
    expect(TextSearch.contains('Nguyễn Văn Hạ', 'hà'), isFalse);
    expect(TextSearch.contains('Bán hàng trên Shopee', 'hà'), isFalse);
    expect(TextSearch.contains('Tiếng Hàn sơ cấp 1', 'hà'), isFalse);
    expect(TextSearch.contains('Nguyễn Văn Hạ', 'ha'), isTrue);
  });

  test('từ không dấu khớp đầu từ, hoặc nguyên từ khi wholeWord', () {
    expect(TextSearch.contains('Đầu tư chứng khoán', 'khoa'), isTrue);
    expect(
      TextSearch.contains('Đầu tư chứng khoán', 'khoa', wholeWord: true),
      isFalse,
    );
    expect(
      TextSearch.contains('Python cho Khoa học dữ liệu', 'khoa', wholeWord: true),
      isTrue,
    );
    expect(TextSearch.contains('Design System với Figma', 'figm'), isTrue);
  });

  test('nhiều từ phải khớp đủ, không cần đúng thứ tự', () {
    expect(TextSearch.contains('Lê Thu Hà', 'thu hà'), isTrue);
    expect(TextSearch.contains('Lê Thu Hà', 'hà lê'), isTrue);
    expect(TextSearch.contains('Lê Thu Hà', 'thu bảo'), isFalse);
  });
}
