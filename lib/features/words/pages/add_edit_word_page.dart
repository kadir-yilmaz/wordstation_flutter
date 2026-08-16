import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_overlay.dart';
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
  late TextEditingController _listNameController;
  bool _isLoading = false;

  bool get _isEditing => widget.wordToEdit != null;

  @override
  void initState() {
    super.initState();
    _enController = TextEditingController(text: widget.wordToEdit?.en ?? '');
    _trController = TextEditingController(text: widget.wordToEdit?.tr ?? '');
    _exampleController =
        TextEditingController(text: widget.wordToEdit?.example ?? '');
    _listNameController = TextEditingController(
      text: widget.wordToEdit?.listName ??
          widget.initialListName ??
          'General',
    );
  }

  @override
  void dispose() {
    _enController.dispose();
    _trController.dispose();
    _exampleController.dispose();
    _listNameController.dispose();
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
      listName: _listNameController.text.trim().isEmpty
          ? 'General'
          : _listNameController.text.trim(),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listNames = ref
        .watch(wordListControllerProvider)
        .listNames
        .where((l) => l != 'Tümü')
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // English Word
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

                  // Turkish Meaning
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

                  // Example Sentence
                  CustomTextField(
                    controller: _exampleController,
                    label: 'Örnek Cümle (İsteğe bağlı)',
                    hintText: 'Örn: Smartphones have become ubiquitous in daily life.',
                    prefixIcon: Icons.format_quote_rounded,
                    minLines: 5,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 18),

                  // List / Category Name
                  CustomTextField(
                    controller: _listNameController,
                    label: 'Liste / Kategori',
                    hintText: 'Örn: A1, B2, TOEFL, General',
                    prefixIcon: Icons.folder_open_rounded,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSave(),
                  ),

                  // Quick Suggestion Chips for Lists
                  if (listNames.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: listNames.map((name) {
                        return ActionChip(
                          label: Text(name),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _listNameController.text == name
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                          ),
                          backgroundColor: _listNameController.text == name
                              ? AppColors.turquoise
                              : (isDark
                                  ? AppColors.darkSurface
                                  : Colors.grey.shade200),
                          onPressed: () {
                            setState(() {
                              _listNameController.text = name;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save Button
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
