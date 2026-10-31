# CLAUDE.md

Audiveris: optical music recognition (OMR). Java/Gradle app in `app/`.

## Quick start (sandbox / cloud session)

```bash
dev/sandbox/setup.sh                                # JDK 25, Tesseract, jai-core stub, build
dev/sandbox/run.sh input.pdf out 2 5-15              # batch OMR on sheets 2 and 5-15
```

Outputs in `out/`: `<book>-print.pdf` (engraved), `<book>.mvtN.mxl` (MusicXML per movement),
`<book>.omr` (project, open in the Audiveris GUI to correct), `run.log`.

Details, known issues and the first test run: `dev/sandbox/NOTES.md`.

## Build gotchas

- Needs **JDK 25** (`invalid source release: 25` with older JDKs). Set `JAVA_HOME`.
- `javax.media:jai-core:1.1.3` only lives on repository.jboss.org; when blocked, use the
  empty stub in `~/.m2` (see `setup.sh`). No source imports `javax.media.jai`.
- Maven Central may return HTTP 429; just retry.
- Tesseract needs a `eng.traineddata` with the **legacy** engine (tessdata repo, not
  Ubuntu's `tesseract-ocr-eng`). Point `TESSDATA_PREFIX` at its directory.

## Batch CLI

`app/build/install/app/bin/Audiveris -batch [-sheets ids...] -transcribe -export -print -output DIR -- FILE`

- A sheet that fails OMR (no staff lines, internal exception) aborts export for the whole
  book. Exclude such sheets with `-sheets`.

## Code conventions

- Source files use **CRLF** line endings. Preserve them when editing (Python: `newline=''`).
- Match existing style: banner comments (`//-----//`) above methods, Javadoc on members.
- Don't access `Application.getInstance()` in static initializers of classes used in batch
  mode: it throws "Application is not launched" without the GUI. Resolve resources lazily.
