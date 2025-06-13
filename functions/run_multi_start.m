function [params] = run_multi_start(problem, fix_a_param)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
% Define possible start points

if ~exist('fix_a_param', 'var')
    fix_a_param = 0;
end

possible_bs = linspace(0.6, 1.8, 10) + randn(1, 10).*0.01;

if fix_a_param == 1
    start_matrix = possible_bs';
else
    possible_as = linspace(0.75, 1.5, 3) + randn(1, 3).*0.02;
    start_matrix = get_start_point_matrix(possible_as, possible_bs);
end

% Run multistart
ms = MultiStart('MaxTime', 60, 'Display', 'off');
[params, ~] = run(ms, problem, CustomStartPointSet(start_matrix));
end