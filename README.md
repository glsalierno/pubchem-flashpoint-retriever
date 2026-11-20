[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python 3.x](https://img.shields.io/badge/python-3.x-blue.svg)](https://www.python.org/downloads/)
# PubChem Flash Point Retriever

This repository provides a MATLAB function and Python script to retrieve flash point information from PubChem for given CAS numbers. Focuses on experimental properties; supports batch processing.

## Files
- `fetchFlashPoints.m`: MATLAB function for CAS input and result parsing.
- `get_fp2.py`: Python script for PubChem API queries and JSON output.

## Requirements
- **Python 3.x**: Run `python -m pip install -r requirements.txt`.
- **MATLAB**: Base installation (uses system calls and jsondecode).

## Usage
1. Keep the Python and MATLAB files together and ensure `python` is on PATH.
2. In MATLAB: `results = fetchFlashPoints({'50-00-0', '64-17-5'});` (batch example).
3. Results: Cell array with {CAS, flash_points_cell}.

## Notes
- Each PubChem request uses a 30-second timeout. Python writes one JSON object to stdout and diagnostics to stderr.
- A result may include several source records with different test conditions. An empty list can mean no annotation or a failed request; check diagnostics. It does not imply nonflammability.
- For issues, open a GitHub issue.

Author: glsalierno  
Date: September 2025  
GitHub: [glsalierno](https://github.com/glsalierno)

## Offline tests

```text
python -m pip install -r requirements.txt
python -m unittest discover -s tests -v
```

The tests mock PubChem requests; CI does not call PubChem or exercise MATLAB.
Network calls are paced in each process and retry HTTP 429 or 503 at most twice.
The tool honors Retry-After. If PubChem requests a wait over 30 seconds, the
tool does not retry early or issue a new request during that cooldown. Keep
batch sizes modest and follow [PubChem's usage policy](https://pubchem.ncbi.nlm.nih.gov/docs/programmatic-access).
