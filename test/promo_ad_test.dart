import 'package:ecolearning_app/data/models/promo_ad.dart';
import 'package:ecolearning_app/presentation/widgets/promo_ad_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _course(String id, int price, int original) => {
  'id': id,
  'title': 'Khóa $id',
  'categoryId': 'DM01',
  'category': 'Thiết kế',
  'instructor': 'Giảng viên',
  'imageUrl': 'http://localhost/a.png',
  'level': 'Cơ bản',
  'rating': 4.5,
  'reviewCount': 3,
  'price': price,
  'originalPrice': original,
  'promotion': original > price
      ? {'name': 'Ưu đãi', 'discountPercent': 10, 'endsAt': '2026-11-27'}
      : null,
};

void main() {
  group('PromoAd', () {
    test('parses the /ads response item', () {
      final ad = PromoAd.fromJson({
        'type': 'campaign',
        'id': 'CD1',
        'title': 'Ưu đãi cuối tháng 10',
        'imageUrl': 'http://localhost/a.png',
        'expiresAt': '2026-11-27',
      });
      expect(ad.type, 'campaign');
      expect(ad.key, 'campaign:CD1');
      expect(ad.imageUrl, 'http://localhost/a.png');
      expect(ad.expiresAt?.year, 2026);
    });

    test('pickUnseen returns the first ad not yet shown this visit', () {
      const a = PromoAd(type: 'campaign', id: 'CD1', title: 'A', imageUrl: 'x');
      const b = PromoAd(
        type: 'promotion',
        id: 'KM1',
        title: 'B',
        imageUrl: 'y',
      );
      expect(PromoAdPresenter.pickUnseen([a, b], {}), a);
      expect(PromoAdPresenter.pickUnseen([a, b], {a.key}), b);
      expect(PromoAdPresenter.pickUnseen([a, b], {a.key, b.key}), isNull);
      expect(PromoAdPresenter.pickUnseen([], {}), isNull);
    });
  });

  group('PromoAdPage', () {
    test('parses offers, codes, messages and course prices', () {
      final page = PromoAdPage.fromJson({
        'type': 'campaign',
        'id': 'CD1',
        'title': 'Ưu đãi cuối tháng 10',
        'description': 'Giảm giá nhiều khóa học',
        'imageUrl': 'http://localhost/a.png',
        'startsAt': '2026-10-28',
        'endsAt': '2026-11-27',
        'offers': [
          {
            'id': 'KM1',
            'title': 'Giảm 10% khóa Marketing',
            'discountText': '10%',
            'note': 'Tối đa 200K',
            'conditions': ['Danh mục Marketing'],
            'expiresAt': '2026-11-27',
            'isDirectDiscount': true,
            'isLoyalty': false,
            'code': null,
            'canSave': false,
            'saved': false,
            'message': null,
            'appliesToAll': false,
            'totalCourses': 10,
            'courses': [_course('K1', 531000, 590000)],
          },
          {
            'id': 'KM2',
            'title': 'Ưu đãi thân thiết',
            'discountText': '15%',
            'conditions': <String>[],
            'isDirectDiscount': false,
            'isLoyalty': true,
            'code': null,
            'canSave': false,
            'message': 'Ưu đãi dành riêng cho học viên thân thiết.',
            'courses': <dynamic>[],
          },
          {
            'id': 'KM3',
            'title': 'Giảm 15% khóa Thiết kế',
            'discountText': '15%',
            'code': 'THIETKE15',
            'canSave': true,
            'saved': false,
            'appliesToAll': false,
            'totalCourses': 1,
            'courses': [_course('K2', 790000, 790000)],
          },
        ],
      });

      expect(page.title, 'Ưu đãi cuối tháng 10');
      expect(page.offers, hasLength(3));

      final direct = page.offers[0];
      expect(direct.isDirectDiscount, isTrue);
      expect(direct.code, isNull);
      expect(direct.totalCourses, 10);
      expect(direct.courses.single.price, 531000);
      expect(direct.courses.single.originalPrice, 590000);

      final loyalty = page.offers[1];
      expect(loyalty.isLoyalty, isTrue);
      expect(
        loyalty.code,
        isNull,
        reason: 'khách / người chưa đủ điều kiện không thấy mã',
      );
      expect(loyalty.message, contains('thân thiết'));

      final coupon = page.offers[2];
      expect(coupon.code, 'THIETKE15');
      expect(coupon.canSave, isTrue);
      expect(coupon.copyWith(saved: true, canSave: false).saved, isTrue);
      expect(coupon.copyWith(saved: true, canSave: false).canSave, isFalse);
    });
  });

  group('LoyaltyPopup', () {
    test('show=false means nothing to advertise', () {
      final p = LoyaltyPopup.fromJson({'show': false});
      expect(p.show, isFalse);
      expect(p.isEligible, isFalse);
    });

    test('only an eligible popup with a code is shown', () {
      final eligible = LoyaltyPopup.fromJson({
        'show': true,
        'kind': 'eligible',
        'promotionId': 'KM9',
        'code': 'NGAYHOIDEV2026',
        'title': 'Ngày hội lập trình viên',
        'discountText': '10%',
        'conditions': ['Đã mua từ 3 khóa học'],
        'expiresAt': '2026-11-25',
      });
      expect(eligible.isEligible, isTrue);

      final upcoming = LoyaltyPopup.fromJson({
        'show': true,
        'kind': 'upcoming',
        'title': 'Sắp mở',
      });
      expect(upcoming.isEligible, isFalse);
    });

    testWidgets('dialog shows the code and the "never again" button works', (
      tester,
    ) async {
      var never = 0;
      final popup = LoyaltyPopup.fromJson({
        'show': true,
        'kind': 'eligible',
        'promotionId': 'KM9',
        'code': 'NGAYHOIDEV2026',
        'title': 'Ngày hội lập trình viên',
        'discountText': '10%',
        'note': 'Tối đa 200K',
        'description': 'Giảm cho học viên thân thiết',
        'conditions': ['Đã mua từ 3 khóa học'],
        'expiresAt': '2026-11-25',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => LoyaltyPopupDialog(
                    popup: popup,
                    onNever: () async => never++,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('NGAYHOIDEV2026'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('Lưu vào ví'), findsOneWidget);

      await tester.tap(find.text('Không hiện lại'));
      await tester.pump();
      expect(never, 1);
    });
  });
}
