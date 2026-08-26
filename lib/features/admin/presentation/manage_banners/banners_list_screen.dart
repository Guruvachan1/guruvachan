import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../home/providers/home_provider.dart';
import '../../../../models/home_banner.dart';

class BannersListScreen extends ConsumerWidget {
  const BannersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(allBannersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Home Banners')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/banners/create');
          ref.invalidate(allBannersProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Banner'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allBannersProvider),
        child: bannersAsync.when(
          loading: () => const AppLoadingWidget(),
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load banners',
            onRetry: () => ref.invalidate(allBannersProvider),
          ),
          data: (banners) {
            if (banners.isEmpty) {
              return const EmptyStateWidget(
                title: 'No banners yet',
                subtitle: 'Add your first home banner',
                icon: Icons.image_rounded,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: banner.imageUrl,
                        width: 80,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      banner.title.isNotEmpty ? banner.title : 'Banner ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: banner.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            banner.isActive ? 'Active' : 'Inactive',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: banner.isActive ? Colors.green : Colors.grey,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order: ${banner.displayOrder}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await context.push(
                            '/admin/banners/edit/${banner.id}',
                            extra: banner.toJson()..['id'] = banner.id,
                          );
                          ref.invalidate(allBannersProvider);
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Banner'),
                              content: const Text('Are you sure?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref.read(bannerRepositoryProvider).deleteBanner(banner.id);
                            ref.invalidate(allBannersProvider);
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
