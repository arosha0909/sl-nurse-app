import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../core/widgets/text_prompt_dialog.dart';
import 'roster_review_screen.dart';
import '../onboarding/progressive_prompts.dart';
import 'roster_widgets.dart';

/// Step 1 of the OCR import: choose the month and a photo of the roster.
class RosterScanScreen extends StatefulWidget {
  const RosterScanScreen({super.key, this.picker});

  /// Injectable for tests.
  final ImagePicker? picker;

  /// Opens the screen, asking once for the primary hospital/ward first (skippable).
  static Future<void> open(BuildContext context) async {
    await ProgressivePrompts.ensureWorkplace(context);
    if (context.mounted) await Navigator.of(context).push(route());
  }

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const RosterScanScreen());

  @override
  State<RosterScanScreen> createState() => _RosterScanScreenState();
}

class _RosterScanScreenState extends State<RosterScanScreen> {
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  late DateTime _month;
  final _rowLabel = TextEditingController();
  bool _busy = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final today = AppScope.of(context).today();
    // Rosters are usually published for the coming month in the last week.
    _month = today.day >= 20
        ? DateTime(today.year, today.month + 1)
        : DateTime(today.year, today.month);
  }

  @override
  void dispose() {
    _rowLabel.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      // Downscaled + JPEG-compressed on device: faster upload, plenty for OCR.
      file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 85,
      );
    } catch (e) {
      if (mounted) {
        context.showMessage(
          'Couldn\'t open the ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
        );
      }
      return;
    }
    if (file == null) return; // cancelled
    final bytes = await file.readAsBytes();
    await _scan(
      imageBytes: bytes,
      filename: file.name,
      mimeType: file.mimeType ?? _mimeFor(file.name),
    );
  }

  static String _mimeFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  Future<void> _pasteText() async {
    final text = await TextPromptDialog.show(
      context,
      const TextPromptDialog(
        title: 'Paste roster text',
        hint: '01 M\n02 N OT 4\n03 CL\n…',
        helper: "Text from your phone's text scanner works too",
        maxLines: 8,
        confirmLabel: 'Read',
      ),
    );
    if (text != null && text.trim().isNotEmpty) await _scan(rawText: text);
  }

  Future<void> _scan({
    List<int>? imageBytes,
    String? filename,
    String? mimeType,
    String? rawText,
  }) async {
    setState(() => _busy = true);
    final scope = AppScope.of(context);
    try {
      final result = await scope.repository.scanRoster(
        month: _month.month,
        year: _month.year,
        imageBytes: imageBytes,
        filename: filename,
        mimeType: mimeType,
        rawText: rawText,
        rowLabel: _rowLabel.text.trim(),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        RosterReviewScreen.route(result: result, month: _month),
      );
    } catch (e) {
      if (mounted) context.showMessage('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = AppScope.of(context).today();

    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    const PageHeader(title: 'Scan Roster'),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Roster month', style: text.titleMedium),
                        ),
                        MonthSwitcher(
                          month: _month,
                          min: DateTime(today.year, today.month - 2),
                          max: DateTime(today.year, today.month + 2),
                          onChanged: (m) => setState(() => _month = m),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rowLabel,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Your name as printed (optional)',
                        helperText:
                            'For ward rosters with one row per nurse, e.g. "K. PERERA"',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SourceCard(
                            icon: Icons.photo_camera_outlined,
                            title: 'Take photo',
                            color: AppColors.lavender,
                            iconColor: AppColors.lavenderDeep,
                            onTap: _busy
                                ? null
                                : () => _pick(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gap),
                        Expanded(
                          child: _SourceCard(
                            icon: Icons.photo_library_outlined,
                            title: 'From gallery',
                            color: AppColors.peach,
                            iconColor: AppColors.peachDeep,
                            onTap: _busy
                                ? null
                                : () => _pick(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.gap),
                    PastelCard(
                      color: AppColors.sky,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                color: AppColors.skyDeep,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text('For a clean read', style: text.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final tip in const [
                            'Lay the roster flat in good light',
                            'Fill the frame and hold the phone straight',
                            'Include the row of day numbers',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('•  $tip', style: text.bodyMedium),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _busy ? null : _pasteText,
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: const Text('Paste roster text instead'),
                      ),
                    ),
                  ],
                ),
                if (_busy)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.background.withValues(alpha: 0.85),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.lavenderDeep,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Reading your ${Fmt.monthYear(_month)} roster…',
                              style: text.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PastelCard(
      color: color,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
      child: Column(
        children: [
          IconBadge(icon: icon, iconColor: iconColor, size: 58),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
