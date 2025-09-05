import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:redactly/theme/app_colors.dart';

Future<void> showAboutDialogCustom({
  required BuildContext context,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      const maxW = 720.0;
      const maxH = 520.0;

      return AlertDialog(
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.all(16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Body (zweispaltig)
              Flexible(
                fit: FlexFit.loose,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linke Spalte: großes Logo
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Rechte Spalte: Text
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Redactly',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Local text anonymization with placeholder mapping. '
                                  'No cloud. Your data stays on your device.',
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 14),

                            const _FeatureBullet(
                              leading: '•',
                              textSpans: [
                                TextSpan(text: ' Create '),
                                TextSpan(text: 'sessions', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' to keep work organized and re-usable.'),
                              ],
                            ),
                            const _FeatureBullet(
                              leading: '•',
                              textSpans: [
                                TextSpan(text: ' Select text and use '),
                                TextSpan(text: 'Set Placeholder', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' – or define custom mappings.'),
                              ],
                            ),
                            const _FeatureBullet(
                              leading: '•',
                              textSpans: [
                                TextSpan(text: ' One click to '),
                                TextSpan(text: 'Anonymize', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' the original text into placeholders.'),
                              ],
                            ),
                            const _FeatureBullet(
                              leading: '•',
                              textSpans: [
                                TextSpan(text: ' Send anonymized text to an LLM to rewrite, then '),
                                TextSpan(text: 'De-anonymize', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' to restore real names.'),
                              ],
                            ),
                            const _FeatureBullet(
                              leading: '•',
                              textSpans: [
                                TextSpan(text: ' Precise search with '),
                                TextSpan(text: 'Match Case', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' and '),
                                TextSpan(text: 'Whole Word', style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' options.'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                children: [
                  const Text(
                    'Open-source licenses of Flutter and included packages can be viewed here: ',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => LicensePage(
                            applicationName: 'Redactly',
                            // HINWEIS: Legalese siehe Kommentar unten
                            applicationLegalese:
                            '© 2024–${DateTime.now().year} Tilo Schmidtsdorff (Plain Tools) — All rights reserved.',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Open Licenses',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.cPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Footer mit Version
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (c, snap) {
                  final version = snap.data?.version ?? '';
                  final build = snap.data?.buildNumber ?? '';
                  final isNumericBuild = int.tryParse(build) != null;
                  final showBuild = isNumericBuild && build != version && build.isNotEmpty;
                  final versionLabel = showBuild ? '$version ($build)' : version;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        versionLabel,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.leading, required this.textSpans});
  final String leading;
  final List<TextSpan> textSpans;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(leading, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                children: textSpans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
