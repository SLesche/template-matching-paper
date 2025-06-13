function[] = run_simulation(n_simuls, sliced_trials, time_vec, method_table, db_location)

    % Sliced trials should be an array with n_subjects entries
    n_subjects = length(sliced_trials);
    n_params = 5; % a, b, latency, fit_cor, fit_distance
    polarity = 'positive'; %TODO: Make variable
    
    % initialize simulation-options
    if method_table.approach == "maxcor" || method_table.approach == "minsq"
        is_template_matching = 1;
    elseif method_table.approach == "peak" || method_table.approach == "area"|| method_table.approach == "liesefeld_area" || method_table.approach == "liesefeld_p2p_area"
        is_template_matching = 0;
    else
        error("Set a proper matching approach");
    end
    
    if method_table.weight ~= "none"
        weight_function = eval(strcat("@", method_table.weight));
    else
        weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
    end
    
    if method_table.penalty ~= "none"
        penalty_function = eval(strcat("@", method_table.penalty));
    else 
        penalty_function = @(a, b) 1;
    end
    
    if method_table.normalize ~= "none"
        normalize_function = eval(strcat("@", method_table.normalize)); 
    else
        normalize_function = @(x) x;
    end


    if method_table.window_name == "p3_250_700"
        window_control = [250 700];
        window_simul = [250 700];
    elseif method_table.window_name == "p3_250_900"
        window_control = [250 900];
        window_simul = [250 900];
    elseif method_table.window_name == "p3_200_700"
        window_control = [200 700];
        window_simul = [200 700];
    elseif method_table.window_name == "p3_300_600"
        window_control = [300 600];
        window_simul = [300 600];
    end

    eval_function = NaN;
    fix_a_param = 0;
     if method_table.approach == "minsq"
        eval_function = @eval_sum_of_squares;
        fix_a_param = 0;
    elseif method_table.approach == "maxcor"
        eval_function = @eval_correlation;
        fix_a_param = 1;
    end

    cfg = [];
    cfg.times     = time_vec;           %tell the function about the time axis
    cfg.sign      = 1;              %search for a positive component
    cfg.percAmp   = 0.3;            %percentage of amplitude for on- and offsets
    cfg.percArea  = 0.5;            %defaults to 50% anyway
    cfg.peakWin   = window_control;      %set window for searching the peak
    cfg.chans = 1;
    cfg.timeFormat = 'ms';
    cfg.peakWidth = 5;
    cfg.cWinWidth = -100;
    cfg.fig = false;
    cfg.extract   = 'areaLat';
    
    % Result of a simulation is task_id, method_id, simul_id, mean_b, sd_b and icc
    simul_overall = zeros(n_simuls, 6);
    simul_subject = zeros(n_simuls, n_subjects);
    
    % Set the simulation params
    % Set rng for same stretch for all methods
    rng(2024);
    % Between participant variance in strength
    mean_b = normrnd(method_table.simulation_stretch, method_table.simulation_sd, 1, n_subjects); % Draw this from normal distribution for all participants
    stretch_sd = method_table.stretch_sd;
    rng 'shuffle'
    parfor isimul = 1:n_simuls
        % Now take the trials per person and generate a new, simulated ERP that is
        % shifted by some factor. only for one electrode
        % Save this into a matrix of n_subjects X n_times
        simul_mat = zeros(n_subjects, length(time_vec));
        control_mat = zeros(n_subjects, length(time_vec));   
        results_simul = zeros(n_subjects, n_params);
        results_control = zeros(n_subjects, n_params);
        simul_id = isimul;
        
        for isubject = 1:n_subjects
            trials = sliced_trials{isubject};
            % Randomly select control and experimental trials
            % Get number of trials to iterate over
            [~, ~, n_trials] = size(trials);
            
            rng 'shuffle';
            random_trial_ids = randperm(n_trials);

            control_trial_ids = random_trial_ids(1:floor(n_trials/2));
            simul_trial_ids = random_trial_ids(floor(n_trials/2)+1: 2.*floor(n_trials/2));
            
            control_trials = trials(:, :, control_trial_ids);
            simul_trials = trials(:, :, simul_trial_ids);
            
            % Save the control EKP
            control_mat(isubject, :) = mean(control_trials, 3, "omitnan");

            % a_param set to 1
            simul_mat(isubject, :) = interpolate_transformed_template(time_vec, mean(simul_trials, 3, "omitnan"), 1, normrnd(mean_b(isubject), stretch_sd, 1, 1));
        end

        % Matching
        ga_simul = mean(simul_mat(:, :), 1, "omitnan");
        ga_control = mean(control_mat(:, :), 1, "omitnan");            

        lat_ga_simul = approx_area_latency(time_vec, ga_simul, [window_simul(1) window_simul(2)], polarity, 0.5, true);
        lat_ga_control = approx_area_latency(time_vec, ga_control, [window_control(1) window_control(2)], polarity, 0.5, true);

            % Match simul ekps
            if is_template_matching
                for isubject = 1:n_subjects
                    signal = simul_mat(isubject, :);
                    %eval_function = NaN;
                   
                    params = run_multi_start(define_optim_problem(specify_objective_function(time_vec', signal', ga_simul', [window_simul(1) window_simul(2)], polarity, weight_function, eval_function, normalize_function ,penalty_function, 0, fix_a_param), fix_a_param), fix_a_param);
                    if fix_a_param == 1
                        params = [1 params];
                    end
                    results_simul(isubject, [1 2]) = params;
                    results_simul(isubject, 3) = return_matched_latency(params(2), lat_ga_simul);
                    results_simul(isubject, [4 5]) = get_fits(time_vec', signal', ga_simul', [window_simul(1) window_simul(2)], polarity, weight_function, params(1), params(2));
                end
            else
                for isubject = 1:n_subjects
                    latency = NaN;
                    signal = simul_mat(isubject, :);
                    if method_table.approach == "area"
                        latency = approx_area_latency(time_vec, signal, [window_simul(1) window_simul(2)], polarity);
                    elseif method_table.approach == "peak"
                        latency = approx_peak_latency(time_vec, signal, [window_simul(1) window_simul(2)], polarity);
                    elseif method_table.approach == "liesefeld_area"
                        latency = approx_area_latency(time_vec, signal, [window_simul(1) window_simul(2)], polarity, 0.5, true);
                    elseif method_table.approach == "liesefeld_p2p_area"
                        latency = liesefeld_latency(cfg, reshape(signal, [1, 1, length(time_vec)]));
                    end
    
                    results_simul(isubject, 3) = latency;
                end
            end

        % Match control ekps
        if is_template_matching
            for isubject = 1:n_subjects
                signal = control_mat(isubject, :);
                %eval_function = NaN;
                
                params = run_multi_start(define_optim_problem(specify_objective_function(time_vec', signal', ga_control', [window_control(1) window_control(2)], polarity, weight_function, eval_function, normalize_function ,penalty_function, 0, fix_a_param), fix_a_param), fix_a_param);
                if fix_a_param == 1
                    params = [1 params];
                end
                results_control(isubject, [1 2]) = params;              
                results_control(isubject, 3) = return_matched_latency(params(2), lat_ga_control);
                results_control(isubject, [4 5]) = get_fits(time_vec', signal', ga_control', [window_control(1) window_control(2)], polarity, weight_function, params(1), params(2));
            end
        else
            for isubject = 1:n_subjects
                latency = NaN;
                signal = control_mat(isubject, :);
                if method_table.approach == "area"
                    latency = approx_area_latency(time_vec, signal, [window_control(1) window_control(2)], polarity);
                elseif method_table.approach == "peak"
                    latency = approx_peak_latency(time_vec, signal, [window_control(1) window_control(2)], polarity);
                elseif method_table.approach == "liesefeld_area"
                    latency = approx_area_latency(time_vec, signal, [window_control(1) window_control(2)], polarity, 0.5, true);
                elseif method_table.approach == "liesefeld_p2p_area"
                    latency = liesefeld_latency(cfg, reshape(signal, [1, 1, length(time_vec)]));
                end
                results_control(isubject, 3) = latency;
            end
        end

        empirical_shift = results_control(:, 3)./results_simul(:, 3);
    
        if is_template_matching
            % remove bad fits here
            empirical_shift(results_simul(:, 4) < 0.5) = NaN;
        end
    
        % write info into subject-level matrix
        simul_subject(isimul, :) = empirical_shift';
        
        % Protect against NaN
        protected_mean_b = mean_b';
        protected_mean_b(isnan(empirical_shift)) = [];
        empirical_shift(isnan(empirical_shift)) = [];
    
        mean_shift = prod(empirical_shift) .^ (1/length(empirical_shift));
        sd_shift = sqrt(sum((empirical_shift - mean_shift).^2) / (length(empirical_shift) - 1));
        computed_icc = compute_icc([protected_mean_b, empirical_shift]');
        simul_overall(isimul, :) = [method_table.task_id, method_table.method_id, simul_id, mean_shift, sd_shift, computed_icc];

        
        % Write into raw data
        simul_table = convert_result_matrix_to_table(results_simul, method_table.task_id, method_table.method_id, simul_id, ones(1, n_subjects), mean_b, ["b_param", "latency", "fit_cor", "fit_distance"], 1:n_subjects);
          
        % Write into raw data
        control_table = convert_result_matrix_to_table(results_control, method_table.task_id, method_table.method_id, simul_id, zeros(1, n_subjects), ones(1, n_subjects), ["b_param", "latency", "fit_cor", "fit_distance"], 1:n_subjects);
         
        write_exponential_backoff(db_location, ["data"], {simul_table});
        write_exponential_backoff(db_location, ["data"], {control_table});
    end
    
    % average shifts on subject level
    mean_subject_shift = zeros(1, n_subjects);
    sd_subject_shift = zeros(1, n_subjects);
    for isubject = 1:n_subjects
        % Remove nan
        shifts = simul_subject(:, isubject);
        shifts(isnan(shifts)) = [];
        mean_subject_shift(isubject) = prod(shifts) .^ (1/length(shifts));
        sd_subject_shift(isubject) = sqrt(sum((shifts - mean_subject_shift(isubject)).^2) / (length(shifts) - 1));
    end
    
    subject_mat = [repelem(method_table.task_id, n_subjects); repelem(method_table.method_id, n_subjects); 1:n_subjects; mean_b; mean_subject_shift; sd_subject_shift]';

    % Save overall information
    write_exponential_backoff(db_location, ["subject"], {array2table(subject_mat, 'VariableNames', ["task_id", "method_id", "subject_id", "true_shift", "mean_shift", "sd_shift"])})
    write_exponential_backoff(db_location, ["simulation"], {array2table(simul_overall, 'VariableNames',["task_id", "method_id", "simulation_id", "mean_shift", "sd_shift", "icc"])})

    disp(['Method ID: ', num2str(method_table.method_id), ' done'])
end