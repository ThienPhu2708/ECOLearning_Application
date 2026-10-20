import 'package:flutter/material.dart';
import 'models/category.dart';
import 'models/coupon.dart';
import 'models/course.dart';
import 'models/lesson.dart';
import 'models/user.dart';

/// Toàn bộ dữ liệu giả lập (Mock Data) chuẩn hóa từ data.js
/// Cung cấp dữ liệu tĩnh cho phân hệ Học viên (Learner)
class MockData {
  MockData._();

  // 1. Học viên hiện tại
  static final User currentUser = User(
    id: 'user-learner-01',
    fullName: 'Hải Yến',
    email: 'haiyen.learner@gmail.com',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80',
    phone: '0987 654 321',
    completedCoursesCount: 1,
    inProgressCoursesCount: 2,
    joinDate: 'Tháng 01/2026',
  );

  // 2. Danh mục khóa học
  static final List<Category> categories = [
    const Category(
      id: 'all',
      name: 'Tất cả',
      icon: Icons.auto_awesome_rounded,
      emoji: '⚡',
      coursesCount: 24,
    ),
    const Category(
      id: 'code',
      name: 'Lập trình',
      icon: Icons.code_rounded,
      emoji: '💻',
      coursesCount: 12,
    ),
    const Category(
      id: 'design',
      name: 'UI/UX Design',
      icon: Icons.brush_rounded,
      emoji: '🎨',
      coursesCount: 6,
    ),
    const Category(
      id: 'ai',
      name: 'AI & Data',
      icon: Icons.psychology_rounded,
      emoji: '🤖',
      coursesCount: 8,
    ),
    const Category(
      id: 'marketing',
      name: 'Marketing',
      icon: Icons.campaign_rounded,
      emoji: '📢',
      coursesCount: 5,
    ),
    const Category(
      id: 'business',
      name: 'Kinh doanh',
      icon: Icons.trending_up_rounded,
      emoji: '💼',
      coursesCount: 4,
    ),
  ];

  // 3. Danh sách từ khóa xu hướng
  static const List<String> trendingKeywords = [
    'Flutter',
    'Figma',
    'Python AI',
    'ReactJS',
    'Machine Learning',
    'UI/UX Design',
  ];

  // 4. Danh sách các bài học mẫu cho Flutter course
  static List<Chapter> createFlutterChapters() {
    return [
      Chapter(
        id: 'ch-1',
        title: 'Chương 1: Tổng quan và Khởi tạo kiến trúc nền tảng',
        lessons: [
          Lesson(
            id: 'les-1-1',
            title: '1.1 Giới thiệu kiến trúc nền tảng & Tổng quan Flutter 3.x',
            duration: '12:40',
            durationSeconds: 760,
            isCompleted: true,
            isFree: true,
            videoSummary: 'Tìm hiểu tổng quan về widget tree, engine và setup.',
          ),
          Lesson(
            id: 'les-1-2',
            title: '1.2 Thiết lập Design System (Màu sắc, Typography, Tokens)',
            duration: '18:25',
            durationSeconds: 1105,
            isCompleted: true,
            isFree: false,
            isCurrent: true,
            lastPositionSeconds: 900,
            videoSummary: 'Quy chuẩn bảng màu #434CE8 và font Plus Jakarta Sans.',
          ),
          Lesson(
            id: 'les-1-3',
            title: '1.3 Tạo khung sườn và cấu trúc điều hướng linh hoạt',
            duration: '22:10',
            durationSeconds: 1330,
            isCompleted: false,
            isFree: false,
            videoSummary: 'Xây dựng Bottom Navigation Bar và routing.',
          ),
          Lesson(
            id: 'les-1-4',
            title: '1.4 Xây dựng thẻ Course Card tỉ lệ chuẩn 16:9',
            duration: '21:50',
            durationSeconds: 1310,
            isCompleted: false,
            isFree: false,
            videoSummary: 'Hoàn thiện card responsive và trạng thái tương tác.',
          ),
        ],
      ),
      Chapter(
        id: 'ch-2',
        title: 'Chương 2: Xây dựng Trình phát Video Player & Logic Tích xanh',
        lessons: [
          Lesson(
            id: 'les-2-1',
            title: '2.1 Tích hợp Video Player với thanh điều khiển tùy biến',
            duration: '16:15',
            durationSeconds: 975,
            isCompleted: false,
            isFree: false,
            videoSummary: 'Tua 10 giây, điều chỉnh tốc độ 0.75x - 2.0x.',
          ),
          Lesson(
            id: 'les-2-2',
            title: '2.2 Cơ chế tự động đánh dấu tích xanh khi xem >= 80%',
            duration: '19:40',
            durationSeconds: 1180,
            isCompleted: false,
            isFree: false,
            videoSummary: 'Thuật toán theo dõi tiến độ thời gian thực.',
          ),
          Lesson(
            id: 'les-2-3',
            title: '2.3 Kích hoạt Modal Popup đánh giá 5 sao khi đạt >= 70%',
            duration: '14:50',
            durationSeconds: 890,
            isCompleted: false,
            isFree: false,
            videoSummary: 'Đánh giá chất lượng và phản hồi từ học viên.',
          ),
        ],
      ),
    ];
  }

