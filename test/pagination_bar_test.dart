import 'package:ecolearning_app/presentation/widgets/pagination_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String show(int page, int total) => PaginationBar.items(page, total).map((e) => e ?? '…').join(' ');

  test('ít trang thì hiện đủ số', () {
    expect(show(1, 2), '1 2');
    expect(show(2, 3), '1 2 3');
  });

  test('nhiều trang thì gọn: đầu, hiện tại, cuối', () {
    expect(show(1, 20), '1 2 … 20');
    expect(show(10, 20), '1 … 10 … 20');
    expect(show(20, 20), '1 … 19 20');
  });

  test('thiếu đúng một trang thì hiện luôn số đó thay vì …', () {
    expect(show(3, 20), '1 2 3 … 20');
    expect(show(18, 20), '1 … 18 19 20');
  });
}
