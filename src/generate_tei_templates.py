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

JSON_URL = "https://raw.githubusercontent.com/krp-project/krp-baserow-dump/main/json_dumps/protocols.json"
TEI_NS = "http://www.tei-c.org/ns/1.0"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
XML_NS = "http://www.w3.org/XML/1998/namespace"
XML_BASE = "https://example.org"  # to be changed
OUTPUT_DIR = "/home/tfruehwirth/Downloads/test-xmls"  # to be changed

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

    nsmap = {None: TEI_NS, "xsi": XSI_NS}

    root = etree.Element("TEI", nsmap=nsmap)
    root.set(f"{{{XML_NS}}}id", protocol_id)
    root.set(f"{{{XML_NS}}}base", XML_BASE)

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
        tree.write(file_path, encoding="utf-8", xml_declaration=True, pretty_print=True)