  // 5. Khóa học Collaborative Filtering Top Match (98% Fit)
  static final Course topMatchCourse = Course(
    id: 'course-cf-1',
    title: 'Machine Learning & Data Science với Python Toàn Diện',
    category: 'AI & Data',
    instructor: 'TS. Lê Hoàng Nam',
    instructorRole: 'Trưởng nhóm AI Research & Giảng viên ĐH Quốc Gia',
    instructorAvatar:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    rating: 4.95,
    reviewCount: 520,
    price: 1190000,
    originalPrice: 2000000,
    imageUrl:
        'https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?w=800&auto=format&fit=crop&q=80',
    tag: '✨ YOUR TOP MATCH: 98% FIT',
    level: 'Trung cấp',
    duration: '36 giờ',
    lessonsCount: 48,
    progress: 0,
    isEnrolled: false,
    isCompleted: false,
    description:
        'Khóa học trang bị đầy đủ kiến thức Toán ứng dụng, Pandas, NumPy, Scikit-learn, hồi quy, phân loại và thuật toán Collaborative Filtering tiên tiến.',
    outcomes: [
      'Nắm vững toán đại số tuyến tính & xác suất ứng dụng trong AI.',
      'Thành thạo thư viện Pandas, NumPy, Scikit-Learn và PyTorch cơ bản.',
      'Tự tay xây dựng hệ thống gợi ý sản phẩm/khóa học (Recommendation System).',
      'Hoàn thành 3 đồ án ứng dụng thực chiến đưa vào CV nghề nghiệp.',
    ],
    chapters: [
      Chapter(
        id: 'cf-ch-1',
        title: 'Chương 1: Nền tảng Python & Xử lý dữ liệu với Pandas',
        lessons: [
          Lesson(
            id: 'cf-les-1',
            title: '1.1 Tổng quan Machine Learning trong kỷ nguyên AI',
            duration: '15:20',
            durationSeconds: 920,
            isCompleted: false,
            isFree: true,
          ),
          Lesson(
            id: 'cf-les-2',
            title: '1.2 Phân tích khám phá dữ liệu (EDA) thực chiến',
            duration: '24:10',
            durationSeconds: 1450,
            isCompleted: false,
            isFree: true,
          ),
        ],
      ),
      Chapter(
        id: 'cf-ch-2',
        title: 'Chương 2: Xây dựng hệ thống gợi ý Collaborative Filtering',
        lessons: [
          Lesson(
            id: 'cf-les-3',
            title: '2.1 Thuật toán User-Based & Item-Based Filtering',
            duration: '28:45',
            durationSeconds: 1725,
            isCompleted: false,
            isFree: false,
          ),
        ],
      ),
    ],
  );

