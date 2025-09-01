% fetchFlashPoints_v2.m
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
% results = fetchFlashPoints_v2('50-00-0');  % Single CAS
% results = fetchFlashPoints_v2({'50-00-0', '64-17-5'});  % Batch
% 
% Notes:
% - Batch processing is built-in via cell array input.
% - Handles errors from Python execution.
% - Flash points are extracted from 'Experimental Properties' section; may include multiple values with conditions.
% - Respect PubChem API rate limits (e.g., pause in loops for large batches).
% - v2 Fix: Handles mangled field names from jsondecode for CAS keys (e.g., '50-00-0' -> 'x50_00_0').
% 
% Author: glsalierno
% Date: September 2025

function results = fetchFlashPoints_v2(cas_numbers)
    % Ensure cas_numbers is a cell array of strings
    if ~iscell(cas_numbers)
        cas_numbers = {cas_numbers};
    end
    
    % Create a temporary file to store CAS numbers (one per line for Python stdin)
    temp_file = tempname;
    fid = fopen(temp_file, 'w');
    fprintf(fid, '%s\n', cas_numbers{:});
    fclose(fid);
    
    % Call the Python script with stdin redirection
    [status, output] = system(sprintf('python get_fp2.py < %s', temp_file));
    
    % Delete the temporary file
    delete(temp_file);
    
    % Check if the Python script ran successfully
    if status ~= 0
        error('Error running Python script: %s', output);
    end
    
    % Parse the JSON output from Python
    results_struct = jsondecode(output);
    
    % Convert the results to a cell array: {CAS, flash_points}
    results = cell(length(cas_numbers), 2);
    for i = 1:length(cas_numbers)
        cas = cas_numbers{i};
        results{i,1} = cas;
        
        % Mangle CAS to match jsondecode's field name conversion
        mangled = mangleFieldName(cas);
        
        if isfield(results_struct, mangled)
            results{i,2} = results_struct.(mangled);
        else
            results{i,2} = {};
        end
    end
end

% Helper function to mimic matlab.lang.makeValidName (for compatibility)
function mangled = mangleFieldName(str)
    mangled = regexprep(str, '[^a-zA-Z0-9_]', '_');
    if ~isempty(mangled) && (isstrprop(mangled(1), 'digit') || strcmp(mangled(1), '_'))
        mangled = ['x' mangled];
    end
end
