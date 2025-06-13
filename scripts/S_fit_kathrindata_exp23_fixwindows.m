clear all;
load("saved_data/kathrinexp23_data.mat");
load("saved_data/kathrinexp23_times.mat");

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

% Full files
path_extensions_task = ["flanker/", "nback/", "switching/"];
path_extensions_age = ["young/", "old/"];
path_extensions_filter = ["0hz/", "4hz/", "8hz/", "16hz/", "32hz/"];

n_tasks = length(path_extensions_task);
n_groups = length(path_extensions_age);
n_filter = length(path_extensions_filter);

% Convert to cell array with conditionsXn_subject entries 
component_names = {"p3_250_700", "p3_250_900", "p3_200_700", "p3_300_600"};
n_components = length(component_names);
component_electrodes = {1, 1, 1, 1};
component_polarity = {'positive', 'positive', 'positive', 'positive'};
component_windows = {[250 700], [250 900], [200 700], [300 600]};

% For fitting
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

writetable(comb, "results/method_combinations_revision.csv")
n_methods = height(comb);

full_results = cell(n_tasks, n_groups, n_filter);
for itask = 1:n_tasks
    for igroup = 1:n_groups
        for ifilter = 1:n_filter
            relevant_data = erp_data{itask, igroup, ifilter};
            [n_subjects, n_chans, n_times, n_bins] = size(relevant_data);
            % resulting latency
            n_params = 5; % a_param, b_param, latency, fit_cor, fit_distance

            results = zeros(n_components, n_methods, n_subjects, n_bins, n_params);

            for icomponent = 1:n_components
                for imethod = 1:n_methods
                    polarity = component_polarity{icomponent};
                             
                    % init  ialize fitting-options
                    if table2array(comb(imethod, "possible_approaches")) == "maxcor" || table2array(comb(imethod, "possible_approaches")) == "minsq"
                        is_template_matching = 1;
                    elseif table2array(comb(imethod, "possible_approaches")) == "peak" || table2array(comb(imethod, "possible_approaches")) == "area" || table2array(comb(imethod, "possible_approaches")) == "liesefeld_area" || table2array(comb(imethod, "possible_approaches")) == "liesefeld_p2p_area"
                        is_template_matching = 0;
                    else
                        error("Set a proper matching approach");
                    end
                    
                    if table2array(comb(imethod, "possible_weights")) ~= "none"
                        weight_function = eval(strcat("@", table2array(comb(imethod, "possible_weights"))));
                    else
                        weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
                    end
                    
                    if table2array(comb(imethod, "possible_penalty")) ~= "none"
                        penalty_function = eval(strcat("@", table2array(comb(imethod, "possible_penalty"))));
                    else 
                        penalty_function = @(a, b) 1;
                    end
                    
                    if table2array(comb(imethod, "possible_normalization")) ~= "none"
                        normalize_function = eval(strcat("@", table2array(comb(imethod, "possible_normalization")))); 
                    else
                        normalize_function = @(x) x;
                    end
        
                    if table2array(comb(imethod, "possible_approaches")) == "minsq"
                        eval_function = @eval_sum_of_squares;
                        fix_a_param = 0;
                    elseif table2array(comb(imethod, "possible_approaches")) == "maxcor"
                        eval_function = @eval_correlation;
                        fix_a_param = 1;
                    end

                    cfg = [];
                    cfg.times     = time_vec;           %tell the function about the time axis
                    cfg.sign      = 1;              %search for a positive component
                    cfg.percAmp   = 0.3;            %percentage of amplitude for on- and offsets
                    cfg.percArea  = 0.5;            %defaults to 50% anyway
                    cfg.peakWin   = component_windows{icomponent};      %set window for searching the peak
                    cfg.chans = 1;
                    cfg.timeFormat = 'ms';
                    cfg.peakWidth = 5;
                    cfg.cWinWidth = -100;
                    cfg.fig = false;
                    cfg.extract   = 'areaLat';
            
                    bin_results = cell(1, n_bins);
                    parfor ibin = 1:n_bins
                        match_results = zeros(n_subjects, n_params);
                        % Get the GA here, get corresponding approach and other pars
                        ga = squeeze(mean(relevant_data(:, component_electrodes{icomponent}, :, ibin), 1));                            
                        % Get the appropriate measurement window
                        window = component_windows{icomponent};
                        
                        if is_template_matching
                            lat_ga = approx_area_latency(time_vec, ga, [window(1) window(2)], polarity, 0.5, true);

                            for isubject = 1:n_subjects
                                signal = squeeze(relevant_data(isubject, component_electrodes{icomponent}, :, ibin));
                                params = run_global_search(define_optim_problem(specify_objective_function(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, eval_function, normalize_function ,penalty_function, 0, fix_a_param), fix_a_param));
                                
                                if fix_a_param == 1
                                    params = [1 params];
                                end
                                match_results(isubject, [1 2]) = params;
                                match_results(isubject, 3) = return_matched_latency(params(2), lat_ga);
                                match_results(isubject, [4 5]) = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, params(1), params(2));
                                
                                %{
                                results(icomponent, imethod, isubject, ibin, [1 2]) = params;
                                results(icomponent, imethod, isubject, ibin, 3) = return_matched_latency(params(2), lat_ga);
                                results(icomponent, imethod, isubject, ibin, [4 5]) = get_fits(time_vec', signal, ga, [window(1) window(2)], polarity, weight_function, params(1), params(2));
                                %}
                            end
                        else
                            for isubject = 1:n_subjects
                                latency = NaN;
                                signal = squeeze(relevant_data(isubject, component_electrodes{icomponent}, :, ibin));
                                if table2array(comb(imethod, "possible_approaches")) == "area"
                                    latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5);
                                elseif table2array(comb(imethod, "possible_approaches")) == "liesefeld_area"
                                    latency = approx_area_latency(time_vec, signal, [window(1) window(2)], polarity, 0.5, true);
                                elseif table2array(comb(imethod, "possible_approaches")) == "peak"
                                    latency = approx_peak_latency(time_vec, signal, [window(1) window(2)], polarity);
                                elseif table2array(comb(imethod, "possible_approaches")) == "liesefeld_p2p_area"                                    
                                    latency = liesefeld_latency(cfg, reshape(signal, [1, 1, 1200]));
                                end
                                match_results(isubject, [1 2 4 5]) = NaN;
                                match_results(isubject, 3) = latency;
                                %{
                                results(icomponent, imethod, isubject, ibin, [1 2 4 5]) = NaN;
                                results(icomponent, imethod, isubject, ibin, 3) = latency;
                                %}
                            end
                        end

                        bin_results{ibin} = match_results
                    end

                    for ibin = 1:n_bins
                        results(icomponent, imethod, :, ibin, :) = bin_results{ibin};
                    end
                    disp("Method done")
                end
                disp("Component done")
            end
            disp("Setting done")
            % Save results here
            full_results{itask, igroup, ifilter} = results;
        end
    end
end

save("results/results_kathrinexp23_revision.mat", 'full_results');
