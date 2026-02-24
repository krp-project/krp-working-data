# Import

# Standard libraries
import logging

# External packages
import requests
from lxml import etree

# Configure logging

logging.basicConfig(level=logging.DEBUG, format="%(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Constants

JSON_URL = "https://raw.githubusercontent.com/krp-project/krp-baserow-dump/main/json_dumps/protocols.json"

# Fetch JSON data

def fetch_json():

    with requests.get(JSON_URL, timeout=30) as response:
        response.raise_for_status()
        data = response.json()
        logger.info("JSON successfully downloaded")
        return data
