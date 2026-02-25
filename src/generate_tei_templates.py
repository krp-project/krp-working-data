# Import
# ------

import logging

import requests
from lxml import etree

# Configure logging
# -----------------

logging.basicConfig(level=logging.DEBUG, format="%(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Constants
# ---------

JSON_URL = 'https://raw.githubusercontent.com/krp-project/krp-baserow-dump/main/json_dumps/protocols.json'
TEI_NS = 'http://www.tei-c.org/ns/1.0'
XSI_NS = 'http://www.w3.org/2001/XMLSchema-instance'
XML_NS = 'http://www.w3.org/XML/1998/namespace'
XML_BASE = 'https://example.org'  # to be changed
OUTPUT_DIR = '/home/tfruehwirth/Downloads/test-xmls'  # to be changed

# Fetch JSON data
# ---------------


def fetch_json():
    """Fetch metadata from remote JSON source."""


    with requests.get(JSON_URL, timeout=30) as response:

        response.raise_for_status()
        data = response.json()

        logger.info(f"JSON successfully downloaded ({len(data)} objects)")

        return data


# Build TEI-XML template
# ----------------------


def build_template(protocol):
    """Build TEI-XML template from single JSON object."""

    protocol_id = f"krp-transcript_{protocol['krp_id']}"  # to be discussed

    nsmap = {None: TEI_NS, 'xsi': XSI_NS}

    root = etree.Element('TEI', nsmap=nsmap)
    root.set(f"{{{XML_NS}}}id", protocol_id)
    root.set(f"{{{XML_NS}}}base", XML_BASE)

    tei_header = etree.SubElement(root, 'teiHeader')
    tei_facsimile = etree.SubElement(root, 'facsimile')
    tei_text = etree.SubElement(root, 'text')

    tei_filedesc = etree.SubElement(tei_header, 'fileDesc')
    tei_profiledesc = etree.SubElement(tei_header, 'profileDesc')
    tei_encodingdesc = etree.SubElement(tei_header, 'encodingDesc')
    tei_body = etree.SubElement(tei_text, 'body')

    tei_titlestmt = etree.SubElement(tei_filedesc, 'titleStmt')
    tei_pubstmt = etree.SubElement(tei_filedesc, 'publicationStmt')
    tei_seriesstmt = etree.SubElement(tei_filedesc, 'seriesStmt')
    tei_notesstmt = etree.SubElement(tei_filedesc, 'notesStmt')
    tei_sourcedesc = etree.SubElement(tei_filedesc, 'sourceDesc')
    tei_abstract = etree.SubElement(tei_profiledesc, 'abstract')
    tei_styledefdecl = etree.SubElement(tei_encodingdesc, 'styleDefDecl')
    tei_tagsdecl = etree.SubElement(tei_encodingdesc,'tagsDecl')
    tei_editorialdecl = etree.SubElement(tei_encodingdesc, 'editorialDecl')

    tei_title_s = etree.SubElement(tei_titlestmt, 'title', level='s', type='main')
    tei_title_a = etree.SubElement(tei_titlestmt, 'title', level='a', type='main')
    tei_title_m_main = etree.SubElement(tei_titlestmt, 'title', level='m', type='main')
    tei_title_m_sub = etree.SubElement(tei_titlestmt, 'title', level='m', type='sub')

    tei_title_s.text = 'Protokolle des Ministerrates der Ersten Republik der Republik Österreich'
    tei_title_a.text = f"{protocol['title']} {protocol['written_date']}"
    tei_title_m_main.text = 'Abteilung I: (Deutsch-)Österreichischer Kabinettsrat 31. Oktober 1918 bis 7. Juli 1920'
    tei_title_m_sub.text = protocol['period']['value']

    return root, protocol_id


# Main
# ----

if __name__ == "__main__":
    data = fetch_json()

    for key, protocol in data.items():

        # Unpack returned tuple
        root, protocol_id = build_template(protocol)

        file_path = f"{OUTPUT_DIR}/{protocol_id}.xml"

        tree = etree.ElementTree(root)

        # Create processing instructions
        pi1 = etree.ProcessingInstruction('xml-model',
            "href='path/to/krp.rng' type='application/xml' schematypens='http://relaxng.org/ns/structure/1.0'")  # to be changed
        pi2 = etree.ProcessingInstruction('xml-model',
            "href='http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng' type='application/xml' schematypens='http://relaxng.org/ns/structure/1.0'")

        # Insert processing instructions as previous siblings of root
        root.addprevious(pi1)
        root.addprevious(pi2)

        tree.write(file_path, encoding='utf-8', xml_declaration=True, pretty_print=True)
