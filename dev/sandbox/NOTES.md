# Audiveris sandbox build & run notes

## 1. Rebuild in a new session

```bash
git checkout claude/audiveris-sandbox-build
dev/sandbox/setup.sh                 # ~3-5 min the first time
dev/sandbox/run.sh my.pdf out 2 5-15 # ~5 min for 12 pages
```

## 2. Environment blockers & workarounds

| Blocker | Symptom | Workaround |
|---|---|---|
| JDK 21 preinstalled | `invalid source release: 25` | `apt install openjdk-25-jdk-headless` |
| repository.jboss.org blocked | `Could not resolve javax.media:jai-core:1.1.3` (403) | Empty stub jar + pom in `~/.m2` (unused by code) |
| Maven Central rate limit | HTTP 429 | Retry loop in `setup.sh` |
| Ubuntu tessdata is LSTM-only | `Could not initialize TessBaseAPI ... legacy mode` | Download full `eng.traineddata` from tesseract-ocr/tessdata |

## 3. Audiveris bugs fixed (commit "Fix batch -print and multi-movement export with -sheets")

1. **Batch `-print` crashed** (`ExceptionInInitializerError: Application is not launched`).
   `SheetPainter` and `ViewParameters` read GUI resource maps in static initializers.
   Fix: resolve them lazily, only where the GUI needs them.
2. **Empty (0 byte) print PDF** when any sheet painting failed. The exception skipped
   `g2.dispose()`, and iText then threw `Unbalanced save/restore state operators` on close.
   Fix: per-sheet try/catch/finally in `BookPdfOutput.write`.
3. **MusicXML movements overwrote each other** as `<book>.mvtnull.mxl` when using `-sheets`.
   Scores built from selected sheets aren't registered in the book, so `Score.getId()` was null.
   Fix: `Book.getMovementId` falls back to the score rank in the exported list.

## 4. Open issues (not fixed)

- Sheets that throw during OMR abort the whole batch (`Error in reaching step PAGE`).
  Workaround: exclude them with `-sheets`.
- Observed NPEs on the test score:
  - `stems is null` (sheet 3)
  - `Measure.getClefBefore ... measure is null` (sheet 4)
  - `Staff.getPart() ... this.staff is null` in `SymbolsBuilder` (sheet 8, non-fatal)
  - `PartBarline with no proper StaffBarline` (non-fatal, measures dropped from export)

## 5. First test run: "Incident at Wounded Knee", Bassoon II (15-page scan)

- Command: `run.sh Bassoon_II_-_Ballard.pdf out 2 5-15`
- Sheet 1: cover page (no staves). Sheets 3-4: crash (see above).
- Output: 12-page engraved PDF, 7 MusicXML movements, 422 measures total.
- Quality is rough, so expect manual correction in the Audiveris GUI:
  - header clefs mostly missed, so pitches and accidentals are unreliable
  - time signatures missed, so measure durations aren't checked
  - multi-measure rests and some barlines misread
  - the "RENTAL ONLY" stamp gets OCR'd as garbage text
- Tips to improve: rescan at 300-400 dpi, clean stamps/marks, then fix clefs and time
  signatures in the GUI and re-run from the `.omr` project.
