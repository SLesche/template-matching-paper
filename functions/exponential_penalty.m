function [penalty] = exponential_penalty(~, b)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% no penalty for a for now
if b < 1
    b = 1/b;
end

if b < 1.5
    b = 1;
end

penalty = exp(b);

end