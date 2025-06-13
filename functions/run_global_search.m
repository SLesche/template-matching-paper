function [params, f] = run_global_search(problem)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here
gs = GlobalSearch('MaxTime', 60, 'Display', 'off');
[params, f] = run(gs, problem);
end