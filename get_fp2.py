# get_fp2.py
#
# Python script to fetch flash point data from PubChem for CAS numbers provided via stdin.
# Uses PubChem PUG REST API to get CID from CAS, then extract flash points from compound data.
#
# Requirements:
# - Python 3.x
# - requests library (install via: pip install requests)
# - json library (built-in)
#
# Usage:
# echo "50-00-0\n64-17-5" | python get_fp2.py
# (Reads CAS numbers from stdin, one per line; outputs JSON to stdout)
#
# Output:
# JSON object: {"CAS1": ["value1", "value2"], "CAS2": []}
#
# Notes:
# - Batch processing via stdin for efficiency.
# - Extracts from 'Flash Point' subsection; returns all available strings (may include units/conditions).
# - Handles API errors gracefully (returns empty list for failures).
# - Requests are paced and have bounded retries for transient PubChem responses.
#
# Author: glsalierno
# Date: September 2025

import sys
import json
import logging
from urllib.parse import quote
from pubchem_http import pubchem_get
import requests

LOG = logging.getLogger(__name__)
TIMEOUT = 30

def get_compound_id_from_cas(cas_number):
    url = f"https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/{quote(cas_number, safe='')}/cids/JSON"
    data = pubchem_get(url, timeout=TIMEOUT, context=f"CAS {cas_number}: CID lookup").json()
    cids = data.get("IdentifierList", {}).get("CID", [])
    if cids:
        return str(cids[0])
    LOG.warning("CAS %s: PubChem returned no CID", cas_number)
    return None

def get_flash_points(compound_id):
    url = f"https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/{compound_id}/JSON"
    data = pubchem_get(url, timeout=TIMEOUT, context=f"CID {compound_id}: flash point").json()
    flash_points = []
    
    if 'Record' in data and 'Section' in data['Record']:
        for section in data['Record']['Section']:
            if section.get('TOCHeading') == 'Chemical and Physical Properties':
                if 'Section' in section:
                    for subsection in section['Section']:
                        if subsection.get('TOCHeading') == 'Experimental Properties':
                            if 'Section' in subsection:
                                for property_section in subsection['Section']:
                                    if property_section.get('TOCHeading') == 'Flash Point':
                                        if 'Information' in property_section:
                                            for info in property_section['Information']:
                                                value = (info.get('Value', {}).get('StringWithMarkup') or [{}])[0].get('String')
                                                if value:
                                                    flash_points.append(value)
    return flash_points

def process_cas_numbers(cas_numbers):
    results = {}
    for cas in cas_numbers:
        try:
            compound_id = get_compound_id_from_cas(cas)
            results[cas] = get_flash_points(compound_id) if compound_id else []
        except (requests.RequestException, ValueError, TypeError, AttributeError, KeyError, IndexError) as e:
            LOG.warning("CAS %s: could not retrieve flash point: %s", cas, e)
            results[cas] = []
    return results

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    # Read CAS numbers from stdin (one per line)
    cas_numbers = [line.strip() for line in sys.stdin if line.strip()]
    results = process_cas_numbers(cas_numbers)
    # Print results as JSON to stdout
    print(json.dumps(results))
