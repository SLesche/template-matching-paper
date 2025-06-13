function [problem] = define_optim_problem(objective_func, fix_a_param)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
lb = [0.20, 0.33];
ub = [20, 2];


if ~exist('fix_a_param', 'var')
    fix_a_param = 0;
end

rng default % For reproducibility
opts = optimoptions(@fmincon,'Algorithm','sqp');

if fix_a_param == 0
    problem = createOptimProblem('fmincon','objective',...
    @(x) objective_func(x(1), x(2)),'x0',[1 1] + normrnd(0, 0.01, 1, 2),'lb',lb,'ub',ub,'options',opts);

else
    problem = createOptimProblem('fmincon','objective',@(x) objective_func(x(1)),'x0',1 + normrnd(0, 0.01, 1, 1),'lb',lb(2),'ub',ub(2),'options',opts);
end
end