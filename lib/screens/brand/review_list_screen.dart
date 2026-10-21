import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../routes.dart';
import '../../services/api_client.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-ENGAGE-04: thuong hieu xem danh gia va phan hoi mot lan cho moi danh gia.
// FR-ENGAGE-05: danh gia bi quan tri vien an van hien o day (kem nhan "Da bi an") va van phan hoi duoc.
class ReviewListScreen extends StatelessWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.brandReviews,
        child: BrandGate(builder: (context, brand) => _ReviewList(brand: brand)),
      );
}

class _ReviewList extends StatefulWidget {
  const _ReviewList({required this.brand});

  final Brand brand;

  @override
  State<_ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<_ReviewList> {
  late Future<List<Review>> _future;

  BrandService get _service => context.read<BrandService>();

  @override
  void initState() {
    super.initState();
    _future = _service.reviews(widget.brand.id);
  }

  void _reload() {
    setState(() {
      _future = _service.reviews(widget.brand.id);
    });
  }

  Future<void> _reply(Review review) async {
    final text = await promptTextDialog(context, title: 'Phản hồi đánh giá', label: 'Nội dung phản hồi', confirm: 'Gửi', maxLines: 4);
    if (text == null) return;
    try {
      await _service.replyReview(review.id, text);
      if (!mounted) return;
      showMessage(context, 'Đã gửi phản hồi.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, e.toString(), error: true);
      // Da co phan hoi truoc do (vd. tab khac): tai lai de hien phan hoi
      if (e is ApiException && e.reason == 'REVIEW_ALREADY_REPLIED') _reload();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Đánh giá của khách hàng',
            actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
          ),
          Expanded(
            child: AsyncBody<List<Review>>(
              future: _future,
              onRetry: _reload,
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có đánh giá nào.',
              builder: (context, reviews) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final r = reviews[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            for (var s = 1; s <= 5; s++)
                              Icon(s <= r.rating ? Icons.star : Icons.star_border, color: AppColors.secondary, size: 20),
                            const Spacer(),
                            Text(formatDateTime(r.createdAt), style: const TextStyle(color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (r.campaignTitle != null && r.campaignTitle!.isNotEmpty)
                                Text(r.campaignTitle!, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (r.isHidden) const StatusChip(ReviewStatus.hidden, label: 'Đã bị ẩn'),
                            ],
                          ),
                          Text(
                            r.reviewerName ?? 'Khách hàng',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (r.comment != null && r.comment!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(r.comment!),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          if (r.hasReply)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                              child: Text('Phản hồi: ${r.brandReply}'),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => _reply(r),
                              icon: const Icon(Icons.reply),
                              label: const Text('Phản hồi'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
}
