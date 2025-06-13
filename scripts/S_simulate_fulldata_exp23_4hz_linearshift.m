% first, read the data in
clear all

load("saved_data/exp23_data.mat");
load("saved_data/exp23_times.mat");

% create a local cluster object
pc = parcluster('local');

%{
% get the number of dedicated cores from environment
pc.NumWorkers = str2num(getenv('SLURM_CPUS_PER_TASK'));

% explicitly set the JobStorageLocation to the tmp directory that is unique to each cluster job (and is on local, fast scratch)
parpool_tmpdir = [getenv('TMP'),'/.matlab/local_cluster_jobs/slurm_jobID_',getenv('SLURM_JOB_ID')];
mkdir(parpool_tmpdir);
pc.JobStorageLocation = parpool_tmpdir;
%}

% start the parallel pool
parpool(pc);
addpath("../functions") % add template matching functions


% Saving information about dataset
[n_tasks, n_filters, n_conditions, n_subjects] = size(sliced_trials);
electrode = 11;
n_params = 5; % a, b, latency, fit_cor, fit_distance

% initialize simulation
n_simuls = 100;
db_location = "results/simulation_results_exp23_4hz_revision_linear_spline.db";

if ~exist(db_location, 'file')
    % create the database file
    initialize_simulation_db(db_location);
end

possible_tasks = ["flanker"];
possible_conditions = ["congruent"];
possible_filters = [4, 8, 16, 32];

current_task_id = 1;

window_options = {"p3_250_700", "p3_250_900", "p3_200_700", "p3_300_600"};

for itask = 1:length(possible_tasks)
    for ifilter = 1
        % Set task parameters
        rng 'shuffle'
        task_id = randi([1 10.^10]);
        task_description = strcat("Flanker Task");
        data_source = "exp23";
        task = "flanker";
        filter = possible_filters(ifilter);
        
        % write info to task table
        task_table = table(task_id, data_source, filter, task_description, task);
        
        write_exponential_backoff(db_location, ["task"], {task_table});
        
        % What combination of methods and other pars should be tested?
        % p3 first. 
        % MAXCOR/MINSQ/Peak/Areay
        % Both weighting functions for algos
        % Both normalization for algos
        % Penalty and no penalty for algos
        % Varying the stretch_sd (do later)
        possible_approaches = ["maxcor", "minsq"];
        possible_weights = ["none", "get_tukey_weights", "get_hamming_weights", "get_normalized_weights"];
        possible_normalization = ["none"];
        possible_penalty = ["none", "exponential_penalty"];
        
        comb = combinations(possible_approaches, possible_weights, possible_penalty, possible_normalization);
        % add peak/area with no weights/normalization/penalty
        comb(end+1, :) = {"peak", "none", "none", "none"};
        comb(end+1, :) = {"area", "none", "none", "none"};
        comb(end+1, :) = {"liesefeld_area", "none", "none", "none"};
        comb(end+1, :) = {"liesefeld_p2p_area", "none", "none", "none"};

        for imethod = 1:height(comb)
            for iwindow = 1:length(window_options)
                % Add method_id
                rng 'shuffle'
                method_id = randi([1 10.^10], 1);
                window_name = window_options{iwindow};
                component = "p3";
                polarity = 'positive';
                approach = comb.possible_approaches(imethod);
                weight = comb.possible_weights(imethod);
                normalize = comb.possible_normalization(imethod);
                penalty = comb.possible_penalty(imethod);
                simulation_stretch = 45;
                simulation_sd = 15;
                stretch_sd = 0;
                method_description = "none";    
                                
                % Save info to method table
                method_table = table(task_id, method_id, window_name, ...
                    component, approach, weight, normalize, ...
                    penalty, simulation_stretch, simulation_sd, stretch_sd, method_description);
                
                write_exponential_backoff(db_location, ["method"], {method_table});
            
                run_simulation_linear(n_simuls, sliced_trials{itask, ifilter}, time_vec, method_table, db_location)
                % disp(["Method ", num2str(imethod), " of ",num2str(height(comb)), " done."])
            end
        end
    end
end

