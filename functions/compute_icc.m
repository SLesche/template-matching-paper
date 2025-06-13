function [icc] = compute_icc(M)
    [n, k] = size(M);

    SStotal = var(M(:)) *(n*k - 1);
    MSR = var(mean(M, 2)) * k;
    MSC = var(mean(M, 1)) * n;
    MSE = (SStotal - MSR *(n - 1) - MSC * (k -1))/ ((n - 1) * (k - 1));

    icc = (MSR - MSE) / (MSR + (k-1)*MSE + k*(MSC-MSE)/n);
end