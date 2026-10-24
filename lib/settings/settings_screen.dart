import 'dart:async';

import 'package:costing_master/common/enums.dart';
import 'package:costing_master/costings/quote/quote_card.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/empty_state.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "મારો બિઝનેસ": business profile, quote design and app theme, with a live
/// preview of the quote so the user sees exactly what they are creating.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The form is only built once the saved settings are known, so it never
    // starts empty and overwrites them.
    return switch (ref.watch(settingsProvider)) {
      AsyncValue(:final value?) => _SettingsForm(initial: value),
      AsyncError() => Scaffold(
          appBar: AppBar(title: const Text('મારો બિઝનેસ')),
          body: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'સેટિંગ્સ લોડ ન થયા',
            message: 'ઇન્ટરનેટ તપાસીને ફરી પ્રયત્ન કરો',
            actionLabel: 'ફરી પ્રયત્ન કરો',
            onAction: () => ref.invalidate(settingsProvider),
          ),
        ),
      _ => Scaffold(
          appBar: AppBar(title: const Text('મારો બિઝનેસ')),
          body: const Center(child: CircularProgressIndicator()),
        ),
    };
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final AppSettings initial;
  const _SettingsForm({required this.initial});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  // Kept so pending edits can still be saved from dispose(), where ref is gone.
  late final SettingsNotifier _notifier = ref.read(settingsProvider.notifier);
  late final AppSettings _initial = widget.initial;
  late BusinessProfile _profile = _initial.profile;
  late final _business = TextEditingController(text: _profile.businessName);
  late final _owner = TextEditingController(text: _profile.ownerName);
  late final _phone = TextEditingController(text: _profile.phone);
  late final _city = TextEditingController(text: _profile.city);
  late final _tagline = TextEditingController(text: _profile.tagline);
  Timer? _debounce;
  bool _uploadingLogo = false;

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      final profile = _profileFromFields();
      final notifier = _notifier;
      // Saved after unmount completes; listeners must not rebuild mid-dispose.
      scheduleMicrotask(() => notifier
          .edit((s) => s.copyWith(profile: profile, profilePrompted: true))
          .catchError((Object _) {}));
    }
    for (final c in [_business, _owner, _phone, _city, _tagline]) {
      c.dispose();
    }
    super.dispose();
  }

  BusinessProfile _profileFromFields() => _profile.copyWith(
        businessName: _business.text.trim(),
        ownerName: _owner.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
        tagline: _tagline.text.trim(),
      );

  void _onProfileChanged(String _) {
    setState(() => _profile = _profileFromFields());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _flushProfile);
  }

  void _flushProfile() {
    final profile = _profileFromFields();
    if (!mapEquals(profile.toMap(), _notifier.current.profile.toMap())) {
      _save((s) => s.copyWith(profile: profile, profilePrompted: true));
    }
  }

  void _save(AppSettings Function(AppSettings) change) {
    _notifier.edit(change).catchError((Object _) {
      if (mounted) {
        showAppSnack(context, 'સેવ ન થયું · Could not save settings',
            type: SnackType.error);
      }
    });
  }

  Future<void> _pickLogo() async {
    final storage = ref.read(imageStorageProvider);
    final file = await storage.pick(fromCamera: false, maxWidth: 512);
    if (file == null || !mounted) return;
    setState(() => _uploadingLogo = true);
    try {
      final uid = _notifier.uid ?? 'user';
      final url = await storage.upload(file,
          fileName: 'logo_${uid}_${DateTime.now().millisecondsSinceEpoch}');
      setState(() => _profile = _profileFromFields().copyWith(logoUrl: url));
      _save((s) => s.copyWith(profile: _profile));
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'લોગો અપલોડ ન થયો', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? _initial;
    final style = settings.quoteStyle;
    void setStyle(QuoteStyle s) => _save((all) => all.copyWith(quoteStyle: s));

    return Scaffold(
      appBar: AppBar(title: const Text('મારો બિઝનેસ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const _SectionTitle('લાઇવ પ્રિવ્યૂ', 'Live preview of your quote'),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 300,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  child: QuoteCard(
                    key: ValueKey(style),
                    costing: _sampleCosting,
                    clientName: 'શ્રી ટેક્સટાઇલ્સ',
                    profile: _profile,
                    style: style,
                    mode: QuoteMode.customer,
                    date: DateTime.now(),
                  ),
                ),
              ),
            ),
          ),
          const _SectionTitle('બિઝનેસ', 'Shown at the top of every quote'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: _uploadingLogo ? null : _pickLogo,
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: context.colors.primaryContainer,
                          child: _uploadingLogo
                              ? const CircularProgressIndicator()
                              : _profile.logoUrl.isEmpty
                                  ? Icon(Icons.add_photo_alternate_outlined,
                                      color: context.colors.onPrimaryContainer)
                                  : ClipOval(
                                      child: SizedBox.square(
                                        dimension: 68,
                                        child:
                                            NetworkThumb(url: _profile.logoUrl),
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _Field(_business, 'બિઝનેસનું નામ',
                            'Business name', _onProfileChanged),
                      ),
                    ],
                  ),
                  if (_profile.logoUrl.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() => _profile =
                              _profileFromFields().copyWith(logoUrl: ''));
                          _save((s) => s.copyWith(profile: _profile));
                        },
                        child: const Text('લોગો કાઢો · Remove logo'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _Field(_tagline, 'ટેગલાઇન', 'e.g. હેન્ડવર્ક સ્પેશિયાલિસ્ટ',
                      _onProfileChanged),
                  const SizedBox(height: 12),
                  _Field(
                      _owner, 'માલિકનું નામ', 'Owner name', _onProfileChanged),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(_phone, 'ફોન', 'Phone', _onProfileChanged,
                            keyboard: TextInputType.phone),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(_city, 'શહેર', 'City', _onProfileChanged),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const _SectionTitle('કોસ્ટિંગની ડિઝાઇન', 'Quote design'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<QuoteTemplate>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: QuoteTemplate.royal, label: Text('રોયલ')),
                      ButtonSegment(
                          value: QuoteTemplate.classic, label: Text('ક્લાસિક')),
                      ButtonSegment(
                          value: QuoteTemplate.minimal, label: Text('સાદી')),
                    ],
                    selected: {style.template},
                    onSelectionChanged: (s) =>
                        setStyle(style.copyWith(template: s.first)),
                  ),
                  const SizedBox(height: 16),
                  Text('રંગ · Accent', style: context.text.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < quoteAccents.length; i++)
                        _Swatch(
                          color: quoteAccents[i],
                          selected: style.accentIndex == i,
                          onTap: () => setStyle(style.copyWith(accentIndex: i)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Toggle('ફોટો બતાવો', 'Show design photo', style.showPhoto,
                      (v) => setStyle(style.copyWith(showPhoto: v))),
                  _Toggle(
                      'દરેક વસ્તુનો ભાવ',
                      'Show item-wise rows',
                      style.showItems,
                      (v) => setStyle(style.copyWith(showItems: v))),
                  _Toggle('તારીખ', 'Show date', style.showDate,
                      (v) => setStyle(style.copyWith(showDate: v))),
                  _Toggle(
                      'ગુજરાતી અંક (૧૨૩)',
                      'Gujarati numerals',
                      style.gujaratiDigits,
                      (v) => setStyle(style.copyWith(gujaratiDigits: v))),
                  _Toggle(
                      '"Made with કોસ્ટિંગ માસ્ટર"',
                      'Small footer line',
                      style.showFooter,
                      (v) => setStyle(style.copyWith(showFooter: v))),
                ],
              ),
            ),
          ),
          const _SectionTitle('એપ થીમ', 'App theme'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('ઓટો')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('લાઇટ')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('ડાર્ક')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) =>
                _save((all) => all.copyWith(themeMode: s.first)),
          ),
        ],
      ),
    );
  }
}

