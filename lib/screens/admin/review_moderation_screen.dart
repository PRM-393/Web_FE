import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-ENGAGE-05 (F15): quan tri vien xem danh gia cua moi thuong hieu, an danh gia vi pham (bat buoc ly do,
// ghi AuditLog) hoac hien lai. Danh gia bi an khong tinh vao diem trung binh cua chien dich.
class ReviewModerationScreen extends StatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  State<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends State<ReviewModerationScreen> {
  static const _pageSize = 20;

  // null = tat ca
  String? _status;
  final List<Review> _items = [];
  int _page = 0;
  int _total = 0;
  bool _loading = false;
  bool _busy = false;
  String? _error;

  // Bo qua ket qua cua lan tai cu khi nguoi dung da doi bo loc
  int _generation = 0;

  AdminService get _service => context.read<AdminService>();

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    final generation = reset ? ++_generation : _generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
        _total = 0;
      }
    });
    try {
      final page = await _service.reviews(status: _status, page: _page + 1, pageSize: _pageSize);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _total = page.total;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  void _setFilter(String? status) {
    if (status == _status) return;
    _status = status;
    _load(reset: true);
  }

  Future<void> _hide(Review r) async {
    final reason = await promptTextDialog(
      context,
      title: 'Ẩn đánh giá',
      message: 'Đánh giá bị ẩn sẽ không hiển thị công khai và không tính vào điểm trung bình của chiến dịch.',
      label: 'Lý do ẩn',
      confirm: 'Ẩn',
      maxLines: 3,
    );
    if (reason == null) return;
    await _moderate(() => _service.hideReview(r.id, reason), r, 'Đã ẩn đánh giá.');
  }

  Future<void> _unhide(Review r) async {
    final ok = await confirmDialog(
      context,
      title: 'Hiện lại đánh giá',
      message: 'Đánh giá sẽ hiển thị công khai và được tính lại vào điểm trung bình của chiến dịch.',
      confirm: 'Hiện lại',
    );
    if (!ok) return;
    await _moderate(() => _service.unhideReview(r.id), r, 'Đã hiện lại đánh giá.');
  }

  // Cap nhat tai cho (khong tai lai ca danh sach); dang loc theo trang thai thi bo danh gia khong con khop
  Future<void> _moderate(Future<ReviewModeration> Function() action, Review r, String done) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((e) => e.id == r.id);
        if (index >= 0) {
          if (_status != null && result.review.status != _status) {
            _items.removeAt(index);
            _total = _total > 0 ? _total - 1 : 0;
          } else {
            _items[index] = r.withStatus(result.review.status);
          }
        }
      });
      final avg = result.avgRating;
      showMessage(
        context,
        avg == null
            ? '$done Chiến dịch chưa có đánh giá đang hiển thị.'
            : '$done Điểm trung bình chiến dịch: ${avg.toStringAsFixed(1)}',
      );
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminReviews,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Kiểm duyệt đánh giá',
              subtitle: _loading && _items.isEmpty ? null : '$_total đánh giá',
              actions: [
                IconButton(tooltip: 'Tải lại', onPressed: () => _load(reset: true), icon: const Icon(Icons.refresh)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (status, label) in const [
                    (null, 'Tất cả'),
                    (ReviewStatus.visible, 'Đang hiển thị'),
                    (ReviewStatus.hidden, 'Đã ẩn'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _status == status,
                      onSelected: (_) => _setFilter(status),
                    ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      );

  Widget _body() {
    if (_items.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error != null) {
        return MessageView(icon: Icons.cloud_off, message: _error!, onRetry: () => _load(reset: true));
      }
      return const MessageView(icon: Icons.inbox_outlined, message: 'Không có đánh giá nào.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      itemCount: _items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        if (i < _items.length) {
          final r = _items[i];
          return _ReviewCard(
            review: r,
            onHide: _busy || r.isHidden ? null : () => _hide(r),
            onUnhide: _busy || !r.isHidden ? null : () => _unhide(r),
          );
        }
        return _footer();
      },
    );
  }

  // F01: phan trang, tai them trang tiep theo
  Widget _footer() {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: CircularProgressIndicator()));
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      );
    }
    if (!_hasMore) return const SizedBox.shrink();
    return Center(
      child: OutlinedButton.icon(
        key: const Key('reviews-load-more'),
        onPressed: _load,
        icon: const Icon(Icons.expand_more),
        label: const Text('Tải thêm'),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, this.onHide, this.onUnhide});

  final Review review;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var s = 1; s <= 5; s++)
                  Icon(s <= r.rating ? Icons.star : Icons.star_border, color: AppColors.secondary, size: 20),
                const Spacer(),
                StatusChip(r.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [r.campaignTitle ?? 'Chiến dịch', if (r.brandName != null && r.brandName!.isNotEmpty) r.brandName!].join(' · '),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${r.reviewerName ?? 'Khách hàng'} · ${formatDateTime(r.createdAt)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (r.comment != null && r.comment!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(r.comment!),
            ],
            if (r.hasReply) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text('Phản hồi của thương hiệu: ${r.brandReply}'),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: r.isHidden
                  ? OutlinedButton.icon(
                      key: Key('review-unhide-${r.id}'),
                      onPressed: onUnhide,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Hiện lại'),
                    )
                  : OutlinedButton.icon(
                      key: Key('review-hide-${r.id}'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                      onPressed: onHide,
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Ẩn'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
