import 'package:ecolearning_app/core/utils/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tìm tên giảng viên không phân biệt dấu và hoa thường', () {
    expect(TextSearch.contains('Trần Minh Khoa', 'tran minh'), isTrue);
    expect(TextSearch.contains('Lê Thu Hà', 'THU hà'), isTrue);
    expect(TextSearch.contains('Phạm Quốc Bảo', 'khoa'), isFalse);
    expect(TextSearch.contains('Đặng Văn', 'dang'), isTrue);
  });
}
