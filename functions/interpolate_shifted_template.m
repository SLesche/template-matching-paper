function [transformed_signal] = interpolate_shifted_template(time_vector, template, shift)
    % Interpolates a shifted template with smooth transition
    
    % Initialize with NaN to prevent extrapolation
    transformed_signal = NaN(length(time_vector), 1);
    
    % Where time <= 0, no shift applied
    transformed_signal(time_vector <= 0) = template(time_vector <= 0);
    
    % Shift template and interpolate
    shifted_time = time_vector - shift;
    valid_indices = (shifted_time >= min(time_vector)) & (shifted_time <= max(time_vector));
    
    % Perform interpolation only on valid indices
    if any(valid_indices)
        interpolated_values = interp1(time_vector, template, shifted_time(valid_indices), 'spline', 0);
        transformed_signal(valid_indices) = interpolated_values;
    end
    
    % Ensure values before shift are zero
    transformed_signal(time_vector > 0 & time_vector <= shift) = 0;
end
