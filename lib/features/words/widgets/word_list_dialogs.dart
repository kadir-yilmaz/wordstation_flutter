import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/no_internet_dialog.dart';
import '../controllers/word_list_controller.dart';

abstract final class WordListDialogs {
  static Future<void> showAddListDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final textController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'New List',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter a name for your new word list.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Name (e.g. YDS, TOEFL, A1)',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  final success = await ref
                      .read(wordListControllerProvider.notifier)
                      .createList(text);
                  if (!success && context.mounted) {
                    final err =
                        ref.read(wordListControllerProvider).errorMessage;
                    if (err != null && DioErrorHandler.isNetworkError(err)) {
                      NoInternetDialog.show(
                        context,
                        onRetry: () async {
                          final ok = await ref
                              .read(wordListControllerProvider.notifier)
                              .createList(text);
                          if (!ok) throw Exception('Failed');
                        },
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    textController.dispose();
  }

  static Future<void> showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String oldName,
  ) async {
    final textController = TextEditingController(text: oldName);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Rename List'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'New List Name',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  final success = await ref
                      .read(wordListControllerProvider.notifier)
                      .renameList(oldName, newName);
                  if (!success && context.mounted) {
                    final err =
                        ref.read(wordListControllerProvider).errorMessage;
                    if (err != null && DioErrorHandler.isNetworkError(err)) {
                      NoInternetDialog.show(
                        context,
                        onRetry: () async {
                          final ok = await ref
                              .read(wordListControllerProvider.notifier)
                              .renameList(oldName, newName);
                          if (!ok) throw Exception('Failed');
                        },
                      );
                    }
                  }
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    textController.dispose();
  }

  static Future<void> showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String listName,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete List'),
          content: Text(
            "'$listName' will be permanently deleted. Are you sure?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final success = await ref
                    .read(wordListControllerProvider.notifier)
                    .deleteList(listName);
                if (!success && context.mounted) {
                  final err =
                      ref.read(wordListControllerProvider).errorMessage;
                  if (err != null && DioErrorHandler.isNetworkError(err)) {
                    NoInternetDialog.show(
                      context,
                      onRetry: () async {
                        final ok = await ref
                            .read(wordListControllerProvider.notifier)
                            .deleteList(listName);
                        if (!ok) throw Exception('Failed');
                      },
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
