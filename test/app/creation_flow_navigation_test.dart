import 'package:doc_scanly/app/creation_module.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Back from Enhance reopens Crop with the same edited page', () async {
    const original = PageDraft(
      id: PageId('page'),
      originalImagePath: '/page.jpg',
    );
    final cropped = original.copyWith(thumbnailPath: '/cropped.jpg');
    final enhanced = cropped.copyWith(thumbnailPath: '/enhanced.jpg');
    final cropInputs = <PageDraft>[];
    var enhanceCalls = 0;

    final result = await editNewPageReversibly(
      original,
      openCrop: (page) async {
        cropInputs.add(page);
        return cropped;
      },
      openEnhance: (_) async {
        enhanceCalls++;
        return enhanceCalls == 1 ? null : enhanced;
      },
    );

    expect(cropInputs, [original, cropped]);
    expect(result, enhanced);
  });

  test('cancelling Crop abandons the new page', () async {
    final result = await editNewPageReversibly(
      const PageDraft(id: PageId('page'), originalImagePath: '/page.jpg'),
      openCrop: (_) async => null,
      openEnhance: (_) async => fail('Enhance must not open'),
    );

    expect(result, isNull);
  });
}
