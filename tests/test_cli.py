from contextlib import redirect_stdout
import io
import json
import runpy
import unittest
from unittest.mock import Mock, patch

import requests

import get_fp2 as lookup


class LookupTests(unittest.TestCase):
    def test_flash_annotations_keep_conditions_and_timeout(self):
        payload = {"Record": {"Section": [{
            "TOCHeading": "Chemical and Physical Properties",
            "Section": [{"TOCHeading": "Experimental Properties",
                         "Section": [{"TOCHeading": "Flash Point", "Information": [
                             {"Value": {"StringWithMarkup": [{"String": "source text / closed cup"}]}},
                             {"Value": {"StringWithMarkup": []}},
                         ]}]}],
        }]}}
        with patch.object(lookup, "pubchem_get", side_effect=[
            Mock(json=lambda: {"IdentifierList": {"CID": [702]}}),
            Mock(json=lambda: payload),
        ]) as get:
            self.assertEqual(lookup.process_cas_numbers(["64-17-5"]),
                             {"64-17-5": ["source text / closed cup"]})
        self.assertTrue(all(call.kwargs["timeout"] == 30 for call in get.call_args_list))

    def test_cli_stdout_is_valid_json_even_on_timeout(self):
        output = io.StringIO()
        with patch("sys.stdin", io.StringIO("64-17-5\n")), redirect_stdout(output), \
             patch("pubchem_http.pubchem_get", side_effect=requests.Timeout), self.assertLogs(level="WARNING"):
            runpy.run_module("get_fp2", run_name="__main__")
        self.assertEqual(json.loads(output.getvalue()), {"64-17-5": []})
