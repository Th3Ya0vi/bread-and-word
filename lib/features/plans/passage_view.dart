import 'package:flutter/material.dart';

import '../../services/youversion/versions.dart';
import '../../services/youversion/youversion_client.dart';
import '../../services/youversion/youversion_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../plans/plan_catalog.dart';

/// Reads one or more passages live from YouVersion (in the member's chosen
/// version) and renders them as quiet, readable Scripture. Shared by the plan
/// day reader and the live-room "now reading" sheet.
class PassageView extends StatefulWidget {
  const PassageView({super.key, required this.references});

  final List<String> references;

  @override
  State<PassageView> createState() => _PassageViewState();
}

class _PassageViewState extends State<PassageView> {
  final _yv = YouVersionClient();
  late Future<List<Passage>> _future;
  int _versionId = BiblePrefs.instance.versionId.value;

  @override
  void initState() {
    super.initState();
    _future = _load();
    BiblePrefs.instance.versionId.addListener(_onVersionChanged);
  }

  void _onVersionChanged() {
    if (!mounted) return;
    setState(() {
      _versionId = BiblePrefs.instance.versionId.value;
      _future = _load();
    });
  }

  Future<List<Passage>> _load() async {
    final out = <Passage>[];
    for (final ref in widget.references) {
      out.add(await _yv.passage(ref, bibleId: _versionId));
    }
    return out;
  }

  @override
  void dispose() {
    BiblePrefs.instance.versionId.removeListener(_onVersionChanged);
    _yv.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Passage>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text('Gathering the passage…',
                  style: AppType.flourish(15)),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'We couldn’t reach the Scripture just now. Check your connection '
              'and try again.',
              style: AppType.body(16, color: AppColors.inkFaded),
            ),
          );
        }
        final passages = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < passages.length; i++) ...[
              if (i > 0) const SizedBox(height: 26),
              Text(
                passages[i].reference.isNotEmpty
                    ? passages[i].reference
                    : prettyRef(widget.references[i]),
                style: AppType.mono(10, color: AppColors.accent),
              ),
              const SizedBox(height: 10),
              Text(
                passages[i].text,
                style: AppType.body(19, color: AppColors.ink).copyWith(
                  height: 1.62,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text('${versionById(_versionId).abbreviation} · YouVersion',
                style: AppType.mono(9, color: AppColors.inkGhost)),
          ],
        );
      },
    );
  }
}
