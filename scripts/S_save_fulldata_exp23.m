clear all
%eeglab

[filepath, ~, ~] = fileparts(mfilename('fullpath'));

% Set the current directory to that directory
cd(filepath);
PATH_MAIN =  filepath; % Pfad in dem das Skript liegt
PATH_ERP = fullfile(PATH_MAIN, 'raw_data/exp23/'); % Pfad für ERP
cd(PATH_MAIN);

addpath("../functions")

% Path for files
PATHS = [];

% Full files
%path_extensions_task = ["flanker/", "nback/", "switching/"];
%path_extensions_filter = ["0Hz/", "4Hz/", "8Hz/", "16Hz/", "32Hz/", "64Hz/"];
path_extensions_task = ["flanker/"];
path_extensions_filter = ["4Hz/", "8Hz/", "16Hz/", "32Hz/"];

n_tasks = length(path_extensions_task);
n_filters = length(path_extensions_filter);

% Path for files
full_data = cell(n_tasks, n_filters);
for itask = 1:n_tasks
    for ifilter = 1:n_filters
        full_data{itask, ifilter} = fetch_autocleaned_files(convertStringsToChars(fullfile(PATH_ERP, strcat(path_extensions_task(itask), path_extensions_filter(ifilter), 'autocleaned/'))), 'autocleaned');
    end
end

% Filter by congruency
% Saving information about dataset
time_vec = full_data{1, 1}(1).erpset.times;
electrode = 11;

trials_retained = zeros(length(full_data{1, 1}), n_filters);

% Slice trials to be able to free up memory
n_conditions = 1;
sliced_trials = cell(n_tasks, n_filters, n_conditions);
for itask = 1:n_tasks
    for ifilter = 1:n_filters
        n_subjects_current = length(full_data{itask, ifilter});
        congruent_data = cell(1, n_subjects_current);
        incongruent_data = cell(1, n_subjects_current);
        for isubject = 1:n_subjects_current
            congruency = rmmissing({full_data{itask, ifilter}(isubject).erpset.event.Condition});
            is_congruent = strcmp(congruency, 'Congruent');
            congruent_data{1, isubject} = full_data{itask, ifilter}(isubject).erpset.data(electrode, :, is_congruent);

            trials_retained(isubject, ifilter) = sum(is_congruent);

            for itrial = 1:sum(is_congruent)
                congruent_data{1, isubject}(1, :, itrial) = congruent_data{1, isubject}(1, :, itrial) - mean(congruent_data{1, isubject}(1,find(time_vec == -200):find(time_vec == 0), itrial), 2);
            end
            
        end
        sliced_trials{itask, ifilter, 1} = congruent_data;
    end
end

% Remove data to clear memory
clear data

save("saved_data/exp23_data.mat", 'sliced_trials');
save("saved_data/exp23_times.mat", 'time_vec');
