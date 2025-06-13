function [transformed_signal] = interpolate_transformed_template(time_vector, template, a_param, b_param)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% Using splines
% initialize with NaN to prevent extrapolatiton to values outside of known
% range
transformed_signal = NaN(length(time_vector), 1);
transformed_signal(time_vector.*b_param <= max(time_vector) & time_vector.*b_param >= min(time_vector)) = a_param.*spline(time_vector(~isnan(template)), template(~isnan(template)), time_vector(time_vector.*b_param <= max(time_vector) & time_vector.*b_param >= min(time_vector)).*b_param);

% using linear interpolation
%transformed_signal = a_param.*interp1(time_vector, template, time_vector.*b_param);

end