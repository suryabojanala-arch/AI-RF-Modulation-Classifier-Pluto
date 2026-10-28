%% STEP 5 - Dataset vs real-time performance comparison
% Compares the CNN on the RadioML test split against real Pluto frames:
% overall accuracy, per-class accuracy, accuracy vs TX gain and
% confusion matrices. If step 6 has been run, the fine-tuned model is
% compared too on the held-out Pluto frames.
%
% "Signal present" = TX gain >= minGain. Weaker settings are below the
% noise floor (pure noise), just as AI_Training.m only used SNR >= 10 dB.

clear; clc; close all;
cfg = plutoConfig();
minGain = -20;

S = load(cfg.modelFile, 'net1D');
netBase = S.net1D;
load(cfg.refFile, 'rmlTestSeq', 'rmlTestY');
load(cfg.captureFile, 'XSeq', 'Y', 'snrEst', 'gainUsed');

haveTuned = isfile(cfg.tunedFile);
if haveTuned
    T = load(cfg.tunedFile, 'net1D', 'plutoTestIdx');
    netTuned = T.net1D;
    evalIdx  = T.plutoTestIdx;          % frames the tuned net never saw
else
    evalIdx  = true(numel(Y), 1);
end
Xp = XSeq(evalIdx); Yp = Y(evalIdx);
snrP = snrEst(evalIdx); gainP = gainUsed(evalIdx);
sig  = gainP >= minGain;

predRML  = classify(netBase, rmlTestSeq, 'MiniBatchSize', 512);
predBase = classify(netBase, Xp, 'MiniBatchSize', 512);
accRML   = mean(predRML == rmlTestY) * 100;
acc = @(p, sel) mean(p(sel) == Yp(sel)) * 100;
if haveTuned
    predTuned = classify(netTuned, Xp, 'MiniBatchSize', 512);
end

%% Summary table
fprintf('\n================ PERFORMANCE COMPARISON ================\n');
fprintf('%-34s %10s %10s\n', '', 'signal', 'all');
fprintf('%-34s %10s %10s\n', '', 'present', 'frames');
fprintf('%-34s %9.2f%% %10s\n', 'RadioML test split (dataset)', accRML, '-');
fprintf('%-34s %9.2f%% %9.2f%%\n', 'ADALM-Pluto real (original CNN)', acc(predBase, sig), acc(predBase, true(size(Yp))));
if haveTuned
    fprintf('%-34s %9.2f%% %9.2f%%\n', 'ADALM-Pluto real (fine-tuned CNN)', acc(predTuned, sig), acc(predTuned, true(size(Yp))));
end
fprintf('(signal present = TX gain >= %d dB)\n', minGain);
fprintf('========================================================\n\n');

classes = categories(Y);
fprintf('Per-class accuracy, signal present:\n');
fprintf('%-8s %10s %12s', 'Class', 'RadioML', 'Pluto-orig');
if haveTuned, fprintf(' %12s', 'Pluto-tuned'); end
fprintf('\n');
for c = 1:numel(classes)
    k = classes{c};
    selK = sig & Yp == k;
    fprintf('%-8s %9.1f%% %11.1f%%', k, ...
        mean(predRML(rmlTestY==k) == k)*100, mean(predBase(selK) == k)*100);
    if haveTuned, fprintf(' %11.1f%%', mean(predTuned(selK) == k)*100); end
    fprintf('\n');
end

%% Accuracy vs TX gain
gains = sort(unique(gainP));
accPts = zeros(size(gains)); accPtsT = accPts; snrPts = accPts;
fprintf('\n%-10s %12s %12s', 'TX offset', 'est. SNR', 'Pluto-orig');
if haveTuned, fprintf(' %12s', 'Pluto-tuned'); end
fprintf('\n');
for i = 1:numel(gains)
    sel = gainP == gains(i);
    snrPts(i) = median(snrP(sel));
    accPts(i) = acc(predBase, sel);
    fprintf('%7d dB %9.1f dB %11.1f%%', gains(i), snrPts(i), accPts(i));
    if haveTuned
        accPtsT(i) = acc(predTuned, sel);
        fprintf(' %11.1f%%', accPtsT(i));
    end
    fprintf('\n');
end

%% Figures
figure('Name','Dataset vs ADALM-Pluto','Color','w','Position',[60 60 1500 750]);
tiledlayout(1, 3 + haveTuned, 'TileSpacing', 'compact');
nexttile;
cc = confusionchart(rmlTestY, predRML, 'RowSummary','row-normalized');
cc.Title = sprintf('RadioML dataset (%.1f%%)', accRML);
nexttile;
cc = confusionchart(Yp(sig), predBase(sig), 'RowSummary','row-normalized');
cc.Title = sprintf('Pluto real - original (%.1f%%)', acc(predBase, sig));
if haveTuned
    nexttile;
    cc = confusionchart(Yp(sig), predTuned(sig), 'RowSummary','row-normalized');
    cc.Title = sprintf('Pluto real - fine-tuned (%.1f%%)', acc(predTuned, sig));
end
nexttile;
plot(gains, accPts, '-o', 'LineWidth', 1.5); hold on;
if haveTuned, plot(gains, accPtsT, '-s', 'LineWidth', 1.5); end
yline(accRML, '--', 'RadioML');
yline(20, ':', 'chance');
xline(minGain - 5, ':', 'below noise  |  signal present', 'LabelHorizontalAlignment', 'center');
grid on; ylim([0 100]);
xlabel(sprintf('TX gain offset from %d dB (dB)', cfg.txGain)); ylabel('Accuracy (%)');
title('Pluto accuracy vs TX power');
if haveTuned, legend('Original','Fine-tuned','Location','southeast');
else, legend('Original','Location','southeast'); end
