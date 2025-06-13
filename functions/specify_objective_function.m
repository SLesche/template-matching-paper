function [objective_func] = specify_objective_function(time_vector, template, signal, measurement_window, polarity, weight_function, eval_function, normalize_function, penalty_function, use_derivative, fix_a_param)
%UNTITLED12 Summary of this function goes here
%   Detailed explanation goes here
if ~exist('normalize_function', 'var')
    normalize_function = @(x) x;
end

if ~exist('penalty_function', 'var')
    penalty_function = @(a, b) 1;
end

if ~exist('weight_function', 'var')
    weight_function = @(time_vector, signal, window) ones(length(time_vector), 1);
end

if ~exist('use_derivative', 'var')
    use_derivative = 0;
end

if ~exist('fix_a_param', 'var')
    fix_a_param = 0;
end

splined_template = spline(time_vector(~isnan(template)), normalize_function(template(~isnan(template))));
normalized_signal = normalize_function(signal);

% Flip if polarity is negative
switch polarity
    case 'positive'
        peak_factor = 1;
    case 'negative'
        peak_factor = -1;
end

weights = weight_function(time_vector, normalized_signal.*peak_factor, measurement_window);

if use_derivative == 1
    template_deriv = [0; diff(template)];
    signal_deriv = normalize_function([0; diff(signal)]);
    
    splined_template_deriv = spline(time_vector(~isnan(template_deriv)), normalize_function(template_deriv(~isnan(template_deriv))));

    if fix_a_param == 0
        objective_func = @(a, b) (eval_function(time_vector, splined_template_deriv, signal_deriv, weights, a, b) + eval_function(time_vector, splined_template, normalized_signal, weights, a, b)) .* penalty_function(a, b);
    else 
        objective_func = @(b) (eval_function(time_vector, splined_template_deriv, signal_deriv, weights, 1, b) + eval_function(time_vector, splined_template, normalized_signal, weights, 1, b)) .* penalty_function(1, b);
    end
else
    if fix_a_param == 0
        objective_func = @(a, b) eval_function(time_vector, splined_template, normalized_signal, weights, a, b) .* penalty_function(a, b);
    else
        objective_func = @(b) eval_function(time_vector, splined_template, normalized_signal, weights, 1, b) .* penalty_function(1, b);
    end
end

end