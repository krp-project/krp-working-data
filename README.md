# krp-working-data

Preprocessing repo for the KRP project. Holds the workflow for converting transcription DOCX files into project-compliant TEI-XML documents ready for editorial work in [krp-data](https://github.com/krp-project/krp-data).

## Folder structure

```
input/                          DOCX transcription files (gitignored)
preprocessing/
├── docx-to-tei.sh              Bash script for local TEIGarage conversion
├── teigarage-out/              generic TEI-XML output
└── xslts/
    └── upconvert.xsl           XSLT 3.0 stylesheet for upconversion
header-docs/                    TEI headers generated from JSON metadata
saxon/                          Saxon HE 12.5 + xmlresolver
data/templates/                 project-compliant TEI-XML output files
src/
└── generate_tei_templates.py   Python script for generating header-docs
build.xml                       Ant for running upconvert.xsl via Saxon
```

## Workflow

### 1. Generate TEI headers

A Python script fetches protocol metadata from a [Baserow JSON dump](https://github.com/krp-project/krp-baserow-dump/blob/main/json_dumps/protocols.json) and generates one header file per protocol into `header-docs/` (naming: `krp-???_header.xml`).

```
uv run src/generate_tei_templates.py
```

### 2. Convert DOCX to generic TEI-XML

Transcription DOCX files placed in `input/` are converted to generic TEI-XML via a local [TEIGarage](https://github.com/TEIC/TEIGarage) Docker container. Output goes to `preprocessing/teigarage-out/`.

```
bash preprocessing/docx-to-tei.sh
```

### 3. Merge and upconvert to project-compliant TEI-XML

An Ant build applies `upconvert.xsl` (XSLT 3.0, processed by Saxon HE 12.5) to each generic TEI-XML in `preprocessing/teigarage-out/`. The XSLT automatically merges the matching header-doc and transforms the body into a project-compliant structure. Output goes to `data/templates/`.

```
ant
```

> [!WARNING]
> The `upconvert.xsl` stylesheet is work in progress and does not yet generate actionable templates for editorial markup.

### 4. Transfer to krp-data

The files in `data/templates/` (which preserve the transcription DOCX filenames) are ready for being copied into [`data/editions/`](https://github.com/krp-project/krp-data/tree/main/data/editions) in the `krp-data` repo and renamed to `krp-???.xml` for editorial work.

## GitHub Actions

Steps 1 and 3 are automated via GitHub Actions:

- **write-headers** (`write-headers.yml`): Generates TEI header-docs from Baserow metadata. Runs on push to `src/` as well as manually.
- **upconvert-tei** (`upconvert-tei.yml`): Runs the Ant/Saxon TEI-XML upconversion. Triggered by pushes to `preprocessing/teigarage-out/` or `header-docs/`, or manually.

The first Action generates up-to-date header-docs. This then triggers the TEI-XML upconversion, which fires also when new TEIGarage output is pushed.

> [!IMPORTANT]
> When running the `upconvert-tei` Action manually, make sure to run `write-headers` before to make sure that the TEI headers are up to date for downstream processing.
