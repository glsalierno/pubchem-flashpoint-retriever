% fetchFlashPoints.m
% 
% Function to fetch flash point data for one or more CAS numbers from PubChem.
% Uses a Python helper script to query the PubChem PUG REST API.
% 
% Inputs:
%   cas_numbers - String or cell array of strings with CAS numbers (e.g., {'50-00-0', '64-17-5'}).
% 
% Outputs:
%   results - Cell array where each row is {CAS, flash_points_cell_array}.
%             flash_points is a cell array of strings (e.g., {'100 °C', 'Closed cup: 95 °F'}).
% 
% Requirements:
% - MATLAB (base installation; uses tempname, fopen, system, jsondecode).
% - Python 3.x with 'requests' and 'json' libraries (built-in/standard).
% - The Python script 'get_fp2.py' in the system PATH or same directory.
% 
% Usage:
% results = fetchFlashPoints('50-00-0');  % Single CAS
% results = fetchFlashPoints({'50-00-0', '64-17-5'});  % Batch
% 
% Notes:
% - Batch processing is built-in via cell array input.
% - Handles errors from Python execution.
% - Flash points are extracted from 'Experimental Properties' section; may include multiple values with conditions.
% - Respect PubChem API rate limits (e.g., pause in loops for large batches).
% 
% Author: glsalierno
% Date: September 2025

function results = fetchFlashPoints(cas_numbers)
    % Ensure cas_numbers is a cell array of strings
    if ~iscell(cas_numbers)
        cas_numbers = {cas_numbers};
    end
    
    % Create a temporary file to store CAS numbers
    temp_file = tempname;
    fid = fopen(temp_file, 'w');
    fprintf(fid, '%s\n', cas_numbers{:});
    fclose(fid);
    
    % Call the Python script
    [status, output] = system(sprintf('get_fp2.py < %s', temp_file));
    
    % Delete the temporary file
    delete(temp_file);
    
    % Check if the Python script ran successfully
    if status ~= 0
        error('Error running Python script: %s', output);
    end
    
    % Parse the JSON output from Python
    results = jsondecode(output);
    
    % Convert the results to a more MATLAB-friendly format
    results = struct2cell(results);
    results = [cas_numbers', results];
end
