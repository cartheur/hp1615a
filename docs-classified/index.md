# HP 1615A Document Classification Index

This folder is organized so an agent can reason about HP 1615A measurement behavior, front-end loading, probe wiring, self-tests, adjustments, and repair flow without rereading raw PDFs each time.

## Document Registry

### HP 1615A Operating And Service Manual

- File: `docs-classified/logic-analyzer/01615-90904.md`
- Source PDF: `docs/01615-90904.pdf`
- Category: `logic-analyzer-operating-and-service-manual`
- Best for: instrument setup, timing/state capture behavior, self-tests, performance tests, adjustments, troubleshooting, schematic navigation, and board-level repair
- Fault domains:
  - analyzer does not trigger, arms incorrectly, or captures incoherent timing/state data
  - front-panel or display anomalies
  - self-test failures
  - input threshold, setup/hold, or timing qualification misunderstandings
  - power supply, timing, display, or acquisition board adjustment/service work
- High-value sections:
  - `Section III`: operating behavior and measurement setup
  - `Section IV`: performance tests and verification fixtures
  - `Section V`: adjustments
  - `Section VIII`: troubleshooting, self-test interpretation, signature analysis, schematics
- Figures: `docs-classified/logic-analyzer/01615-90904/figures/`

### HP 10248C Eight-Bit Data Probe Operating Note

- File: `docs-classified/probes/10248-90805.md`
- Source PDF: `docs/10248-90805.pdf`
- Category: `probe-operating-note`
- Best for: probe electrical loading, threshold range, grounding, glitch capture integrity, probe cable usage, and compatibility with the 1615A
- Fault domains:
  - suspect DUT loading or overvoltage at the probe tip
  - false glitches caused by grounding or cable arrangement
  - threshold mismatch between DUT logic family and analyzer setup
  - uncertainty about which probe/accessory is valid for a measurement
- High-value sections:
  - `Description` and specifications
  - `Input Signal Grounding`
  - `Principles Of Operation`
- Figures: `docs-classified/probes/10248-90805/figures/`

## Agent Usage Rules

- Use the `1615A` manual first when the question is about analyzer behavior, verification, or internal faults.
- Use the `10248C` note first when the question is really about the measurement connection itself: probe loading, thresholding, grounding, or glitch integrity.
- When OCR text is ambiguous, cite the page number from the Markdown and inspect the matching page image in the sibling `figures/` directory.
- For DUT diagnosis, separate instrument faults from measurement-condition faults:
  - instrument fault candidates usually live in `Sections IV`, `V`, and `VIII` of the `1615A` manual
  - measurement-condition faults usually live in the `10248C` probe note plus the `1615A` operating examples in `Section III`
