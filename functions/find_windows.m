function [window] = find_windows(signal, time_vec, range, peak_polarity, percent_amp, percent_buffer)
    peak_amp = approx_peak_amplitude(time_vec, signal, range, peak_polarity);
    peak_lat = approx_peak_latency(time_vec, signal, range, peak_polarity);
    
    percent_max_amp = peak_amp .* percent_amp;

    window_lower = -Inf;
    window_upper = Inf;

    itime = 1:length(time_vec);
    ipeak_lat = itime(time_vec == peak_lat);

    for i = ipeak_lat:length(time_vec)
        if signal(i) < percent_max_amp
            window_upper = time_vec(i);
            break;
        end
    end

    for i = linspace(ipeak_lat, 1, ipeak_lat)
        if signal(i) < percent_max_amp
            window_lower = time_vec(i);
            break;
        end
    end

    if window_upper == Inf
        window_upper = max(time_vec);
    end

    if window_lower == -Inf
        window_lower = 0;
    end

    window_size = window_upper - window_lower;

    buffer = window_size .* percent_buffer;

    window_lower = window_lower - buffer;
    window_upper = window_upper + buffer;

    if window_upper > max(time_vec)
        window_upper = max(time_vec);
    end

    if window_lower < 0
        window_lower = 0;
    end
    
    window = [window_lower, window_upper];
end


