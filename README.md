# krp-working-data
Repo to store TEI/XML data the KRP-Project


## workflow
The inital plan
### tei-body
* textual work and formal "markup" is done in .docx
* once done, the .docx is converted to generic-tei via [TEIGarage Conversion](https://teigarage.tei-c.org/) and the resulting TEI/XML is copied into `preprocessing/teigarage-out/editions` or `preprocessing/teigarage-out/stenogramms` respecting the project's file naming convention
* files in those folder are upconverted applying XSLTs (using Oxygen's transformation scenarios); the resulting documents are stored in `preprocessing/upconverted/editions` or `preprocessing/upconverted/stenogramms`

### tei-header
TEI-Headers are genereated via `uv run src/generate_tei_templates.py` by fetching metadata from the project's baserow project and genereting template files

### full document
The final working document is created by copying a template file into `data/editions/` and replacing its `tei:body` with the matching one from `preprocessing/upconverted/editions`

### tracking progress
set some status in the baserow metadata table

### next things
Editors continue working on this document