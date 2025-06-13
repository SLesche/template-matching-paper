function [weights] = get_tukey_weights(time_vector, ~, measurement_window)
    %UNTITLED15 Summary of this function goes here
    %   Detailed explanation goes here
    is_relevant = time_vector >= measurement_window(1) & time_vector <= measurement_window(2);
    
    % Initialize weights with one. replace the relevant parts with norm signal
    weights = zeros(length(time_vector), 1);

    % Calculate Hamming window weights
    weights(is_relevant) = tukeywin(sum(is_relevant), 0.25);
    
    end