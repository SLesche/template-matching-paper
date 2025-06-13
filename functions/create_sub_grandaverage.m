function allerp = create_sub_grandaverage(allerp, n_sub_grandaverage)
% DOCUMENTATION

n_subjects = length(allerp);
for i = 1:n_subjects
    % Only include N - 1 random samples
    subject_sample = datasample(find(1:n_subjects ~= i), n_sub_grandaverage - 1, 'Replace', false);

    % Add the subject number to the grand average
    subject_sample = sort([subject_sample, i]);


    % EEGLAB-averaging
    allerp(i).grand_average = pop_gaverager( ...
        allerp, 'DQ_flag', 0, 'Erpsets', subject_sample,...
        'ExcludeNullBin', 'on', 'SEM', 'on');
    
    % allerp(i).grand_average = custom_grand_average(allerp, subject_sample);
end

end