final _sampleCosting = Costing(
  guid: 'sample',
  createdBy: '',
  clientGuid: '',
  designNo: 108,
  sariName: 'રાની પટોળા',
  imageUrl: '',
  sheetBharvana: 60,
  lessFiting: 25,
  reniyaCutting: 10,
  fusing: 12,
  dieKapvana: 0,
  otherCost: 8,
  vatavPercentage: 2,
  profitPercentage: 12,
  totalExpense: 0,
  totalChargesPlusVatavAmount: 0,
  totalChargesPlusVatavPlusProfit: 0,
  diamondCostingsMap: {
    PartType.patti: {
      DiamondType.shadow: DiamondCosting(
        diamondType: DiamondType.shadow,
        partType: PartType.patti,
        diamondRate: 0.45,
        diamondsPerPart: 30,
        numbersOfPartsPerSari: 12,
      ),
    },
  },
  sagadiCostingsMap: {},
);

class _SectionTitle extends StatelessWidget {
  final String gu;
  final String en;
  const _SectionTitle(this.gu, this.en);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(
            text: gu,
            style: context.text.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        TextSpan(
            text: '   $en',
            style: context.text.labelMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ])),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;

  const _Field(this.controller, this.label, this.hint, this.onChanged,
      {this.keyboard});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboard,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle(this.title, this.subtitle, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.brand.gold : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
