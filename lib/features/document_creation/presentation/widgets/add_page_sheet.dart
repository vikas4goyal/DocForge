/// The sources a page can be added from.
library;

import 'package:doc_forge/features/document_creation/presentation/creation_keys.dart';
import 'package:flutter/material.dart';

/// Where a new page comes from.
enum PageSourceChoice {
  /// The device camera.
  camera,

  /// The photo library.
  gallery,
}

/// Offers the camera and the photo library.
///
/// Both go through the same loop afterwards — crop, then enhance, then a row —
/// so this sheet decides only where the pixels come from.
class AddPageSheet extends StatelessWidget {
  /// Creates the sheet.
  const AddPageSheet({required this.onChosen, super.key});

  /// Called with the chosen source.
  final void Function(PageSourceChoice choice) onChosen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: CreationKeys.addPageSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: CreationKeys.addFromCamera,
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            subtitle: const Text('Use the camera to capture a page'),
            onTap: () => onChosen(PageSourceChoice.camera),
          ),
          ListTile(
            key: CreationKeys.addFromGallery,
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from photos'),
            subtitle: const Text('Pick one or more images'),
            onTap: () => onChosen(PageSourceChoice.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
