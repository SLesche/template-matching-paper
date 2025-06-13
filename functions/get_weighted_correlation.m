function [weighted_corr] = get_weighted_correlation(x, y, weights)
%UNTITLED14 Summary of this function goes here
%   Detailed explanation goes here
is_nan = isnan(x) | isnan(y) | isnan(weights);

weighted_mean = @(values, weights) sum(values.*weights) / sum(weights);

weighted_cov = @(x, y, weights) sum(weights.*(x - weighted_mean(x, weights)).*(y-weighted_mean(y, weights))) / sum(weights);

weighted_corr = weighted_cov(x(~is_nan), y(~is_nan), weights(~is_nan)) / sqrt(weighted_cov(x(~is_nan), x(~is_nan), weights(~is_nan)).*weighted_cov(y(~is_nan), y(~is_nan), weights(~is_nan)));
end