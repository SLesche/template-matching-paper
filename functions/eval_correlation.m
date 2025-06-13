function [correlation] = eval_correlation(time_vector, splined_template, signal, weights, a_param, b_param)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

correlation = 1 - get_weighted_correlation(signal, fast_interpolation(time_vector, splined_template, a_param, b_param), weights);

end