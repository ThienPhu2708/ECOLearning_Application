import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_utils.dart';

class QuizSkillsCard extends StatelessWidget {
  const QuizSkillsCard({super.key, required this.skills, this.results = false});
  final List<Map<String, dynamic>> skills;
  final bool results;
  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              results ? 'Kết quả từng kỹ năng' : 'Kỹ năng và điều kiện đạt',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              results
                  ? 'Theo ngưỡng áp dụng khi bắt đầu lượt thi.'
                  : 'Cần đạt tổng điểm và tất cả kỹ năng bắt buộc.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            for (final skill in skills)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            JsonUtils.asString(skill['name']),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (results)
                          Text(
                            JsonUtils.asBool(skill['passed'])
                                ? 'Đạt'
                                : 'Chưa đạt',
                            style: TextStyle(
                              color: JsonUtils.asBool(skill['passed'])
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${results ? '${JsonUtils.asInt(skill['correct'])}/' : ''}${JsonUtils.asInt(skill['total'])} câu · Ngưỡng ${JsonUtils.asInt(skill['passPercent'])}%${JsonUtils.asBool(skill['required']) ? ' · Bắt buộc' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
