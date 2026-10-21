import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/auth_session.dart';
import 'package:ecolearning_app/data/models/cart_quote.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';

/// Kiểm tra model đọc đúng các mẫu JSON trong Task_Tuan10.docx (mục 5.5, B3, G2, A1)
void main() {
  cartQuoteTests();
  test('CourseSummary (mục 5.5)', () {
    final c = Course.fromJson({
      'id': 'KH260929150333',
      'title': 'Lập trình C# Cơ bản đến Nâng cao',
      'categoryId': 'DM01',
      'category': 'Lập trình',
      'instructor': 'Trần Minh Khoa',
      'imageUrl': 'https://example.com/cover.jpg',
      'level': 'Cơ bản',
      'rating': 4.8,
      'reviewCount': 12,
      'price': 349000,
      'originalPrice': 499000,
      'isFree': false,
      'lessonsCount': 24,
      'durationSeconds': 54000,
      'tag': 'Bán chạy',
    });
    expect(c.id, 'KH260929150333');
    expect(c.price, 349000);
    expect(c.originalPrice, 499000);
    expect(c.isFree, isFalse);
    expect(c.duration, '15 giờ');
    expect(c.instructorAvatar, Course.defaultInstructorAvatar);
  });

  test('Chi tiết khóa học (B3): đề cương, đánh giá của tôi', () {
    final c = Course.fromJson({
      'id': 'KH1',
      'title': 'A',
      'price': 0,
      'outcomes': ['Nắm vững cú pháp C#'],
      'chapters': [
        {
          'id': 'CH01',
          'title': 'Giới thiệu',
          'lessons': [
            {'id': 'BH01', 'title': 'Cài đặt', 'durationSeconds': 317, 'isPreview': true},
          ],
        },
      ],
      'isFavorite': true,
      'myReview': {'rating': 4, 'comment': 'Hay'},
    });
    expect(c.isFree, isTrue);
    expect(c.chapters.single.lessons.single.duration, '05:17');
    expect(c.chapters.single.lessons.single.isFree, isTrue);
    expect(c.isFavorite, isTrue);
    expect(c.myReviewRating, 4);
    expect(c.outcomes, ['Nắm vững cú pháp C#']);
  });

  test('Đăng nhập (A1): token + user', () {
    final s = AuthSession.fromJson({
      'token': 'abc',
      'expiresAt': '2026-11-19T10:00:00+07:00',
      'user': {'id': 4, 'fullName': 'Học viên', 'role': 'HocVien', 'joinDate': '2026-01-10T08:00:00+07:00'},
    });
    expect(s.token, 'abc');
    expect(s.expiresAt, isNotNull);
    expect(s.user.id, '4');
    expect(s.user.role, 'Học viên');
    expect(s.user.joinDate, 'Tháng 01/2026');
  });

  test('Không gian học (G2)', () {
    final o = LearningOverview.fromJson({
      'courseId': 'KH1',
      'title': 'A',
      'progress': 62.5,
      'currentLessonId': 'BH07',
      'chapters': [
        {
          'id': 'CH01',
          'title': 'x',
          'lessons': [
            {'id': 'BH01', 'title': 'y', 'durationSeconds': 317, 'isCompleted': true, 'lastPositionSeconds': 317},
          ],
        },
      ],
      'quiz': {'available': true, 'passed': false},
      'certificate': {'issued': false},
    });
    expect(o.progress, 62.5);
    expect(o.chapters.first.lessons.first.isCompleted, isTrue);
    expect(o.quizAvailable, isTrue);
    expect(o.certificateIssued, isFalse);
  });

  test('Phân trang (mục 5.4)', () {
    final p = PagedResult.fromJson({
      'items': [
        {'id': 'KH1', 'title': 'A', 'price': 1},
      ],
      'page': 1,
      'pageSize': 12,
      'total': 37,
      'totalPages': 4,
    }, Course.fromJson);
    expect(p.items.length, 1);
    expect(p.hasMore, isTrue);
  });

  test('Lỗi chung (mục 5.3) đổi thành ApiException', () {
    final options = RequestOptions(path: '/auth/register/send-otp');
    final e = ApiException.fromDio(DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: options, statusCode: 409, data: {
        'success': false,
        'code': 'EMAIL_EXISTS',
        'message': 'Email này đã được đăng ký',
        'errors': {'email': 'Email này đã được đăng ký'},
      }),
    ));
    expect(e.statusCode, 409);
    expect(e.code, 'EMAIL_EXISTS');
    expect(e.message, 'Email này đã được đăng ký');
    expect(e.fieldError('email'), isNotNull);

    final network = ApiException.fromDio(DioException(requestOptions: options, type: DioExceptionType.connectionError));
    expect(network.isNetwork, isTrue);
  });
}

void cartQuoteTests() {
  group('Báo giá giỏ hàng (F1)', () {
    test('mã hợp lệ và khóa bị loại', () {
      final q = CartQuote.fromJson({
        'items': [
          {'id': 'c1', 'price': 349000},
        ],
        'subTotal': 349000,
        'discount': 34900,
        'total': 314100,
        'coupon': {'code': 'ABC', 'isValid': true},
        'invalidItems': [
          {'courseId': 'c2', 'reason': 'Bạn đã sở hữu khóa học này'},
        ],
      });
      expect(q.total, 314100);
      expect(q.prices['c1'], 349000);
      expect(q.couponCode, 'ABC');
      expect(q.invalidItems.single.courseId, 'c2');
    });

    test('ví dụ F1 trong tài liệu hợp đồng', () {
      final q = CartQuote.fromJson({
        'items': [
          {'id': 'KH01', 'title': 'x', 'price': 349000, 'originalPrice': 499000},
        ],
        'subTotal': 349000,
        'discount': 69800,
        'total': 279200,
        'coupon': {'code': 'GIAM20', 'valid': true, 'message': 'Giảm 69.800 đ'},
        'invalidItems': [
          {'id': 'KH02', 'reason': 'Bạn đã sở hữu khóa học này'},
        ],
        'paymentMethods': [
          {'id': 'Napas', 'name': 'Thẻ ATM nội địa', 'enabled': true},
          {'id': 'Visa/Mastercard', 'name': 'Thẻ quốc tế', 'enabled': false, 'reason': 'Chưa hỗ trợ'},
        ],
      });
      expect(q.couponCode, 'GIAM20');
      expect(q.invalidItems.single.courseId, 'KH02');
      expect(q.paymentMethods.first.enabled, isTrue);
      expect(q.paymentMethods.last.enabled, isFalse);
      expect(q.paymentMethods.last.reason, 'Chưa hỗ trợ');
    });

    test('mã sai không được áp dụng', () {
      final q = CartQuote.fromJson({
        'subTotal': 100,
        'discount': 0,
        'total': 100,
        'coupon': {'code': 'SAI', 'isValid': false, 'message': 'Mã hết hạn'},
      }, requestedCoupon: 'SAI');
      expect(q.couponCode, isNull);
      expect(q.couponMessage, 'Mã hết hạn');
    });
  });
}
