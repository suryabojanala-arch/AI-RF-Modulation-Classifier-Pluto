%% STEP 2 - Reference data from RadioML (run once, no hardware needed)
% Saves pluto_ref.mat with:
%   refRMS          average RMS of the training frames (used to scale
%                   Pluto frames to the amplitude the CNN expects)
%   rmlTestSeq/Y    the same 20 % RadioML test split as AI_Training.m
%   rmlTrainSeq/Y   5000 RadioML training frames (mixed in at step 6)

clear; clc;
cfg = plutoConfig();

load(cfg.datasetFile, 'X', 'modulation', 'snr');
modulation = strtrim(cellstr(string(modulation(:))));
snr = double(snr(:));

% identical selection and split to AI_Training.m
mask  = ismember(modulation, cfg.classes);
X5    = X(mask,:,:);
Y5    = modulation(mask);
snr5  = snr(mask);
good  = snr5 >= 10;
Xgood = X5(good,:,:);
Ygood = Y5(good);

I = squeeze(Xgood(:,1,:));
Q = squeeze(Xgood(:,2,:));
frameRMS = sqrt(mean(I.^2 + Q.^2, 2));
refRMS = double(mean(frameRMS));
fprintf('RadioML frames used : %d\n', size(Xgood,1));
fprintf('Reference RMS       : %.5f\n', refRMS);

rng(1);
N = size(Xgood,1);
order = randperm(N);
nTrain = round(0.8*N);
trainIdx = order(1:nTrain);
testIdx  = order(nTrain+1:end);

toSeq = @(idx) arrayfun(@(i) single(squeeze(Xgood(i,:,:))), idx(:), ...
    'UniformOutput', false);

rmlTestSeq = toSeq(testIdx);
rmlTestY   = categorical(Ygood(testIdx), cfg.classes);

pick = trainIdx(randperm(numel(trainIdx), min(5000, numel(trainIdx))));
rmlTrainSeq = toSeq(pick);
rmlTrainY   = categorical(Ygood(pick), cfg.classes);

save(cfg.refFile, 'refRMS', 'rmlTestSeq', 'rmlTestY', 'rmlTrainSeq', 'rmlTrainY');
fprintf('Saved %s\n', cfg.refFile);
