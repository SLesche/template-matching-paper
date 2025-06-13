function [norm_signal] = normalize_signal(signal)
%UNTITLED19 Summary of this function goes here
%   Detailed explanation goes here
norm_signal = 2*(signal + max(signal)) / (2*max(signal)) - 1;
end