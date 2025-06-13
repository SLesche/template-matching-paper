function [peak_amplitude] = approx_peak_amplitude(time_vector, signal, measurement_window, peak_polarity)
    switch peak_polarity
        case 'positive'
            peak_factor = 1;
        case 'negative'
            peak_factor = -1;
    end
    signal = signal * peak_factor;

    % filter out those that are not greater than the average next three or previous 5 data points
    max_val = -Inf;

    n_points = 3;
    for i = (n_points + 1):length(signal)-n_points
        if time_vector(i) >= measurement_window(1) && time_vector(i) <= measurement_window(2)
            if signal(i) > mean(signal(i-n_points:i-1)) && signal(i) > mean(signal(i+1:i+n_points))
                max_val = max(max_val, signal(i));
            end
        end
    end

    if max_val == -Inf
        peak_amplitude = NaN;
        return
    end
    peak_amplitude = max_val;

end