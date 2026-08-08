/// Capability-driven camera-resolution Settings screen.
library;

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lists only resolution choices the active camera can satisfy.
class CameraResolutionScreen extends StatefulWidget {
  /// Creates the screen.
  const CameraResolutionScreen({required this.onBack, super.key});

  /// Returns to the parent Settings screen.
  final VoidCallback onBack;

  @override
  State<CameraResolutionScreen> createState() => _CameraResolutionScreenState();
}

class _CameraResolutionScreenState extends State<CameraResolutionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadCameraResolutionOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: SettingsKeys.cameraResolutionScreen,
      appBar: AppBar(
        title: const Text('Camera resolution'),
        leading: BackButton(onPressed: widget.onBack),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => SafeArea(
          child: switch (state.cameraResolutionStatus) {
            CameraResolutionStatus.idle ||
            CameraResolutionStatus.loading => const AppLoadingIndicator(
              semanticsLabel: 'Loading camera resolutions',
            ),
            CameraResolutionStatus.failure => AppErrorView(
              failure: state.cameraResolutionFailure ?? const Failure.camera(),
              onRetry: context
                  .read<SettingsCubit>()
                  .loadCameraResolutionOptions,
              retryKey: SettingsKeys.cameraResolutionRetry,
            ),
            CameraResolutionStatus.unavailable => _ResolutionList(
              state: state,
              capabilitiesUnavailable: true,
            ),
            CameraResolutionStatus.supported => _ResolutionList(state: state),
          },
        ),
      ),
    );
  }
}

class _ResolutionList extends StatelessWidget {
  const _ResolutionList({
    required this.state,
    this.capabilitiesUnavailable = false,
  });

  final SettingsState state;
  final bool capabilitiesUnavailable;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final supported = state.supportedCameraResolutions;
    final desired = state.settings.cameraResolution;
    final maximum = const DesiredCameraResolution.fullResolution().resolve(
      supported,
    );
    final resolved = desired.resolve(supported);
    final selectedTier = desired.when<CameraResolutionTier?>(
      fullResolution: () => null,
      tier: (tier) => tier,
    );
    final fellBack =
        selectedTier != null &&
        resolved != null &&
        resolved.tier != selectedTier;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Choose source capture dimensions before cropping and PDF '
              'quality scaling.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (capabilitiesUnavailable)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Exact choices are unavailable. Full resolution requests '
                  'the camera’s maximum and uses the actual captured size.',
                ),
              ),
            if (fellBack)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${selectedTier.label} is unavailable on this camera. '
                  'Using ${resolved.displayLabel}.',
                ),
              ),
            const SizedBox(height: 12),
            _ResolutionOption(
              optionKey: SettingsKeys.cameraResolutionOption('full'),
              title: 'Full resolution',
              dimensions: maximum == null
                  ? 'Camera maximum'
                  : '${maximum.width} × ${maximum.height}',
              selected: desired is FullCameraResolution,
              onSelected: () => cubit.setCameraResolution(
                const DesiredCameraResolution.fullResolution(),
              ),
            ),
            for (final resolution in supported)
              _ResolutionOption(
                optionKey: SettingsKeys.cameraResolutionOption(
                  resolution.tier.id,
                ),
                title: resolution.tier.label,
                dimensions: '${resolution.width} × ${resolution.height}',
                selected: selectedTier == resolution.tier,
                onSelected: () => cubit.setCameraResolution(
                  DesiredCameraResolution.tier(resolution.tier),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResolutionOption extends StatelessWidget {
  const _ResolutionOption({
    required this.optionKey,
    required this.title,
    required this.dimensions,
    required this.selected,
    required this.onSelected,
  });

  final Key optionKey;
  final String title;
  final String dimensions;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, $dimensions',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: RadioGroup<bool>(
        groupValue: selected,
        onChanged: (_) => onSelected(),
        child: RadioListTile<bool>(
          key: optionKey,
          value: true,
          title: Text(title),
          subtitle: Text(dimensions),
        ),
      ),
    );
  }
}
