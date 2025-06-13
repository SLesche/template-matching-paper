function [] = plot_algo_results(time_vec, ga, erp, window, polarity, method_table)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    % init  ialize fitting-options
    if table2array(method_table(1, "possible_approaches")) == "maxcor" || table2array(method_table(1, "possible_approaches")) == "minsq"
        is_template_matching = 1;
    elseif table2array(method_table(1, "possible_approaches")) == "peak" || table2array(method_table(1, "possible_approaches")) == "area" || table2array(method_table(1, "possible_approaches")) == "liesefeld_area"
        is_template_matching = 0;
    else
        error("Set a proper matching approach");
    end
    
    if table2array(method_table(1, "possible_weights")) ~= "none"
        weight_function = eval(strcat("@", table2array(method_table(1, "possible_weights"))));
    else
        weight_function = @(time_vector, erp, window) ones(length(time_vector), 1);
    end
    
    if table2array(method_table(1, "possible_penalty")) ~= "none"
        penalty_function = eval(strcat("@", table2array(method_table(1, "possible_penalty"))));
    else 
        penalty_function = @(a, b) 1;
    end
    
    if table2array(method_table(1, "possible_normalization")) ~= "none"
        normalize_function = eval(strcat("@", table2array(method_table(1, "possible_normalization")))); 
    else
        normalize_function = @(x) x;
    end

    if table2array(method_table(1, "possible_approaches")) == "minsq"
        eval_function = @eval_sum_of_squares;
    elseif table2array(method_table(1, "possible_approaches")) == "maxcor"
        eval_function = @eval_correlation;
    end

    use_derivative = table2array(method_table(1, "possible_derivative"));

    %lat_ga = approx_area_latency(time_vec, ga, [window(1) window(2)], polarity, 0.5, true, false);
    % Use this in case of no negative going signal
    lat_ga = approx_peak_latency(time_vec, ga, [window(1) window(2)], polarity);

    % try derivative matching
    ga_deriv = [0; diff(ga)];
    erp_deriv = [0; diff(erp)];

    params = run_multi_start(define_optim_problem(specify_objective_function(time_vec', erp_deriv, ga_deriv, [window(1) window(2)], polarity, weight_function, eval_function, normalize_function,penalty_function, use_derivative)));
    
    match_results = zeros(1, 5);
    match_results(1, [1 2]) = params;
    match_results(1, 3) = return_matched_latency(params(2), lat_ga);
    match_results(1, [4 5]) = get_fits(time_vec', erp, ga, [window(1) window(2)], polarity, weight_function, params(1), params(2));
    
    % plotting flanker
    plot(time_vec, erp, 'Color', "#0072BD", 'LineWidth', 1.5)
    hold on
    xline(match_results(3), 'Color', "magenta", 'LineWidth', 1.5, 'LineStyle', '--')
    plot(time_vec, interpolate_transformed_template(time_vec, ga, 1/params(1), 1/params(2)), 'Color', "#D95319",'LineWidth', 1.5)
    % Reverse Y-axis direction
    set(gca, 'YDir', 'reverse')
    
    % Set X and Y axis properties
    ax = gca;
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    set(gca, 'TickDir', 'in')
    ax.XRuler.TickLabelGapOffset = -20;
    
    % Adjust labels position
    Ylm = ylim;
    Xlm = xlim;
    Xlb = 0.90 * Xlm(2);
    Ylb = 0.90 * Ylm(1);
    xlabel('ms', 'Position', [Xlb 0.75]);
    ylabel('µV', 'Position', [-100 Ylb]);
    
    hold off
          
end