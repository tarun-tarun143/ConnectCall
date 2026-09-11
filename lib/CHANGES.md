ConnectCall UI Upgrade v3

Compatibility cleanup based on the project's latest flutter analyze output.

Fixed:
- Removed the unavailable ThemeController/AuthService dependencies from the upgraded HomeScreen constructor.
- Kept HomeScreen compatible with the existing HomeShell call site.
- Replaced wildcard underscore callback parameters that triggered duplicate_definition.
- Kept the Zego invitation button arguments compatible with the installed package.
- Corrected async BuildContext guards in call-history clearing.
- Preserved the visual redesign and existing Firebase/ZEGOCLOUD architecture.
