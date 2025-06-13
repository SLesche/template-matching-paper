clear all;
% Setting paths
% Get the directory of the currently executing script
[filepath, ~, ~] = fileparts(mfilename('fullpath'));

% Set the current directory to that directory
cd(filepath);
PATH_MAIN =  filepath; % Pfad in dem das Skript liegt
PATH_ERP = fullfile(PATH_MAIN, 'erp/'); % Pfad für ERP
cd(PATH_MAIN);

% Path for files
PATH_ERP23 = fullfile(PATH_ERP, "kathrin_exp23\");
PATHS = [];

% Full files
path_extensions_task = ["flanker/", "nback/", "switching/"];
path_extensions_age = ["young/", "old/"];
path_extensions_filter = ["0hz/", "4hz/", "8hz/", "16hz/", "32hz/"];

n_tasks = length(path_extensions_task);
n_groups = length(path_extensions_age);
n_filter = length(path_extensions_filter);

% Load erpfiles
eeglab;

erp_data = cell(n_tasks, n_groups, n_filter);

n_trials_retained = zeros(n_tasks, n_groups, n_filter, 30, 6);

for itask = 1:n_tasks
    for iage = 1:n_groups
        for ifilter = 1:n_filter
            path = fullfile(PATH_ERP23, strcat(path_extensions_task(itask), path_extensions_age(iage), path_extensions_filter(ifilter), 'erp/'));
            [erp, allerp] = fetch_erp_files(char(path));

            n_subjects = length(allerp);
            [~, n_times, n_bins] = size(allerp(1).bindata);

            subject_data = zeros(n_subjects, 1, n_times, n_bins);
            for isubject = 1:n_subjects
                subject_data(isubject, :, :, :) = allerp(isubject).bindata(11, :, :);

                n_trials_retained(itask, iage, ifilter, isubject, :) = allerp(isubject).ntrials.accepted;
            end
            erp_data{itask, iage, ifilter} = subject_data;    
        end
    end
end

time_vec = allerp(1).times;

mean(squeeze(mean(squeeze(mean(squeeze(n_trials_retained(1, :, :, :, :)), 1)), 1)))

save("saved_data/kathrinexp23_data.mat", 'erp_data');
save("saved_data/kathrinexp23_times.mat", 'time_vec');