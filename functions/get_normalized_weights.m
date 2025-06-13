function [weights] = get_normalized_weights(time_vector, signal, measurement_window)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% Normalize signal within measurement window
% need the maximum and minimum value within the measurement window
is_relevant = time_vector >= measurement_window(1) & time_vector <= measurement_window(2);
max_amp = max(signal(is_relevant));
min_amp = min(signal(is_relevant));

norm_signal = (signal - min_amp) / (max_amp - min_amp);

% Initialize weights with one. replace the relevant parts with norm signal
weights = ones(length(time_vector), 1);

weights(is_relevant) = (10.*abs(norm_signal(is_relevant))).^2;
end