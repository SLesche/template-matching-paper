function [results_table] = convert_result_matrix_to_table(result_mat, task_id, method_id, simulation_id, is_simulation, mean_b, param_names, subject_ids)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
[n_subjects, ~] = size(result_mat);

if ~exist("param_names", "var")
    param_names = ["b_param", "latency", "fit_cor", "fit_distance"];
end

if ~exist("subject_ids", "var")
    subject_ids = 1:n_subjects;
end

method_id_vec = repelem(method_id, n_subjects)';
task_id_vec = repelem(task_id, n_subjects)';
simulation_id_vec = repelem(simulation_id, n_subjects)';

full_mat = [task_id_vec, method_id_vec, simulation_id_vec, subject_ids', is_simulation', mean_b', result_mat];
full_mat(:, 7) = []; % Remove a param
results_table = array2table(full_mat,'VariableNames',["task_id", "method_id", "simulation_id", "subject", "is_simulation", "simulation_shift", param_names]);


end