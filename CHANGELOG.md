# Changelog

All notable changes to LowLevelQuestToggle will be documented here.

## [1.0.3] - 2026-03-08

### Fixed
- Tracking menu items (e.g. Track Fish) now respond correctly on the first click instead of requiring two clicks
- The low-level quest checkbox in the minimap tracking menu now correctly reflects state changes made via the addon button
- Removed `RefreshTrackingFrame` logic that was forcing the minimap tracking button to rebuild on each interaction, causing the extra click requirement
- Scoped the minimap menu hook to only affect the low-level quest checkbox — previously it overrode the checkbox state function for all tracking types, which caused incorrect behaviour for unrelated tracking items

## [1.0.2] - 2026-03-05

### Added
- Initial public release
- Button anchored to the Quest Tracker to toggle low-level quest visibility
- Shift+Drag to reposition the button
- Button position saved between sessions
- Minimap tracking menu reflects the current low-level quest tracking state
- Slash commands: `/llqt`, `/lowlevelquests`
  - `on` / `off` — enable or disable low-level quest tracking
  - `show` / `hide` — show or hide the toggle button
  - `reset` — reset button to default position
  - `debug` — print tracking type info to chat
  - `help` — list all commands
- Syncs button state when tracking is changed via the minimap menu
