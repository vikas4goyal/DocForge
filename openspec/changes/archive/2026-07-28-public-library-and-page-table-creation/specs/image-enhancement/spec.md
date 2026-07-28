## MODIFIED Requirements

### Requirement: Enhancement performance
Enhancement processing SHALL run off the UI thread and SHALL keep the preview responsive.

#### Scenario: Processing off the UI thread
- **WHEN** an enhancement is applied to a full-resolution page
- **THEN** the processing runs in a background isolate and the UI remains responsive

#### Scenario: Preview uses a downscaled image
- **WHEN** the enhancement preview is rendered
- **THEN** it is computed from a downscaled copy of the page so interaction stays responsive, while the saved result is computed at full resolution

#### Scenario: Preview keeps up with adjustments
- **WHEN** the user moves an adjustment slider continuously
- **THEN** previews are coalesced so that at most one render is in flight and the most recent settings are the ones shown when it completes

## ADDED Requirements

### Requirement: Enhancement is per page
The enhancement screen SHALL apply its settings to exactly one page — the page it was opened for — and SHALL NOT offer any control that applies settings to other pages.

#### Scenario: Only the opened page is affected
- **WHEN** the user enhances one page of a multi-page document
- **THEN** only that page is affected and every other page is left exactly as it was

#### Scenario: No bulk control offered
- **WHEN** the enhancement screen is displayed
- **THEN** no apply-to-all control is present, regardless of how many pages the document has

#### Scenario: Each page keeps its own settings
- **WHEN** the user enhances two pages with different settings
- **THEN** each page retains the settings chosen for it

### Requirement: Enhancement is entered from crop and from a page row
The enhancement screen SHALL be reachable from the crop screen's Next control when a page is being added, and from a page row's enhance control afterwards, and SHALL behave identically from both.

#### Scenario: Entered while adding a page
- **WHEN** the user continues from the crop screen while adding a page
- **THEN** the enhancement screen is displayed for the cropped working image, and finishing it appends the page to the page table

#### Scenario: Entered from a row
- **WHEN** the user activates the enhance control on a page row
- **THEN** the enhancement screen is displayed for that page, and finishing it updates that row in place without changing its position

#### Scenario: Finishing returns to the page table
- **WHEN** the user finishes enhancement by activating the done control with key `enhance_done_button`
- **THEN** the page table is displayed with the page's row showing the enhanced result

#### Scenario: Leaving without finishing
- **WHEN** the user leaves the enhancement screen without finishing
- **THEN** no enhancement is recorded, and a page being added is not appended to the table

### Requirement: Enhancement is settings over the cropped page, never baked in
The enhancement screen SHALL derive its preview and its result from the page's original image with its crop layer applied, plus the current settings, and SHALL never apply enhancement to an already-enhanced image.

#### Scenario: Reopening shows the previous settings
- **WHEN** the user enhances a page, leaves, and opens enhancement for that page again
- **THEN** the settings the user last chose are shown, and the preview is the page at its current crop with those settings applied

#### Scenario: Enhancement follows a later crop
- **WHEN** the user enhances a page and then crops it further
- **THEN** the same enhancement settings are applied to the newly cropped result without the user re-entering them

#### Scenario: Enhancement does not compound
- **WHEN** the user applies a strong contrast increase, leaves, reopens enhancement and returns the contrast to its default
- **THEN** the resulting page is visually identical to the unenhanced page at its current crop

#### Scenario: Revert enhancement returns the settings to their defaults
- **WHEN** the user activates the revert control with key `enhance_revert_button`
- **THEN** every enhancement setting returns to its default

#### Scenario: Reverting enhancement keeps the crop
- **WHEN** the user reverts the enhancement of a page that has been cropped
- **THEN** the page is shown unenhanced but still cropped, at its cropped size, and its crop and rotation are unchanged

#### Scenario: Revert disabled when nothing is enhanced
- **WHEN** the page's enhancement settings are already at their defaults
- **THEN** the revert control is disabled

## REMOVED Requirements

### Requirement: Enhancement applies per page and in bulk
**Reason**: Pages are now added one at a time in a simple loop — pick or capture, crop, enhance, done — so at the moment a page is enhanced there is no session of other pages to apply the settings to. Applying one page's settings to pages shot under different light was also the case the per-page loop exists to avoid.
**Migration**: The `enhance_apply_to_all_button` control, the bulk progress indicator `enhance_progress_indicator` and its cancel control are removed, along with `PlanSessionEnhancement` and the batch progress and cancellation state. A user who wants the same settings on several pages applies them per page from each row's enhance control. Per-page behaviour is specified by the `Enhancement is per page` requirement above.
