%% STEP 6 - Fine-tune the CNN on real Pluto data (transfer learning)
% Starts from the RadioML CNN (cfg.modelFile) and fine-tunes it on real
% Pluto frames with a proper 70 / 15 / 15 split:
%   training   - Pluto training frames + 5,000 RadioML TRAINING frames
%                (the RadioML frames stop the network forgetting the dataset)
%   validation - Pluto validation frames, checked during training to pick
%                the best epoch and stop early
%   testing    - Pluto test frames, used only once after training
% The split is stratified by modulation AND power level, so every set has
% every class at every SNR.

clear; clc; close all;
cfg = plutoConfig();
frac = [0.70 0.15 0.15];

% Train/validate only on settings where the signal is clearly above the
% noise (like the SNR >= 10 dB selection on RadioML). Testing reports both.
minTrainGain = -20;

S = load(cfg.modelFile, 'net1D', 'classes5');
classes5 = S.classes5;
load(cfg.captureFile, 'XSeq', 'Y', 'gainUsed');
load(cfg.refFile, 'rmlTrainSeq', 'rmlTrainY', 'rmlTestSeq', 'rmlTestY');

[plutoTrainIdx, plutoValIdx, plutoTestIdx] = splitTVT(string(Y) + "_" + string(gainUsed), frac, 2);
strong = gainUsed >= minTrainGain;

trainSel = plutoTrainIdx & strong;
valSel   = plutoValIdx & strong;
testSel  = plutoTestIdx & strong;
fprintf('Pluto frames: %d  ->  training %d, validation %d, testing %d (all power levels)\n', ...
    numel(Y), sum(plutoTrainIdx), sum(plutoValIdx), sum(plutoTestIdx));
fprintf('Used (TX gain >= %d dB): training %d + %d RadioML, validation %d, testing %d\n', ...
    minTrainGain, sum(trainSel), numel(rmlTrainSeq), sum(valSel), sum(testSel));

XTrain = [XSeq(trainSel); rmlTrainSeq];
YTrain = [Y(trainSel);    rmlTrainY];

layers = S.net1D.Layers;
layers(end) = classificationLayer('Name', layers(end).Name);

if usejava('desktop'), plotMode = 'training-progress'; else, plotMode = 'none'; end
opts = trainingOptions('adam', ...
    'MaxEpochs',           30, ...
    'MiniBatchSize',       128, ...
    'InitialLearnRate',    5e-4, ...     % chosen over 1e-4 by validation accuracy
    'Shuffle',             'every-epoch', ...
    'ValidationData',      {XSeq(valSel), Y(valSel)}, ...
    'ValidationFrequency', 50, ...
    'ValidationPatience',  10, ...
    'OutputNetwork',       'best-validation-loss', ...
    'Verbose',             true, ...
    'VerboseFrequency',    100, ...
    'Plots',               plotMode);

net1D = trainNetwork(XTrain, YTrain, layers, opts);

acc = @(X, Yt) mean(classify(net1D, X, 'MiniBatchSize', 512) == Yt) * 100;
accTrain   = acc(XSeq(trainSel), Y(trainSel));
accVal     = acc(XSeq(valSel),   Y(valSel));
accTest    = acc(XSeq(testSel),  Y(testSel));
accTestAll = acc(XSeq(plutoTestIdx), Y(plutoTestIdx));
accRML     = acc(rmlTestSeq, rmlTestY);

fprintf('\n===== Fine-tuned CNN on Pluto data (70/15/15) =====\n');
fprintf('Training accuracy        : %6.2f%%\n', accTrain);
fprintf('Validation accuracy      : %6.2f%%\n', accVal);
fprintf('Test accuracy            : %6.2f%%   <- reported result (TX gain >= %d dB)\n', accTest, minTrainGain);
fprintf('Test accuracy, all SNRs  : %6.2f%%\n', accTestAll);
fprintf('RadioML test accuracy    : %6.2f%%   (dataset not forgotten)\n', accRML);

plutoSplit = struct('fractions', frac, 'minTrainGain', minTrainGain, ...
    'nTrain', sum(trainSel), 'nVal', sum(valSel), 'nTest', sum(testSel), ...
    'accTrain', accTrain, 'accVal', accVal, 'accTest', accTest, 'accTestAll', accTestAll, 'accRML', accRML);
save(cfg.tunedFile, 'net1D', 'classes5', 'plutoTrainIdx', 'plutoValIdx', 'plutoTestIdx', 'plutoSplit');
fprintf('Saved %s\n', cfg.tunedFile);
