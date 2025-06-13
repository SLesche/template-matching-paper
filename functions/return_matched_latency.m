function [matched_latency] = return_matched_latency(b_param, ga_latency)
%RETURN MATCHED LATENCY - Return an ERP latency on subject level
%   This function takes the fit of the individual-level erp (erp_fit) and
%   that bins grand_average and computes the individual subjects
%   component-latency by applying the strech parameter to the grand
%   average latency

matched_latency = ga_latency * b_param;

end