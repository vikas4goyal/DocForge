# Spec Delta

## ADDED Requirements

### Requirement: Export starts in the default save location
When a default save location is configured in Settings, every export SHALL ask the platform destination picker to start in that location. When none is configured, the picker SHALL open at its own default. A location the platform cannot honour SHALL NOT block or fail the export.

#### Scenario: Configured location offered
- **WHEN** a default save location is configured and the user activates `share_export_button` from the viewer's share sheet `share_options_sheet`
- **THEN** the platform destination picker is asked to start in the configured location, expressed in the form that platform accepts

#### Scenario: Ask each time
- **WHEN** no default save location is configured and the user activates `share_export_button`
- **THEN** the platform destination picker opens with no starting location requested

#### Scenario: Location changed since the sheet was last opened
- **WHEN** the user changes the default save location in Settings and then exports from a document without restarting
- **THEN** the newly configured location is the one offered

#### Scenario: Platform ignores or rejects the location
- **WHEN** the configured location no longer exists, is no longer accessible, or the platform picker does not support a starting location
- **THEN** the picker opens at its own default, the export completes normally, `Key('share_export_done')` confirms the destination actually chosen, and no error is shown about the starting location

#### Scenario: End-to-end export coverage
- **WHEN** the “share” end-to-end flow configures a default save location and exports
- **THEN** the faked platform export adapter records that it was asked to start in that location, and `share_export_done` is visible

## MODIFIED Requirements

### Requirement: Focused share surface
The application SHALL offer PDF sharing, ordered page-image sharing, printing, and platform export without presenting a Share Extracted Text action.

#### Scenario: Extracted text is not a share action
- **WHEN** the share options are displayed for a scanned or imported document
- **THEN** no `share_text_button` or “Share extracted text” option is present and the remaining actions stay reachable and correctly spaced
