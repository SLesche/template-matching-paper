function [start_mat] = get_start_point_matrix(possible_as, possible_bs)
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here
[n,m] = ndgrid(possible_as, possible_bs);
start_mat = [m(:),n(:)];
end