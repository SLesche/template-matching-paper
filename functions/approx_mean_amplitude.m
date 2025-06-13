function [mean_amplitude] = approx_mean_amplitude(erp, bin, b_param, fit_setup, peak_polarity)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    if b_param < 0.5 || b_param > 3
        b_param = NaN;
    end

    if isnan(b_param)
        splitTime = NaN;
        return
    end

    if ~exist('fraction', 'var')
        fraction = 0.5;
    end

    switch peak_polarity
        case 'positive'
            peak_factor = 1;
        case 'negative'
            peak_factor = -1;
    end

    times = erp.times; 

    signal = erp.bindata(fit_setup.electrodes, :, bin);
    signal = signal * peak_factor;
    signal(signal < 0) = 0;

    mean_window = mean(fit_setup.custom_window);
    diff_windows = mean_window - fit_setup.custom_window;
    transformed_window = mean_window * b_param - diff_windows;

    max_times = max(erp.times) - 20;
    min_times = 0;

    if transformed_window(2) > max_times
        transformed_window(1) = transformed_window(1) - (transformed_window(2) - transformed_window(1));
        transformed_window(2) = max_times;
    end    
    
    if transformed_window(1) < min_times
        transformed_window(1) = 0;
    end

    startTime = transformed_window(1);
    endTime = transformed_window(2);

    timeDiffStart = abs(times - startTime);
    timeDiffEnd = abs(times - endTime);

    [~, startIndex] = min(timeDiffStart);
    [~, endIndex] = min(timeDiffEnd);

    if startIndex > length(signal) || startTime >= endTime
        error('Invalid input arguments.');
    end
    
    % Calculate the total sum and cumulative sum of the signal within the window
    signalWindow = signal(startIndex:endIndex);
    if length(signalWindow(signalWindow ~= 0)) < 50
        mean_amplitude = NaN;
        return
    end
    
    mean_amplitude = mean(signalWindow);
end