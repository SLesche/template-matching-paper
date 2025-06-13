function[] = write_exponential_backoff(db_location, table_name_array, data_array)
    maxTries = 1000;
    success = false;
    tries = 0;
    pause_time = 0.0001;

    if length(table_name_array) ~= length(data_array)
        error("Names and Number of Datasets must be equal")
    end

    % Try and save control
    while ~success && tries < maxTries
        tries = tries + 1;
        try
            % Your SQL write operation
            conn = sqlite(db_location);
            for idata = 1:length(data_array)
                sqlwrite(conn, table_name_array(idata), data_array{idata});
            end
            close(conn);
            
            % Set success flag to true if no error occurs
            success = true;
        catch exception
            % Optionally, wait for some time before retrying (if needed)
            disp(['Attempt ', num2str(tries), ': An error occurred: ', exception.message]);
            pause(pause_time); % Wait for 1 second
            pause_time = pause_time .*1.5;
            
            % You can choose to retry immediately or do something else based on the error
        end
    end

    if success
        %disp(['Simulation: ', num2str(isimul), ' completed successfully!']);
    else
        disp(['Exceeded maximum number of tries. Unable to complete operation for simulation: ', num2str(isimul)]);
    end