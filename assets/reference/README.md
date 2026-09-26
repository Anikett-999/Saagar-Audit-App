# Reference JSON

Loaded into S22–S26 (Reference tab) — wired up in Week 4.

| File | Source | Status |
|---|---|---|
| `rating_scale.json` | Spec §11.1 + Workbook A.4 | Authored (5 bands + 3 tier targets + reminder) |
| `escalation_triggers.json` | Spec §11.2 + Workbook A.5 | Authored (7 triggers + 4-part message format + 3 examples) |
| `evidence.json` | Spec §11.3 + Workbook A.6 (8 strong, 8 weak) | Authored (8 strong, 8 weak + warning banner) |
| `glossary.json` | Workbook A.7 (65 EN–MR–Meaning rows) | Authored (65 bilingual terms & meanings) |

Glossary format per Spec §11.4:
```json
[
  { "en": "Audit",  "mr": "[MR]",  "meaning_en": "...", "meaning_mr": "[MR]" }
]
```
