

clear; clc; close all;
cfg = plutoConfig();
txMod = 'QPSK';                     

if ~isfile(cfg.liveModelFile)
    error('%s not found. Run pluto_step6_finetune.m, or set cfg.liveModelFile = cfg.modelFile.', cfg.liveModelFile);
end
S = load(cfg.liveModelFile, 'net1D');
net = S.net1D;
fprintf('Live model: %s\n', cfg.liveModelFile);
classNames = string(net.Layers(end).Classes);
if ~isfile(cfg.refFile)
    error('Run pluto_step2_reference.m first.');
end
load(cfg.refFile, 'refRMS');

txWave = genModWaveform(txMod, cfg);
[tx, rx] = plutoRadios(cfg);
startTransmit(tx, rx, cfg, txWave);

%% Dashboard
bg = [0.07 0.08 0.11]; fg = [0.92 0.92 0.95];
fig = figure('Name','AI-Powered RF Digital Twin - ADALM-Pluto LIVE', ...
    'Color', bg, 'Position', [80 80 1280 740], 'UserData', '');
fig.KeyPressFcn = @(f, e) set(f, 'UserData', e.Character);
sgtitle('AI-POWERED RF DIGITAL TWIN  |  ADALM-PLUTO LIVE', ...
    'Color', fg, 'FontSize', 18, 'FontWeight', 'bold');

styleAx = @(ax) set(ax, 'Color', bg, 'XColor', fg, 'YColor', fg, ...
    'GridColor', [0.5 0.5 0.6]);

axIQ = subplot(2,3,1); styleAx(axIQ); hold(axIQ,'on'); grid(axIQ,'on');
hI = plot(axIQ, nan(1,cfg.frameLen), 'LineWidth', 1.2);
hQ = plot(axIQ, nan(1,cfg.frameLen), 'LineWidth', 1.2);
title(axIQ, 'Received I/Q (one 128-sample frame)', 'Color', fg);
xlabel(axIQ, 'Sample'); legend(axIQ, 'I', 'Q', 'TextColor', fg, 'Color', bg);

nfft = 256;
fAx = (-nfft/2:nfft/2-1) * cfg.fs / nfft / 1e3;
axPSD = subplot(2,3,2); styleAx(axPSD); grid(axPSD,'on');
hPSD = plot(axPSD, fAx, nan(size(fAx)), 'LineWidth', 1.2);
title(axPSD, 'RF Power Spectrum', 'Color', fg);
xlabel(axPSD, 'Frequency offset (kHz)'); ylabel(axPSD, 'dB');

axCon = subplot(2,3,3); styleAx(axCon); grid(axCon,'on');
hCon = plot(axCon, nan, nan, '.', 'MarkerSize', 4);
axis(axCon, 'equal'); title(axCon, 'Constellation', 'Color', fg);
xlabel(axCon, 'I'); ylabel(axCon, 'Q');

axBar = subplot(2,3,4); styleAx(axBar);
hBar = bar(axBar, categorical(classNames, classNames), zeros(1,numel(classNames)));
ylim(axBar, [0 1]); title(axBar, 'CNN confidence (buffer average)', 'Color', fg);

axHist = subplot(2,3,5); styleAx(axHist); grid(axHist,'on');
histLen = 100;
hHist = plot(axHist, nan(1,histLen), 'LineWidth', 1.5);
ylim(axHist, [0 100]); title(axHist, 'Frame accuracy per buffer (%)', 'Color', fg);
xlabel(axHist, 'Buffer');

axTxt = subplot(2,3,6); axis(axTxt, 'off');
txtTx   = text(axTxt, 0, 0.85, '', 'Color', fg, 'FontSize', 14);
txtPred = text(axTxt, 0, 0.65, '', 'Color', fg, 'FontSize', 16, 'FontWeight', 'bold');
txtStat = text(axTxt, 0, 0.45, '', 'FontSize', 16, 'FontWeight', 'bold');
txtAcc  = text(axTxt, 0, 0.25, '', 'Color', fg, 'FontSize', 13);
text(axTxt, 0, 0.05, 'Keys: 1 AM-DSB  2 BPSK  3 QAM16  4 QPSK  5 WBFM  q quit', ...
    'Color', [0.6 0.6 0.7], 'FontSize', 10);

%% Live loop
accHist = nan(1, histLen);
nCorrect = 0; nTotal = 0;
while isvalid(fig)
    key = fig.UserData;
    if ~isempty(key)
        fig.UserData = '';
        if key == 'q', break; end
        k = str2double(key);
        if ~isnan(k) && k >= 1 && k <= numel(cfg.classes)
            txMod = cfg.classes{k};
            txWave = genModWaveform(txMod, cfg);
            startTransmit(tx, rx, cfg, txWave);
            accHist(:) = nan; nCorrect = 0; nTotal = 0;
        end
    end

    x = captureBuffer(rx, cfg, txWave);
    seq = frameAndNormalize(x, cfg, refRMS);
    [pred, scores] = classify(net, seq, 'MiniBatchSize', numel(seq));

    meanScores = mean(scores, 1);
    [conf, ix] = max(meanScores);
    finalPred = classNames(ix);
    frameAcc = mean(string(pred) == txMod) * 100;
    nCorrect = nCorrect + sum(string(pred) == txMod);
    nTotal   = nTotal + numel(pred);
    accHist  = [accHist(2:end) frameAcc];

    % plots
    f1 = seq{1};
    set(hI, 'YData', f1(1,:)); set(hQ, 'YData', f1(2,:));
    xc = x - mean(x);
    segs = reshape(xc(1:floor(numel(xc)/nfft)*nfft), nfft, []);
    psd = 10*log10(mean(abs(fftshift(fft(segs .* hann(nfft), [], 1), 1)).^2, 2) + eps);
    set(hPSD, 'YData', psd);
    allIQ = [seq{:}];
    set(hCon, 'XData', allIQ(1,:), 'YData', allIQ(2,:));
    hBar.YData = meanScores;
    set(hHist, 'YData', accHist);

    ok = finalPred == txMod;
    txtTx.String   = sprintf('Transmitted : %s', txMod);
    txtPred.String = sprintf('AI Predicted: %s  (%.0f%%)', finalPred, conf*100);
    if ok
        txtStat.String = 'STATUS: CORRECT';   txtStat.Color = [0.3 0.9 0.4];
    else
        txtStat.String = 'STATUS: MISMATCH';  txtStat.Color = [1.0 0.4 0.4];
    end
    txtAcc.String = sprintf('Frame accuracy: %.1f%% now, %.1f%% since start', ...
        frameAcc, 100*nCorrect/max(nTotal,1));

    drawnow limitrate;
end

if ~cfg.simulate
    release(tx); release(rx);
end
if isvalid(fig), close(fig); end
fprintf('Stopped. Overall frame accuracy for %s: %.1f%%\n', txMod, 100*nCorrect/max(nTotal,1));
