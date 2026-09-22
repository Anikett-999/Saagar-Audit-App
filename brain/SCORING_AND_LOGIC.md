# Scoring Engine & Operational Mathematical Logic

Location: `phase-1/lib/domain/score_engine.dart`  
Tests: `phase-1/test/score_engine_test.dart` (Must pass 100%)

## 1. Core Mathematical Formula
$$\text{Compliance } \% = \operatorname{round}\left(\frac{\sum \text{Weighted Points Earned}}{\sum \text{Weighted Points Maximum}} \times 100,\; 1\right)$$

- **PASS ('P')**: Earns full checkpoint weight (1 or 2). Max score adds weight.
- **FAIL ('F')**: Earns 0 points. Max score adds weight.
- **N/A ('NA')**: Checkpoint is completely removed from both earned points and maximum score. Does not penalize or inflate percentage.
- **All N/A Edge Case**: Treated as 100.0% Excellent rather than divide-by-zero.

## 2. Strict Band Boundaries (Spec §6.2)
- **Excellent**: $\ge 95.0\%$
- **Good**: $90.0\% - 94.9\%$
- **Fair**: $85.0\% - 89.9\%$ *(89.9% is strictly Fair, not Good)*
- **Poor**: $80.0\% - 84.9\%$ *(84.9% is strictly Poor, not Fair)*
- **Critical**: $< 80.0\%$

## 3. Canonical Test Case (Workbook §5.1)
Must produce:
- Earned: 81
- Max: 90
- Compliance: 90.0%
- Band: Good
- Counts: 62 Pass, 6 Fail, 0 NA.
