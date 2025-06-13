function [fits] = get_fits(time_vector, template, signal, measurement_window, polarity, weight_function, a_param, b_param)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Flip if polarity is negative
switch polarity
    case 'positive'
        peak_factor = 1;
    case 'negative'
        peak_factor = -1;
end

weights = weight_function(time_vector, signal.*peak_factor, measurement_window);

% Correlation-based fit
fit_weighted_cor = get_weighted_correlation(signal, interpolate_transformed_template(time_vector, template, a_param, b_param), weights);
% Distance-based fit
fit_distance = sum(weights.*(normalize_signal(signal) - normalize_signal(interpolate_transformed_template(time_vector, template, a_param, b_param))).^2, "omitnan") / sum(weights);
fits = [fit_weighted_cor fit_distance];
end