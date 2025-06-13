function [ERP, ALLERP] = fetch_erp_files(path, keyword)
%fetch_erp_files returns all files ending in .erp that contain the specified keyword in the name
%   
%   [ERP, ALLERP] = fetch_erp_files(path, keyword) returns a structure containing the EEG data for
%   all files in the specified directory that end with ".erp" and contain the given keyword in their
%   name. It loads the ERP files using the 'pop_loaderp' function from the EEGLAB toolbox and returns 
%   the resulting 'ERP' and 'ALLERP' variables.
%
%   Inputs:
%       - path: The directory path where the ERP files are located
%       - keyword: A keyword to search for in the file names
%
%   Outputs:
%       - ERP: A structure containing the EEG data for all files that match the specified criteria
%       - ALLERP: An array of structures containing the EEG data for each individual file that 
%           matches the specified criteria
 
if ~exist('keyword','var')
    % keyword doesnt exist, get full files
    list = dir([path, '\*.erp']);
else
    list = dir([path,'\*', keyword,'*.erp']);
end

arr = {};
for i = 1:length(list)
    arr{i} = fullfile(list(i).name);
end

[ERP ALLERP] = pop_loaderp('filename', arr, 'filepath', path);

end
