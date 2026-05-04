Run the following grep commands against `lib/` (excluding `vendor/`) and report every result with file path, line number, the current code, and the correct replacement per CLAUDE.md rules.

```bash
# 1. Raw TextStyle — should be NarwhalTextStyle
grep -rn "TextStyle(" lib --include="*.dart" | grep -v vendor | grep -v NarwhalTextStyle | grep -v "//.*TextStyle"

# 2. Hardcoded Colors (non-transparent) — should be ThemeHelper.xxx(context)
grep -rn -E "Colors\.(red|blue|green|black|white|grey|gray|orange|yellow|pink|purple)" lib --include="*.dart" | grep -v vendor | grep -v "//"

# 3. Hardcoded hex colors — should be ThemeHelper colors
grep -rn -E "Color\(0x[Ff]{2}" lib --include="*.dart" | grep -v vendor | grep -v "// TODO"

# 4. Raw Icon(Icons.) — prefer NarwhalIcon(NarwhalIcons.xxx)
grep -rn " Icon(Icons\." lib --include="*.dart" | grep -v vendor

# 5. Raw CustomPainter — should extend NarwhalPainter
grep -rn "extends CustomPainter" lib --include="*.dart" | grep -v vendor | grep -v narwhal_paint

# 6. SizedBox.shrink() outside build() — prefer nil
grep -rn "SizedBox\.shrink()" lib --include="*.dart" | grep -v vendor
```

For every violation found, output:
- File path and line number
- The current violating code
- The correct replacement with explanation (referencing CLAUDE.md rules)

Then fix all violations found.
