# Import
# ------

import os
import shutil

import requests
from lxml import etree
from tqdm import tqdm

# Constants
# ---------

JSON_URL = "https://raw.githubusercontent.com/krp-project/krp-baserow-dump/main/json_dumps/protocols.json"
TEI_NS = "http://www.tei-c.org/ns/1.0"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
XML_NS = "http://www.w3.org/XML/1998/namespace"
XML_BASE = "https://id.acdh.oeaw.ac.at/krp"  # to be changed
OUTPUT_DIR = "tmp"  # to be changed

# Build TEI-XML template
# ----------------------


def build_template(protocol):
    """Build TEI-XML template from single JSON object."""

    protocol_id = f"{protocol['krp_id']}.xml"

    nsmap = {None: TEI_NS, "xsi": XSI_NS}

    # Root
    root = etree.Element("TEI", nsmap=nsmap)
    root.set(f"{{{XML_NS}}}id", protocol_id)
    root.set(f"{{{XML_NS}}}base", XML_BASE)

    # 1st level
    tei_header = etree.SubElement(root, "teiHeader")
    tei_facsimile = etree.SubElement(root, "facsimile")
    tei_text = etree.SubElement(root, "text")

    # 2nd level
    tei_filedesc = etree.SubElement(tei_header, "fileDesc")
    tei_profiledesc = etree.SubElement(tei_header, "profileDesc")
    tei_encodingdesc = etree.SubElement(tei_header, "encodingDesc")
    tei_surface = etree.SubElement(tei_facsimile, "surface")
    tei_body = etree.SubElement(tei_text, "body")

    # 3rd level
    tei_titlestmt = etree.SubElement(tei_filedesc, "titleStmt")
    tei_pubstmt = etree.SubElement(tei_filedesc, "publicationStmt")
    tei_seriesstmt = etree.SubElement(tei_filedesc, "seriesStmt")
    tei_notesstmt = etree.SubElement(tei_filedesc, "notesStmt")
    tei_sourcedesc = etree.SubElement(tei_filedesc, "sourceDesc")
    tei_abstract = etree.SubElement(tei_profiledesc, "abstract")
    tei_styledefdecl = etree.SubElement(tei_encodingdesc, "styleDefDecl", scheme="css")
    tei_tagsdecl = etree.SubElement(tei_encodingdesc, "tagsDecl")
    tei_editorialdecl = etree.SubElement(tei_encodingdesc, "editorialDecl")
    tei_div1 = etree.SubElement(tei_body, "div")  # to be changed

    # 4th level
    tei_title_s = etree.SubElement(tei_titlestmt, "title", level="s", type="main")
    tei_title_s.text = (
        "Protokolle des Ministerrates der Ersten Republik der Republik Österreich"
    )
    tei_title_a = etree.SubElement(
        tei_titlestmt, "title", level="a", type="main", n=protocol["krp_id"][-3:]
    )
    tei_title_a.text = f"{protocol['title']} {protocol['written_date']}"
    tei_title_m_main = etree.SubElement(
        tei_titlestmt, "title", level="m", type="main", n="01"
    )
    tei_title_m_main.text = "Abteilung I: (Deutsch-)Österreichischer Kabinettsrat 31. Oktober 1918 bis 7. Juli 1920"
    tei_title_m_sub = etree.SubElement(
        tei_titlestmt, "title", level="m", type="sub", n=""
    )
    tei_title_m_sub.text = protocol["period"]["value"]

    tei_meeting = etree.SubElement(tei_titlestmt, "meeting")
    tei_editor1 = etree.SubElement(tei_titlestmt, "editor")
    tei_editor2 = etree.SubElement(tei_titlestmt, "editor")
    tei_editor3 = etree.SubElement(tei_titlestmt, "editor")
    tei_editor4 = etree.SubElement(tei_titlestmt, "editor")
    tei_editor5 = etree.SubElement(tei_titlestmt, "editor")
    tei_editor6 = etree.SubElement(tei_titlestmt, "editor")
    tei_funder = etree.SubElement(tei_titlestmt, "funder")
    tei_respstmt1 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_respstmt2 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_respstmt3 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_respstmt4 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_respstmt5 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_respstmt6 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_respstmt7 = etree.SubElement(tei_titlestmt, "respStmt")
    tei_publisher = etree.SubElement(
        tei_pubstmt, "publisher", key="https://d-nb.info/gnd/1001454-8"
    )
    tei_pubdate = etree.SubElement(tei_pubstmt, "date", when="2028")
    tei_availability = etree.SubElement(tei_pubstmt, "availability", status="free")
    tei_pubidno1 = etree.SubElement(tei_pubstmt, "idno", type="ISBN_Print")
    tei_pubidno2 = etree.SubElement(tei_pubstmt, "idno", type="ISBN_Part_epub")
    tei_pubidno3 = etree.SubElement(tei_pubstmt, "idno", type="ISBN_Digital")
    tei_pubidno4 = etree.SubElement(tei_pubstmt, "idno", type="DOI")
    tei_pubidno5 = etree.SubElement(tei_pubstmt, "idno", type="DOI_zenodo")
    tei_pubidno6 = etree.SubElement(tei_pubstmt, "idno", type="ebook_ID")
    tei_seriestitle_s = etree.SubElement(
        tei_seriesstmt, "title", level="s", type="main"
    )
    tei_seriestitle_m = etree.SubElement(
        tei_seriesstmt, "title", level="m", type="main"
    )
    tei_seriesrespstmt = etree.SubElement(tei_seriesstmt, "respStmt")
    tei_note = etree.SubElement(tei_notesstmt, "note")
    tei_relateditem = etree.SubElement(tei_notesstmt, "relatedItem")
    tei_bibl = etree.SubElement(tei_sourcedesc, "bibl")
    tei_msdesc = etree.SubElement(tei_sourcedesc, "msDesc")
    tei_abstractp = etree.SubElement(tei_abstract, "p")
    tei_rendition1 = etree.SubElement(
        tei_tagsdecl, "rendition", attrib={f"{{{XML_NS}}}id": "b", "scheme": "css"}
    )
    tei_rendition2 = etree.SubElement(
        tei_tagsdecl, "rendition", attrib={f"{{{XML_NS}}}id": "su", "scheme": "css"}
    )
    tei_rendition3 = etree.SubElement(
        tei_tagsdecl, "rendition", attrib={f"{{{XML_NS}}}id": "s", "scheme": "css"}
    )
    tei_rendition4 = etree.SubElement(
        tei_tagsdecl, "rendition", attrib={f"{{{XML_NS}}}id": "u", "scheme": "css"}
    )
    tei_rendition5 = etree.SubElement(
        tei_tagsdecl, "rendition", attrib={f"{{{XML_NS}}}id": "ow", "scheme": "css"}
    )
    tei_rendition6 = etree.SubElement(
        tei_tagsdecl, "rendition", attrib={f"{{{XML_NS}}}id": "r", "scheme": "css"}
    )
    tei_rendition7 = etree.SubElement(
        tei_tagsdecl,
        "rendition",
        attrib={f"{{{XML_NS}}}id": "letterspaced", "scheme": "css"},
    )
    tei_hyphenation = etree.SubElement(tei_editorialdecl, "hyphenation")
    tei_correction = etree.SubElement(tei_editorialdecl, "correction")
    tei_normalization = etree.SubElement(tei_editorialdecl, "normalization")
    tei_punctuation = etree.SubElement(tei_editorialdecl, "punctuation")
    tei_stdvals = etree.SubElement(tei_editorialdecl, "stdVals")
    tei_editorialdeclp = etree.SubElement(tei_editorialdecl, "p")

    # 5th level
    tei_meetingplace = etree.SubElement(
        tei_meeting, "placeName", key="https://d-nb.info/gnd/4066009-6"
    )
    tei_meetingorg = etree.SubElement(
        tei_meeting, "orgName", key="https://d-nb.info/gnd/5162749-8"
    )
    tei_meetingdate = etree.SubElement(
        tei_meeting, "date", attrib={"when-iso": protocol["date"]}
    )
    tei_editor1name = etree.SubElement(
        tei_editor1,
        "persName",
        key="https://d-nb.info/gnd/122481836",
        role="hasCreator",
    )
    tei_editor1affiliation = etree.SubElement(
        tei_editor1, "affiliation", key="https://d-nb.info/gnd/37748-X"
    )
    tei_editor1idno = etree.SubElement(tei_editor1, "idno", type="ORCID")
    tei_editor2name = etree.SubElement(
        tei_editor2,
        "persName",
        key="https://d-nb.info/gnd/120789825",
        role="hasCreator",
    )
    tei_editor2affiliation = etree.SubElement(
        tei_editor2, "affiliation", key="https://d-nb.info/gnd/1026192285"
    )
    tei_editor2idno = etree.SubElement(tei_editor2, "idno", type="ORCID")
    tei_editor3name = etree.SubElement(
        tei_editor3,
        "persName",
        key="https://d-nb.info/gnd/131679384",
        role="hasCreator",
    )
    tei_editor3affiliation = etree.SubElement(
        tei_editor3, "affiliation", key="https://d-nb.info/gnd/1026192285"
    )
    tei_editor3idno = etree.SubElement(tei_editor3, "idno", type="ORCID")
    tei_editor4name = etree.SubElement(tei_editor4, "persName", role="hasCreator")
    tei_editor4affiliation = etree.SubElement(
        tei_editor4, "affiliation", key="https://d-nb.info/gnd/1026192285"
    )
    tei_editor4idno = etree.SubElement(tei_editor4, "idno", type="ORCID")
    tei_editor5name = etree.SubElement(tei_editor5, "persName", role="hasCreator")
    tei_editor5affiliation = etree.SubElement(
        tei_editor5, "affiliation", key="https://d-nb.info/gnd/1026192285"
    )
    tei_editor5idno = etree.SubElement(tei_editor5, "idno", type="ORCID")
    tei_editor6name = etree.SubElement(tei_editor6, "persName", role="hasContributor")
    tei_editor6affiliation = etree.SubElement(
        tei_editor6, "affiliation", key="https://d-nb.info/gnd/1026192285"
    )
    tei_editor6idno = etree.SubElement(tei_editor6, "idno", type="ORCID")
    tei_funderorg = etree.SubElement(
        tei_funder, "orgName", key="https://d-nb.info/gnd/2054142-9", role="hasFunder"
    )
    tei_funderidno = etree.SubElement(tei_funder, "idno", type="project")
    tei_resp1 = etree.SubElement(tei_respstmt1, "resp")
    tei_resp1org = etree.SubElement(
        tei_respstmt1, "orgName", key="https://d-nb.info/gnd/1026192285"
    )
    tei_resp2 = etree.SubElement(tei_respstmt2, "resp")
    tei_resp2name = etree.SubElement(
        tei_respstmt2,
        "persName",
        key="https://d-nb.info/gnd/120789825",
        role="hasPrincipalInvestigator",
    )
    tei_resp3 = etree.SubElement(tei_respstmt3, "resp")
    tei_resp3org = etree.SubElement(
        tei_respstmt3,
        "orgName",
        key="https://d-nb.info/gnd/1123037736",
        role="hasEnabler",
    )
    tei_resp4 = etree.SubElement(tei_respstmt4, "resp")
    tei_resp4org = etree.SubElement(
        tei_respstmt4, "orgName", key="https://d-nb.info/gnd/2068748-5"
    )
    tei_resp5 = etree.SubElement(tei_respstmt5, "resp")
    tei_resp5name = etree.SubElement(tei_respstmt5, "persName", role="hasContributor")
    tei_resp6 = etree.SubElement(tei_respstmt6, "resp")
    tei_resp6name = etree.SubElement(
        tei_respstmt6,
        "persName",
        key="https://d-nb.info/gnd/1043833846",
        role="hasContributor",
    )
    tei_resp7 = etree.SubElement(tei_respstmt7, "resp")
    tei_resp7name = etree.SubElement(
        tei_respstmt7,
        "persName",
        key="https://d-nb.info/gnd/13281899X",
        role="hasContributor",
    )
    tei_licence = etree.SubElement(
        tei_availability,
        "licence",
        target="https://creativecommons.org/licenses/by/4.0/deed.de",
    )
    tei_seriesresp = etree.SubElement(tei_seriesrespstmt, "resp")
    tei_seriesresporg1 = etree.SubElement(
        tei_seriesrespstmt, "orgName", key="https://d-nb.info/gnd/2024703-5"
    )
    tei_seriesresporg2 = etree.SubElement(
        tei_seriesrespstmt, "orgName", key="https://d-nb.info/gnd/37748-X"
    )
    tei_biblstruct = etree.SubElement(tei_relateditem, "biblStruct")
    tei_msidentifier = etree.SubElement(tei_msdesc, "msIdentifier")
    tei_hyphenationp = etree.SubElement(tei_hyphenation, "p")
    tei_correctionp = etree.SubElement(tei_correction, "p")
    tei_normalizationp = etree.SubElement(tei_normalization, "p")
    tei_punctuationp = etree.SubElement(tei_punctuation, "p")
    tei_stdvalsp = etree.SubElement(tei_stdvals, "p")

    # 6th level
    tei_editor1forename = etree.SubElement(tei_editor1name, "forename")
    tei_editor1surname = etree.SubElement(tei_editor1name, "surname")
    tei_editor2forename = etree.SubElement(tei_editor2name, "forename")
    tei_editor2surname = etree.SubElement(tei_editor2name, "surname")
    tei_editor3forename = etree.SubElement(tei_editor3name, "forename")
    tei_editor3surname = etree.SubElement(tei_editor3name, "surname")
    tei_editor4forename = etree.SubElement(tei_editor4name, "forename")
    tei_editor4surname = etree.SubElement(tei_editor4name, "surname")
    tei_editor5forename = etree.SubElement(tei_editor5name, "forename")
    tei_editor5surname = etree.SubElement(tei_editor5name, "surname")
    tei_editor6forename = etree.SubElement(tei_editor6name, "forename")
    tei_editor6surname = etree.SubElement(tei_editor6name, "surname")
    tei_resp2forename = etree.SubElement(tei_resp2name, "forename")
    tei_resp2surname = etree.SubElement(tei_resp2name, "surname")
    tei_resp2affiliation = etree.SubElement(
        tei_resp2name, "affiliation", key="https://d-nb.info/gnd/1026192285"
    )
    tei_resp2idno = etree.SubElement(tei_resp2name, "idno", type="ORCID")
    tei_resp5forename = etree.SubElement(tei_resp5name, "forename")
    tei_resp5surname = etree.SubElement(tei_resp5name, "surname")
    tei_resp5affiliation = etree.SubElement(
        tei_resp5name, "affiliation", key="https://d-nb.info/gnd/1123037736"
    )
    tei_resp5idno = etree.SubElement(tei_resp5name, "idno", type="ORCID")
    tei_resp6forename = etree.SubElement(tei_resp6name, "forename")
    tei_resp6surname = etree.SubElement(tei_resp6name, "surname")
    tei_resp6affiliation = etree.SubElement(
        tei_resp6name, "affiliation", key="https://d-nb.info/gnd/1123037736"
    )
    tei_resp6idno = etree.SubElement(tei_resp6name, "idno", type="ORCID")
    tei_resp7forename = etree.SubElement(tei_resp7name, "forename")
    tei_resp7surname = etree.SubElement(tei_resp7name, "surname")
    tei_resp7affiliation = etree.SubElement(
        tei_resp7name, "affiliation", key="https://d-nb.info/gnd/1202798799"
    )
    tei_resp7idno = etree.SubElement(tei_resp7name, "idno", type="ORCID")
    tei_monogr = etree.SubElement(tei_biblstruct, "monogr")
    tei_biblstructnote = etree.SubElement(tei_biblstruct, "note")
    tei_citedrange = etree.SubElement(tei_biblstruct, "citedRange")
    tei_institution = etree.SubElement(
        tei_msidentifier,
        "institution",
        key="https://d-nb.info/gnd/37748-X",
        role="hasOwner",
    )
    tei_repository = etree.SubElement(
        tei_msidentifier, "repository", key="https://d-nb.info/gnd/1601181-8"
    )
    tei_collection = etree.SubElement(tei_msidentifier, "collection")
    tei_idno = etree.SubElement(tei_msidentifier, "idno")

    # 7th level
    tei_imprint = etree.SubElement(tei_monogr, "imprint")
    tei_extent = etree.SubElement(tei_monogr, "extent")
    tei_noteidno = etree.SubElement(tei_biblstructnote, "idno")
    tei_ptr = etree.SubElement(tei_biblstructnote, "ptr")

    # 8th level
    tei_imprintpubplace = etree.SubElement(
        tei_imprint, "pubPlace", key="https://d-nb.info/gnd/4066009-6"
    )
    tei_imprintpublisher = etree.SubElement(
        tei_imprint, "publisher", key="https://d-nb.info/gnd/2068748-5"
    )
    tei_imprintdate = etree.SubElement(tei_imprint, "date", when="2029")

    return root, protocol_id


# Main
# ----

if __name__ == "__main__":
    data = requests.get(JSON_URL, timeout=30).json()

    shutil.rmtree(OUTPUT_DIR, ignore_errors=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for key, protocol in tqdm(data.items(), total=len(data)):
        # Unpack returned tuple
        root, protocol_id = build_template(protocol)

        file_path = os.path.join(OUTPUT_DIR, protocol_id)

        tree = etree.ElementTree(root)

        # Create processing instructions
        pi1 = etree.ProcessingInstruction(
            "xml-model",
            "href='../schema/krp.rng' type='application/xml' schematypens='http://relaxng.org/ns/structure/1.0'",
        )
        pi2 = etree.ProcessingInstruction(
            "xml-model",
            "href='http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng' type='application/xml' schematypens='http://relaxng.org/ns/structure/1.0'",
        )

        # Insert processing instructions as previous siblings of root
        root.addprevious(pi1)
        root.addprevious(pi2)

        # Set custom indentation for readability
        etree.indent(root, space="    ")

        tree.write(file_path, encoding="utf-8", xml_declaration=True, pretty_print=True)
