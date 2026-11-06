import 'package:flutter/material.dart';

import '../../../data/repositories/recommendation_repository.dart';
import '../../widgets/course_card.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';

class PersonalRecommendationsScreen extends StatefulWidget {
  const PersonalRecommendationsScreen({super.key, required this.repository});
  final RecommendationRepository repository;

  @override
  State<PersonalRecommendationsScreen> createState() =>
      _PersonalRecommendationsScreenState();
}

class _PersonalRecommendationsScreenState
    extends State<PersonalRecommendationsScreen> {
  PersonalRecommendations? _result;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = refresh
          ? await widget.repository.refreshPersonal()
          : await widget.repository.personal();
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Khóa học gợi ý')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    result == null
                        ? 'Gợi ý dành cho bạn'
                        : '${result.total} khóa học phù hợp',
                  ),
                ),
                TextButton.icon(
                  onPressed: _loading ? null : () => _load(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(_loading ? 'Đang làm mới...' : 'Làm mới'),
                ),
              ],
            ),
          ),
          if (_error != null && result != null)
            ListTile(
              title: Text(errorMessage(_error)),
              trailing: TextButton(
                onPressed: () => _load(refresh: true),
                child: const Text('Thử lại'),
              ),
            ),
          Expanded(
            child: result == null
                ? (_loading
                      ? const LoadingView()
                      : ErrorView(error: _error, onRetry: _load))
                : result.items.isEmpty
                ? const EmptyView(
                    title: 'Chưa có khóa học phù hợp',
                    message: 'Hãy khám phá và tương tác thêm với các khóa học.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: result.items.length,
                    itemBuilder: (context, index) {
                      final course = result.items[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CourseCard(
                            course: course,
                            badges: [result.badge ?? 'Phù hợp với bạn'],
                            layout: CourseCardLayout.listHorizontal,
                            onTap: () => CourseDetailScreen.open(
                              context,
                              course,
                              'recommend',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