  // 6. Danh sách toàn bộ các khóa học trên hệ thống
  static final List<Course> allCourses = [
    topMatchCourse,
    Course(
      id: 'course-enrolled-1',
      title: 'Flutter & Dart Toàn Diện: Xây Dựng Mobile App Chuyên Nghiệp',
      category: 'Lập trình',
      instructor: 'ThS. Nguyễn Văn An',
      instructorRole: 'Senior Mobile Architect tại VinTech',
      instructorAvatar:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      rating: 4.90,
      reviewCount: 380,
      price: 890000,
      originalPrice: 1500000,
      imageUrl:
          'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=800&auto=format&fit=crop&q=80',
      tag: 'BÁN CHẠY',
      level: 'Mọi cấp độ',
      duration: '32 giờ',
      lessonsCount: 45,
      progress: 85.0, // Đã đạt >= 80% (trigger tích xanh & đánh giá)
      isEnrolled: true,
      isCompleted: false,
      description:
          'Lộ trình bài bản giúp bạn làm chủ Flutter framework, quản lý State, gọi API, xử lý offline và hoàn thiện đồ án Mobile E-Learning.',
      outcomes: [
        'Làm chủ ngôn ngữ Dart 3 và Flutter framework mới nhất.',
        'Xây dựng các màn hình responsive thích ứng mọi kích thước smartphone.',
        'Thực thi đầy đủ các chức năng xem video, đánh giá và cấp chứng chỉ.',
      ],
      chapters: createFlutterChapters(),
    ),
    Course(
      id: 'course-enrolled-2',
      title: 'Thiết Kế Giao Diện UI/UX Chuyên Nghiệp Với Figma Masterclass',
      category: 'UI/UX Design',
      instructor: 'Trần Minh Quân',
      instructorRole: 'Lead Product Designer',
      instructorAvatar:
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150&auto=format&fit=crop&q=80',
      rating: 4.88,
      reviewCount: 640,
      price: 849000,
      originalPrice: 1200000,
      imageUrl:
          'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=800&auto=format&fit=crop&q=80',
      tag: 'XU HƯỚNG',
      level: 'Cơ bản',
      duration: '24 giờ',
      lessonsCount: 32,
      progress: 100.0, // Đã hoàn thành 100% -> Xem chứng chỉ
      isEnrolled: true,
      isCompleted: true,
      description:
          'Học cách xây dựng Design System, Auto-layout, Typography, Color Tokens và tương tác Prototype chân thực như sản phẩm thật.',
      outcomes: [
        'Thiết kế Design System hoàn chỉnh cho dự án Web & Mobile.',
        'Thành thạo Auto Layout, Component variants và Variables trong Figma.',
        'Xuất file và phối hợp hiệu quả cùng đội ngũ kỹ sư phần mềm.',
      ],
      chapters: [
        Chapter(
          id: 'fig-ch-1',
          title: 'Chương 1: Làm chủ Figma & Tư duy thiết kế UI/UX',
          lessons: [
            Lesson(
              id: 'fig-les-1',
              title: '1.1 Tổng quan về UX Research & Wireframing',
              duration: '20:15',
              durationSeconds: 1215,
              isCompleted: true,
              isFree: true,
            ),
            Lesson(
              id: 'fig-les-2',
              title: '1.2 Xây dựng Color System & Typography Scale',
              duration: '25:30',
              durationSeconds: 1530,
              isCompleted: true,
              isFree: true,
            ),
          ],
        ),
      ],
    ),
    Course(
      id: 'course-free-1',
      title: 'Khởi Đầu Lập Trình Web: HTML5, CSS3 & JavaScript Cơ Bản',
      category: 'Lập trình',
      instructor: 'Phạm Quốc Hùng',
      instructorRole: 'Fullstack Web Engineer',
      instructorAvatar:
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
      rating: 4.75,
      reviewCount: 890,
      price: 0, // Khóa học miễn phí
      originalPrice: 500000,
      imageUrl:
          'https://images.unsplash.com/photo-1593720213428-28a5b9e94613?w=800&auto=format&fit=crop&q=80',
      tag: 'MIỄN PHÍ',
      level: 'Cơ bản',
      duration: '18 giờ',
      lessonsCount: 28,
      progress: 0,
      isEnrolled: false,
      isCompleted: false,
      description:
          'Khóa học miễn phí 100% giúp người mới bắt đầu làm quen với kiến trúc Web, Semantic HTML5, CSS Grid, Flexbox và JS ES6+.',
      outcomes: [
        'Nắm chắc cú pháp HTML5 ngữ nghĩa và chuẩn SEO cơ bản.',
        'Dựng trang web responsive tương thích smartphone và máy tính.',
        'Lập trình tương tác sự kiện JavaScript cơ bản.',
      ],
      chapters: [
        Chapter(
          id: 'web-ch-1',
          title: 'Chương 1: HTML5 & CSS3 Cơ Bản',
          lessons: [
            Lesson(
              id: 'web-les-1',
              title: '1.1 Cài đặt VS Code và cấu trúc file HTML chuẩn',
              duration: '10:00',
              durationSeconds: 600,
              isCompleted: false,
              isFree: true,
            ),
          ],
        ),
      ],
    ),
    Course(
      id: 'course-react-1',
      title: 'React & Next.js Thực Chiến: Xây Dựng Ứng Dụng Quy Mô Lớn',
      category: 'Lập trình',
      instructor: 'Vũ Đình Long',
      instructorRole: 'Tech Lead tại FPT Software',
      instructorAvatar:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
      rating: 4.92,
      reviewCount: 410,
      price: 990000,
      originalPrice: 1600000,
      imageUrl:
          'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800&auto=format&fit=crop&q=80',
      tag: 'BÁN CHẠY',
      level: 'Chuyên sâu',
      duration: '40 giờ',
      lessonsCount: 52,
      progress: 0,
      isEnrolled: false,
      isCompleted: false,
      description:
          'Trang bị kỹ năng React 19, Server Components, Next.js App Router, TailwindCSS và tối ưu SEO điểm 100 Lighthouse.',
      outcomes: [
        'Làm chủ Next.js Server Components và Server Actions.',
        'Quản lý State quy mô lớn với Zustand và React Query.',
        'Deploy ứng dụng lên Vercel và tối ưu Core Web Vitals.',
      ],
      chapters: [],
    ),
    Course(
      id: 'course-mkt-1',
      title: 'Digital Marketing Thực Chiến: SEO, Ads & Content AI 2026',
      category: 'Marketing',
      instructor: 'Đặng Thu Thảo',
      instructorRole: 'Marketing Director',
      instructorAvatar:
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      rating: 4.80,
      reviewCount: 295,
      price: 750000,
      originalPrice: 1300000,
      imageUrl:
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&auto=format&fit=crop&q=80',
      tag: 'MỚI',
      level: 'Mọi cấp độ',
      duration: '20 giờ',
      lessonsCount: 30,
      progress: 0,
      isEnrolled: false,
      isCompleted: false,
      description:
          'Chiến lược tăng trưởng Marketing đa kênh thời đại AI: Tối ưu công cụ tìm kiếm SEO, chạy quảng cáo Meta/Google và sáng tạo nội dung.',
      outcomes: [
        'Xây dựng kế hoạch Marketing đa kênh tổng thể.',
        'Ứng dụng AI tạo kịch bản video viral và bài viết chuẩn SEO.',
        'Tối ưu tỷ lệ chuyển đổi (CRO) và chi phí quảng cáo ROI.',
      ],
      chapters: [],
    ),
  ];

  // 7. Mã giảm giá có sẵn
  static final List<Coupon> availableCoupons = [
    const Coupon(
      code: 'CHAOMUNG2026',
      discountPercent: 20.0,
      description: 'Giảm 20% cho học viên mới mừng năm học 2026',
      isValid: true,
    ),
    const Coupon(
      code: 'KLTN2026',
      discountPercent: 50.0,
      description: 'Ưu đãi 50% đồ án Khóa luận Tốt nghiệp CNTT',
      isValid: true,
    ),
  ];

  // 8. Danh sách khóa học trong Giỏ hàng ban đầu
  static List<Course> cartItems = [
    allCourses.firstWhere((c) => c.id == 'course-react-1'),
  ];
}
