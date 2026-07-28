import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_creation/domain/page_render_plan.dart';
import 'package:doc_forge/features/document_scanning/domain/page_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

CropOp crop([double inset = 0.1]) =>
    CropOp(quad: box(inset, inset, 1 - inset, 1 - inset));

const enhancement = EnhancementSettings(
  filter: EnhancementFilter.blackAndWhite,
  contrast: 0.4,
);

PageDraft draft() => const PageDraft(
  id: PageId('page-1'),
  originalImagePath: '/staging/page-1.jpg',
);

void main() {
  group('a fresh draft', () {
    test('has neither layer applied', () {
      expect(draft().hasGeometry, isFalse);
      expect(draft().hasEnhancement, isFalse);
    });

    test('renders as a pass-through', () {
      // Nothing has been done to it, so the original is already what the user
      // should see; rendering would copy a file for no reason.
      expect(PageRenderPlan.of(draft()).isPassThrough, isTrue);
    });
  });

  group('the geometry layer', () {
    test('a crop is appended rather than replacing the original', () {
      final cropped = draft().withCrop(crop());

      expect(cropped.geometry, hasLength(1));
      // The original is what makes reverting possible at all.
      expect(cropped.originalImagePath, draft().originalImagePath);
    });

    test('crops accumulate in the order they were applied', () {
      final twice = draft().withCrop(crop()).withCrop(crop(0.2));

      expect(twice.geometry, [crop(), crop(0.2)]);
    });

    test('an identity crop is not recorded', () {
      // A full-page selection at zero rotation changes nothing; lengthening
      // the chain with it would cost a resample for no visible difference.
      final unchanged = draft().withCrop(const CropOp(quad: PageQuad.full));

      expect(unchanged.geometry, isEmpty);
    });

    test('reverting clears every crop', () {
      final reverted = draft()
          .withCrop(crop())
          .withCrop(crop(0.2))
          .revertGeometry();

      expect(reverted.geometry, isEmpty);
      expect(reverted.hasGeometry, isFalse);
    });
  });

  group('the enhancement layer', () {
    test('is settings, not pixels', () {
      final enhanced = draft().withEnhancement(enhancement);

      expect(enhanced.enhancement, enhancement);
      expect(enhanced.originalImagePath, draft().originalImagePath);
    });

    test('reverting returns the settings to their defaults', () {
      final reverted = draft().withEnhancement(enhancement).revertEnhancement();

      expect(reverted.hasEnhancement, isFalse);
      expect(reverted.enhancement, EnhancementSettings.none);
    });
  });

  group('the layers are independent', () {
    test('reverting the crop keeps the enhancement', () {
      final both = draft().withCrop(crop()).withEnhancement(enhancement);

      final reverted = both.revertGeometry();

      // The user gets the full original frame back, still enhanced.
      expect(reverted.geometry, isEmpty);
      expect(reverted.enhancement, enhancement);
    });

    test('reverting the enhancement keeps the crop', () {
      final both = draft().withCrop(crop()).withEnhancement(enhancement);

      final reverted = both.revertEnhancement();

      // The page stays cropped, at its cropped size.
      expect(reverted.geometry, hasLength(1));
      expect(reverted.enhancement, EnhancementSettings.none);
    });

    test('cropping further does not disturb the enhancement', () {
      final enhanced = draft().withEnhancement(enhancement);

      final cropped = enhanced.withCrop(crop());

      // The same settings re-apply to the newly cropped result, without the
      // user re-entering them and without being applied twice.
      expect(cropped.enhancement, enhancement);
    });

    test('enhancing does not disturb the geometry', () {
      final cropped = draft().withCrop(crop());

      expect(cropped.withEnhancement(enhancement).geometry, cropped.geometry);
    });
  });

  group('thumbnails', () {
    test('a cached thumbnail is dropped when the geometry changes', () {
      final withThumbnail = draft().copyWith(thumbnailPath: '/cache/t.jpg');

      expect(withThumbnail.withCrop(crop()).thumbnailPath, isNull);
    });

    test('a cached thumbnail is dropped when the enhancement changes', () {
      final withThumbnail = draft().copyWith(thumbnailPath: '/cache/t.jpg');

      expect(withThumbnail.withEnhancement(enhancement).thumbnailPath, isNull);
    });

    test('a cached thumbnail is dropped on either revert', () {
      final edited = draft()
          .withCrop(crop())
          .withEnhancement(enhancement)
          .copyWith(thumbnailPath: '/cache/t.jpg');

      expect(edited.revertGeometry().thumbnailPath, isNull);
      expect(edited.revertEnhancement().thumbnailPath, isNull);
    });
  });

  group('toPageRef', () {
    test('carries the original, not a rendered result', () {
      final edited = draft().withCrop(crop()).withEnhancement(enhancement);

      final reference = edited.toPageRef();

      // Composition applies both layers itself; handing it a rendered image
      // would apply the enhancement twice.
      expect(reference.imagePath, '/staging/page-1.jpg');
      expect(reference.enhancement, enhancement);
      expect(reference.id, const PageId('page-1'));
    });
  });

  group('equality', () {
    test('drafts with the same layers are equal', () {
      expect(draft().withCrop(crop()), draft().withCrop(crop()));
      expect(
        draft().withCrop(crop()).hashCode,
        draft().withCrop(crop()).hashCode,
      );
    });

    test('a different crop chain is a different draft', () {
      expect(draft().withCrop(crop()), isNot(draft().withCrop(crop(0.2))));
    });

    test('a different enhancement is a different draft', () {
      expect(draft().withEnhancement(enhancement), isNot(draft()));
    });
  });

  group('PageRenderPlan', () {
    test('describes both layers of a draft', () {
      final edited = draft().withCrop(crop()).withEnhancement(enhancement);

      final plan = PageRenderPlan.of(edited);

      expect(plan.originalImagePath, '/staging/page-1.jpg');
      expect(plan.geometry, edited.geometry);
      expect(plan.enhancement, enhancement);
      expect(plan.isPassThrough, isFalse);
    });

    test('an unchanged plan keeps its cache key', () {
      final edited = draft().withCrop(crop());

      expect(
        PageRenderPlan.of(edited).cacheKey,
        PageRenderPlan.of(edited).cacheKey,
      );
    });

    test('a changed crop invalidates the key', () {
      expect(
        PageRenderPlan.of(draft().withCrop(crop())).cacheKey,
        isNot(PageRenderPlan.of(draft().withCrop(crop(0.2))).cacheKey),
      );
    });

    test('a changed enhancement invalidates the key', () {
      expect(
        PageRenderPlan.of(draft().withEnhancement(enhancement)).cacheKey,
        isNot(PageRenderPlan.of(draft()).cacheKey),
      );
    });

    test('a preview and a full render do not share a key', () {
      final edited = draft().withCrop(crop());

      expect(
        PageRenderPlan.of(edited).cacheKey,
        isNot(PageRenderPlan.of(edited, scale: RenderScale.full).cacheKey),
      );
    });

    test('the key is safe as a file name', () {
      final key = PageRenderPlan.of(draft().withCrop(crop())).cacheKey;

      expect(key, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });

    test('atScale changes only the scale', () {
      final plan = PageRenderPlan.of(draft().withCrop(crop()));

      final full = plan.atScale(RenderScale.full);

      expect(full.scale, RenderScale.full);
      expect(full.geometry, plan.geometry);
      expect(full.enhancement, plan.enhancement);
    });

    test('equal plans compare equal', () {
      expect(PageRenderPlan.of(draft()), PageRenderPlan.of(draft()));
      expect(
        PageRenderPlan.of(draft()).hashCode,
        PageRenderPlan.of(draft()).hashCode,
      );
    });
  });
}
