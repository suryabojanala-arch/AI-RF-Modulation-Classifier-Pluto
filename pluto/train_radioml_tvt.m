%% Train the CNN on RadioML with separate TRAINING / VALIDATION / TEST sets
% Same data selection and network as AI_Training.m (mid review), but with
% a proper 70 / 15 / 15 split:
%   training   - the network learns from these frames
%   validation - checked during training; picks the best epoch and stops
%                training early when validation loss stops improving
%   testing    - used only once, after training, for the reported accuracy
% Saves the model to cfg.modelFile and the RadioML subsets used later by
% steps 5 and 6 into cfg.refFile (refRMS is kept).

clear; clc; close all;
cfg = plutoConfig();
frac = [0.70 0.15 0.15];

load(cfg.datasetFile, 'X', 'modulation', 'snr');
modulation = strtrim(cellstr(string(modulation(:))));
snr = double(snr(:));
keep = ismember(modulation, cfg.classes) & snr >= 10;
X = X(keep,:,:);
Y = categorical(modulation(keep), cfg.classes);
seq = arrayfun(@(i) single(squeeze(X(i,:,:))), (1:size(X,1))', 'UniformOutput', false);

[tr, va, te] = splitTVT(Y, frac, 1);
fprintf('RadioML frames: %d  ->  training %d, validation %d, testing %d\n', ...
    numel(Y), sum(tr), sum(va), sum(te));

layers = [
    sequenceInputLayer(2)
    convolution1dLayer(5, 32, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    convolution1dLayer(5, 64, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    globalAveragePooling1dLayer
    fullyConnectedLayer(numel(cfg.classes))
    softmaxLayer
    classificationLayer];

if usejava('desktop'), plotMode = 'training-progress'; else, plotMode = 'none'; end
opts = trainingOptions('adam', ...
    'MaxEpochs',          30, ...
    'MiniBatchSize',      128, ...
    'InitialLearnRate',   1e-3, ...
    'Shuffle',            'every-epoch', ...
    'ValidationData',     {seq(va), Y(va)}, ...
    'ValidationFrequency', 50, ...
    'ValidationPatience', 6, ...
    'OutputNetwork',      'best-validation-loss', ...
    'Verbose',            true, ...
    'VerboseFrequency',   100, ...
    'Plots',              plotMode);

net1D = trainNetwork(seq(tr), Y(tr), layers, opts);

acc = @(sel) mean(classify(net1D, seq(sel), 'MiniBatchSize', 512) == Y(sel)) * 100;
accTrain = acc(tr); accVal = acc(va); accTest = acc(te);
fprintf('\n===== RadioML CNN (70/15/15) =====\n');
fprintf('Training accuracy   : %6.2f%%\n', accTrain);
fprintf('Validation accuracy : %6.2f%%\n', accVal);
fprintf('Test accuracy       : %6.2f%%   <- reported result\n', accTest);

classes5 = cfg.classes;
radiomlSplit = struct('fractions', frac, 'nTrain', sum(tr), 'nVal', sum(va), 'nTest', sum(te), ...
    'accTrain', accTrain, 'accVal', accVal, 'accTest', accTest);
save(cfg.modelFile, 'net1D', 'classes5', 'radiomlSplit');

% RadioML subsets for steps 5 and 6 (the mixing frames come from TRAINING only)
trIdx = find(tr);
rng(3); pick = trIdx(randperm(numel(trIdx), min(5000, numel(trIdx))));
rmlTrainSeq = seq(pick);  rmlTrainY = Y(pick);
rmlValSeq   = seq(va);    rmlValY   = Y(va);
rmlTestSeq  = seq(te);    rmlTestY  = Y(te);
save(cfg.refFile, 'rmlTrainSeq', 'rmlTrainY', 'rmlValSeq', 'rmlValY', 'rmlTestSeq', 'rmlTestY', '-append');
fprintf('Saved %s and updated %s\n', cfg.modelFile, cfg.refFile);
