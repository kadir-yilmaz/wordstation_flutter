import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/no_internet_dialog.dart';
import '../controllers/word_list_controller.dart';
import '../models/word_model.dart';

class AddEditWordPage extends ConsumerStatefulWidget {
  final WordModel? wordToEdit;
  final String? initialListName;

  const AddEditWordPage({
    super.key,
    this.wordToEdit,
    this.initialListName,
  });

  @override
  ConsumerState<AddEditWordPage> createState() => _AddEditWordPageState();
}

class _AddEditWordPageState extends ConsumerState<AddEditWordPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _enController;
  late TextEditingController _trController;
  late TextEditingController _exampleController;
  late String _selectedListName;
  bool _isLoading = false;

  bool get _isEditing => widget.wordToEdit != null;

  @override
  void initState() {
    super.initState();
    _enController = TextEditingController(text: widget.wordToEdit?.en ?? '');
    _trController = TextEditingController(text: widget.wordToEdit?.tr ?? '');
    _exampleController =
        TextEditingController(text: widget.wordToEdit?.example ?? '');
    _selectedListName = widget.wordToEdit?.listName ??
        widget.initialListName ??
        'General';
  }

  @override
  void dispose() {
    _enController.dispose();
    _trController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final word = WordModel(
      id: widget.wordToEdit?.id,
      en: _enController.text.trim(),
      tr: _trController.text.trim(),
      example: _exampleController.text.trim(),
      listName: _selectedListName.trim().isEmpty
          ? 'General'
          : _selectedListName.trim(),
      userId: widget.wordToEdit?.userId,
    );

    bool success;
    if (_isEditing) {
      success =
          await ref.read(wordListControllerProvider.notifier).updateWord(word);
    } else {
      success =
          await ref.read(wordListControllerProvider.notifier).addWord(word);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(word);
    } else if (!success && mounted) {
      final err = ref.read(wordListControllerProvider).errorMessage;
      if (err != null && DioErrorHandler.isNetworkError(err)) {
        NoInternetDialog.show(
          context,
          onRetry: () async {
            final ok = _isEditing
                ? await ref
                    .read(wordListControllerProvider.notifier)
                    .updateWord(word)
                : await ref
                    .read(wordListControllerProvider.notifier)
                    .addWord(word);
            if (ok && mounted) {
              Navigator.of(context).pop(word);
            } else {
              throw Exception('Retry failed');
            }
          },
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kelimeyi Sil'),
        content: Text(
          '"${widget.wordToEdit!.en}" kelimesini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      final success = await ref
          .read(wordListControllerProvider.notifier)
          .deleteWord(widget.wordToEdit!.id);
      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (!success && mounted) {
        final err = ref.read(wordListControllerProvider).errorMessage;
        if (err != null && DioErrorHandler.isNetworkError(err)) {
          NoInternetDialog.show(
            context,
            onRetry: () async {
              final ok = await ref
                  .read(wordListControllerProvider.notifier)
                  .deleteWord(widget.wordToEdit!.id);
              if (ok && mounted) {
                Navigator.of(context).pop();
              } else {
                throw Exception('Retry failed');
              }
            },
          );
        }
      }
    }
  }

  Future<String?> _showCreateListDialog(
      BuildContext context, bool isDark) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          title: const Text('Yeni Liste Oluştur'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Liste Adı (Örn: B2, Phrasal Verbs)',
              hintStyle: TextStyle(
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final text = controller.text.trim();
                Navigator.of(ctx).pop(text.isNotEmpty ? text : null);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Widget _buildListDropdown(bool isDark, List<String> availableLists) {
    final options = <String>[...availableLists];
    if (!options.contains(_selectedListName) &&
        _selectedListName.trim().isNotEmpty) {
      options.insert(0, _selectedListName);
    }
    if (options.isEmpty) {
      options.add('General');
    }

    final selectedValue = options.contains(_selectedListName)
        ? _selectedListName
        : options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste / Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              items: [
                ...options.map((name) => DropdownMenuItem<String>(
                      value: name,
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.turquoise
                                : const Color(0xFF12C6B2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const DropdownMenuItem<String>(
                  value: '__CREATE_NEW__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: Color(0xFF34C759),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '+ Yeni Liste Oluştur...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) async {
                if (val == '__CREATE_NEW__') {
                  final newName = await _showCreateListDialog(context, isDark);
                  if (newName != null && newName.trim().isNotEmpty) {
                    setState(() {
                      _selectedListName = newName.trim();
                    });
                  }
                } else if (val != null) {
                  setState(() {
                    _selectedListName = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listNames = ref
        .watch(wordListControllerProvider)
        .listNames
        .where((l) => l != 'Tümü' && l != 'All')
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Kelimeyi Düzenle' : 'Yeni Kelime Ekle',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              tooltip: 'Kelimeyi Sil',
              onPressed: _isLoading ? null : _handleDelete,
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isEditing ? 'Güncelleniyor...' : 'Kaydediliyor...',
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Liste / Kategori Dropdown
                  _buildListDropdown(isDark, listNames),
                  const SizedBox(height: 18),

                  // 2. İngilizce Kelime
                  CustomTextField(
                    controller: _enController,
                    label: 'İngilizce Kelime (Word)',
                    hintText: 'Örn: ubiquitous',
                    prefixIcon: Icons.translate_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Lütfen İngilizce kelimeyi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 3. Türkçe Anlamı
                  CustomTextField(
                    controller: _trController,
                    label: 'Türkçe Anlamı (Meaning)',
                    hintText: 'Örn: her yerde bulunan, yaygın',
                    prefixIcon: Icons.language_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Lütfen Türkçe anlamını girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // 4. Örnek Cümle
                  CustomTextField(
                    controller: _exampleController,
                    label: 'Örnek Cümle (İsteğe bağlı)',
                    hintText:
                        'Örn: Smartphones have become ubiquitous in daily life.',
                    prefixIcon: null,
                    minLines: 4,
                    maxLines: null,
                  ),
                  const SizedBox(height: 28),

                  // 5. Kaydet Butonu
                  CustomButton(
                    text: _isEditing ? 'Değişiklikleri Kaydet' : 'Kelimeyi Ekle',
                    onPressed: _handleSave,
                    variant: ButtonVariant.primary,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
