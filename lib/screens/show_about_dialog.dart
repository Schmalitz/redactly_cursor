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
      const maxW = 640.0;
      const maxH = 440.0;

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

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Redactly',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Local text anonymization with placeholder mapping. '
                            'No cloud. Your data stays on your device.',
                        style: TextStyle(fontSize: 14),
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
                                    applicationLegalese:
                                    '© 2024–${DateTime.now().year} Plain Tools — All rights reserved.',
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
                    ],
                  ),
                ),
              ),

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
