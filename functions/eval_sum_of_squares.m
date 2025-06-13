function [sum_of_squares] = eval_sum_of_squares(time_vector, splined_template, signal, weights, a_param, b_param)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

sum_of_squares = sum(weights.*(signal - fast_interpolation(time_vector, splined_template, a_param, b_param)).^2, "omitnan");
end