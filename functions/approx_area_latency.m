function [splitTime] = approx_area_latency(time_vector, signal, measurement_window, peak_polarity, fraction, liesefeld, remove_opposite)
    if ~exist('fraction', 'var')
        fraction = 0.5;
    end
    
    if ~exist('liesefeld', 'var')
        liesefeld = false;
    end

    if ~exist('remove_opposite', 'var')
        remove_opposite = true;
    end


    switch peak_polarity
        case 'positive'
            peak_factor = 1;
        case 'negative'
            peak_factor = -1;
    end
    
    signal = signal * peak_factor;

    if remove_opposite
        signal(signal < 0) = 0;
    end

    % Get starting indices
    timeDiffStart = abs(time_vector - measurement_window(1));

    [~, startIndex] = min(timeDiffStart);
    
    % Calculate the total sum and cumulative sum of the signal within the window
    signalWindow = signal(time_vector >= measurement_window(1) & time_vector <= measurement_window(2));
    if liesefeld == true
        % get maximum amplitude within the search window
        max_amp = max(signalWindow);

        % subtract half amplitude from signal window
        signalWindow = signalWindow - max_amp.*0.5;
    end

    signalWindow(signalWindow < 0) = 0;
    if length(signalWindow(signalWindow ~= 0)) < 10
        splitTime = NaN;
        return
    end
    
    totalSum = sum(signalWindow);
    cumulativeSum = cumsum(signalWindow);
    
    % Find the index where the cumulative sum crosses half of the total sum
    fraction_sum = totalSum * fraction;
    indexBefore = find(cumulativeSum < fraction_sum, 1, 'last');
    indexAfter = indexBefore + 1;
    
    % Interpolate to find the exact time point that accumulates half the area
    timeBefore = time_vector(startIndex + indexBefore - 1);
    timeAfter = time_vector(startIndex + indexAfter - 1);
    splitTime = interp1([cumulativeSum(indexBefore), cumulativeSum(indexAfter)], [timeBefore, timeAfter], fraction_sum);
end
