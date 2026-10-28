function [tr, va, te] = splitTVT(groups, fractions, seed)
% SPLITTVT  Stratified train / validation / test split.
%   [tr, va, te] = splitTVT(groups, [0.70 0.15 0.15], seed) returns three
%   logical vectors with no overlap. Every group (e.g. every modulation,
%   or every modulation x power level) is split with the same fractions,
%   so all three sets contain every class in the same proportion.

groups = categorical(groups(:));
n  = numel(groups);
tr = false(n, 1); va = false(n, 1); te = false(n, 1);
rng(seed);
for g = categories(groups)'
    idx = find(groups == g{1});
    idx = idx(randperm(numel(idx)));
    nTr = round(fractions(1) * numel(idx));
    nVa = round(fractions(2) * numel(idx));
    tr(idx(1:nTr)) = true;
    va(idx(nTr+1:nTr+nVa)) = true;
    te(idx(nTr+nVa+1:end)) = true;
end
end
