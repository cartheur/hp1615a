# HP 1615A Agent Repair Playbook

This playbook is the fast path for an agent diagnosing HP `1615A` logic-analyzer faults and bad measurement conditions while probing a DUT.

## Scope

- Primary analyzer source: `docs-classified/logic-analyzer/01615-90904.md`
- Primary probe source: `docs-classified/probes/10248-90805.md`
- Figure source for schematics, waveforms, and locator drawings:
  - `docs-classified/logic-analyzer/01615-90904/figures/`
  - `docs-classified/probes/10248-90805/figures/`

## Source Of Truth Rules

- Treat the `1615A` operating and service manual as canonical for analyzer behavior, self-tests, verification, adjustments, troubleshooting flow, and board-level repair.
- Treat the `10248C` probe note as canonical when the likely problem is front-end loading, threshold mismatch, grounding, false glitch pickup, or misuse of probe cabling.
- When OCR text is unclear, cite the Markdown page number and inspect the matching rendered page image.

## First Split: Instrument Fault Or Measurement Fault

Ask this first:

1. Does the symptom move when threshold, ground, probe routing, or pod assignment changes?
2. Does the `1615A` pass its built-in self-tests?
3. Is the failure present on one pod or probe only, or does it affect the whole instrument?

Treat it as a measurement-condition problem first when:

- the DUT appears to glitch only when long flying leads are attached
- changing threshold changes the symptom dramatically
- one probe pod behaves differently from the others
- asynchronous captures produce suspicious false triggers

Treat it as an instrument fault first when:

- the power-up test fails
- the display is blank or incoherent independent of the DUT
- keyboard or self-test modes fail
- built-in test clocks or operator tests fail without any external DUT attached

## Fast Triage Workflow

1. Run the built-in checks from `1615A` Section III before assuming a board fault.
   - `Power-up self test`: pages `16`, `32`
   - `Keyboard self test`: page `32`
   - `Data acquisition self test`: page `33`
   - `DSA loop modes`: page `33`
2. If the unit fails self-test, route into `Section VIII` troubleshooting instead of changing DUT hookup.
3. If the unit passes self-test but captures look wrong, verify probe grounding and thresholding before touching internal adjustments.
   - `1615A` threshold setup: page `16`
   - `10248C` grounding and threshold behavior: pages `2` to `3`
4. Only after the above should you use `Section IV` performance tests and `Section V` adjustments.

## Symptom Routing

## 1. No Boot Or Power-Up Failure

Use when:

- no normal format screen appears after turn-on
- display shows `POWER UP FAILED`
- display shows `ERROR IN ROM #` or `ERROR IN RAM`
- display shows `TEST FAILED, STATUS = ...` during startup

Primary pages:

- power-up behavior and failure messages: `1615A` pages `16`, `32`
- self-test escalation and status-code interpretation entry point: `1615A` pages `33`, `4`
- troubleshooting with status codes / self-test / signature analysis: `1615A` `Section VIII`, especially pages `4` onward in the service section

Agent actions:

1. Record the exact startup message.
2. Distinguish `ROM/RAM/display-logic` startup faults from later acquisition faults.
3. Run keyboard and data-acquisition self-tests if startup allows it.
4. Use `Section VIII` status-code and mnemonic tables to localize the failing logic region.

## 2. Keyboard Or Front-Panel Problems

Use when:

- keys do not respond
- a stuck key is suspected
- menu navigation is inconsistent

Primary pages:

- keyboard self-test procedure: `1615A` page `32`
- keyboard stuck-key note: `1615A` page `32`
- keyboard assembly location and replaceable parts: `1615A` pages `53` to `56`

Agent actions:

1. Run the `A-key at power-up` keyboard self-test.
2. Note the `LAST KEY #` and `NEXT KEY #` behavior.
3. If the keyboard test fails consistently, use the exploded views and replaceable-parts section to isolate keyboard assembly `A10`.

## 3. Trigger Never Happens Or Capture Looks Wrong

Use when:

- `NO TRIGGER`, `NO 8 BIT TRIGGER`, or `NO 16 BIT TRIGGER` persists
- trigger occurs at the wrong time
- trigger is not in memory
- trace delay or trigger occurrence settings seem to misbehave

Primary pages:

- status messages: `1615A` page `32`
- timing/state mode behavior and trigger concepts: `1615A` pages `14` to `18`
- core trigger and glitch limits: `1615A` page `8`
- dual-mode trigger interactions: `1615A` pages `29` to `31`

Agent actions:

1. Confirm whether the mode is `24-bit state`, `8-bit timing`, or `16-bit + 8-bit`.
2. Check whether the symptom is really a false asynchronous trigger due to transient states.
3. Verify selected trigger duration, delay mode, and qualifier assumptions.
4. If dual-mode is used, confirm whether the user intended `ARMS` or `TRIGGERS`.

Common interpretation notes:

- Asynchronous triggering can false-trigger on transient states; the manual explicitly says trigger duration must sometimes be widened.
- Glitch trigger is ANDed with the asynchronous pattern trigger, so missing glitch captures can be setup-related rather than hardware failure.
- `TRIGGER NOT IN MEMORY` can be a normal result of delay settings, not a hardware fault.

## 4. Suspect False Glitches, Bad Threshold, Or DUT Loading

Use when:

- glitches appear only with the probe attached
- signals look different between pods or between direct and cabled hookup
- logic family threshold is unclear
- measurement validity is in doubt

Primary pages:

- `1615A` threshold control and grounding notes: page `16`
- `1615A` input and glitch specifications: page `8`
- `10248C` specifications and threshold range: page `2`
- `10248C` input grounding rules and glitch-minimizing ground path: page `2`
- `10248C` threshold-compensation explanation: page `3`

Agent actions:

1. Check whether the circuit is TTL or requires a custom threshold.
2. For non-TTL logic, measure and set the correct variable threshold before blaming the analyzer.
3. If using the supplied long leads and hooks, use the inner ground path required by the probe note.
4. Ground unused probe leads; the `1615A` manual warns they can pick up glitches if left floating.
5. If direct connection is possible with no long cabling, prefer it when investigating suspected false glitches.

Important constraints to preserve:

- `1615A` front-end spec: `50 kOhm` shunted by less than `14 pF` at the probe tip, variable threshold to `+/-10 Vdc`, minimum detectable glitch `5 ns` with overdrive criteria.
- `10248C` probe note: input RC about `100 kOhm` shunted by about `5 pF`, dynamic range `+/-15 Vdc`, maximum input `+/-40 Vdc`.

## 5. Display Is Blank, Corrupt, Or Incoherent

Use when:

- no visible trace appears
- CRT content is unstable or unreadable
- only the display path seems broken while the instrument otherwise runs

Primary pages:

- troubleshooting incoherent display / no display: `1615A` service-section contents on page `4`
- display adjustment and alignment entry points: `1615A` pages `50` to `51`
- display-related block diagrams and schematics: `1615A` service pages around `188` to `213`

Agent actions:

1. Separate display-generation faults from acquisition faults using self-tests and DSA display mode.
2. Use `D-key at power-up` display DSA measurements mode before adjusting anything.
3. If the display path is proven faulty, use display adjustment locations and the display section schematics.
4. Avoid changing display adjustments until the logic path is otherwise known-good.

## 6. Acquisition Hardware Fails Self-Test

Use when:

- `B-key at power-up` data-acquisition self-test fails
- a specific octal status code is reported
- operator tests pass partly but acquisition logic still fails

Primary pages:

- data-acquisition self-test procedure: `1615A` page `33`
- section pointer for failure-code interpretation and tested circuitry: `1615A` page `33`
- service-section self-test and mnemonic tables: `1615A` pages near `8-2` and `8-11` in the original section, plus mnemonic tables around Markdown lines later in the file

Agent actions:

1. Capture the exact octal status code.
2. Re-display the test state via `FORMAT SPECIFICATION` and `TRACE SPECIFICATION`.
3. Use the service section to map the failed phase to the acquisition assemblies.
4. Move from status-code interpretation to the corresponding block diagram and then the schematic page image.

Likely board families to consider:

- `A1` data acquisition
- `A2` trigger and clock mux
- `A3` memory
- `A4` timing data acquisition
- `A5` microprocessor and ROM
- `A6` display programmer
- `A8` mother board
- `A9` probe threshold / input board

Board identifiers are listed in the replaceable-parts section and exploded views on pages `53` to `56`.

## 7. Verify Before And After Repair

Use when:

- the instrument has been repaired
- an internal adjustment was touched
- a fault seems fixed but needs proof

Primary pages:

- operator tests and self-tests: `1615A` pages `32` to `33`
- performance-test overview and operation verification: `1615A` pages `34` to `35`
- clock, qualifier, and data input test: `1615A` page `35`
- asynchronous operation test: `1615A` performance-test section, later pages in Section IV
- adjustments overview and locator drawings: `1615A` pages `50` to `51`
- probe performance test dependency: `10248C` page `3`

Agent actions:

1. Re-run startup and operator self-tests.
2. Run `Section IV` verification that matches the repaired function.
3. If a probe was involved, verify the probe through the logic-analyzer performance tests, not by ad hoc DUT observation alone.
4. Record the threshold setting, trigger mode, pod used, and exact test page referenced.

## Adjustment Guardrails

- Do not adjust internal controls until thresholding, probe grounding, and self-tests have been checked first.
- `Section V` is for known-good test setups, not first-pass troubleshooting.
- Use the locator drawings on `1615A` pages `50` to `51` to identify the exact control before touching it.

## Minimal Citation Pattern For Agents

When answering a fault question, cite like this:

- `1615A manual, Page 32`: startup messages and self-test entry behavior
- `1615A manual, Page 33`: data-acquisition self-test and DSA loop modes
- `1615A manual, Page 8`: trigger, glitch, threshold, and input limits
- `10248C note, Page 2`: ground selection and false-glitch prevention
- `10248C note, Page 3`: threshold-compensation behavior

## Suggested Answer Strategy For Future Agents

1. Restate the symptom as either `instrument fault`, `measurement-condition fault`, or `uncertain`.
2. Name the first proving step, not the final diagnosis.
3. Prefer reversible checks first:
   - self-test
   - threshold change
   - probe ground correction
   - unused-lead grounding
   - alternate pod / alternate probe
4. Only then recommend performance tests, adjustments, or schematic-level repair.
