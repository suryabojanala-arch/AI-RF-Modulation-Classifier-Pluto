%% Figures for the final review slides (saved to ppt_assets/)
% Needs steps 2, 4, 6 and 7 to have been run, and the Pluto connected
% (for the test-tone spectrum).

cfg = plutoConfig();
outDir = fullfile(cfg.projectDir, 'results');
if ~isfolder(outDir), mkdir(outDir); end

load(cfg.captureFile, 'XSeq', 'Y', 'gainUsed');
navy = [0.09 0.11 0.30]; blue = [0.23 0.36 0.69]; orange = [0.95 0.55 0.15];
newFig = @(w, h) figure('Color','w','Position',[100 100 w h], 'Theme','light');

%% 1. Real received constellations, one per class (strongest TX setting)
f = newFig(1500, 330);
tiledlayout(1, numel(cfg.classes), 'TileSpacing','compact','Padding','compact');
for c = 1:numel(cfg.classes)
    k = cfg.classes{c};
    idx = find(Y == k & gainUsed == 0, 6);
    iq = [XSeq{idx}];
    nexttile;
    plot(iq(1,:), iq(2,:), '.', 'Color', blue, 'MarkerSize', 4);
    axis equal; axis square; grid on; box on;
    lim = 1.1*max(abs(iq(:)));
    xlim([-lim lim]); ylim([-lim lim]);
    set(gca, 'XTickLabel', [], 'YTickLabel', [], 'GridAlpha', 0.15);
    title(k, 'FontSize', 15, 'Color', navy, 'FontWeight', 'bold');
end
exportgraphics(f, fullfile(outDir, 'constellations.png'), 'Resolution', 200);
close(f);

%% 2. One received I/Q frame per class
f = newFig(1500, 300);
tiledlayout(1, numel(cfg.classes), 'TileSpacing','compact','Padding','compact');
for c = 1:numel(cfg.classes)
    k = cfg.classes{c};
    idx = find(Y == k & gainUsed == 0, 1);
    s = XSeq{idx};
    nexttile;
    plot(s(1,:), 'LineWidth', 1.3, 'Color', blue); hold on;
    plot(s(2,:), 'LineWidth', 1.3, 'Color', orange);
    grid on; box on; xlim([1 128]);
    set(gca, 'YTickLabel', [], 'GridAlpha', 0.15);
    title(k, 'FontSize', 15, 'Color', navy, 'FontWeight', 'bold');
    if c == 1, legend('I','Q','Location','southwest'); end
end
exportgraphics(f, fullfile(outDir, 'iq_frames.png'), 'Resolution', 200);
close(f);

%% 3-4. Confusion matrices from the independent fresh-capture test (step 7)
R = load(fullfile(cfg.projectDir, 'data', 'independent_test_results.mat'));
order = string(cfg.classes);
mk = @(p, ttl, fname) saveConf(categorical(R.Ytrue, order), categorical(p, order), ttl, ...
    fullfile(outDir, fname), blue, newFig);
mk(R.pB, sprintf('Fine-tuned CNN, fresh capture (%.1f%%)', mean(R.pB == R.Ytrue)*100), 'confusion_tuned.png');
mk(R.pA, sprintf('Original CNN, fresh capture (%.1f%%)',  mean(R.pA == R.Ytrue)*100), 'confusion_original.png');

%% 5. Test tone through the antennas
t = (0:9999).' / cfg.fs;
txWave = 0.7 * exp(1i*2*pi*100e3*t);
[tx, rx] = plutoRadios(cfg);
startTransmit(tx, rx, cfg, txWave);
x = captureBuffer(rx, cfg, txWave);
release(tx); release(rx);
N = numel(x); fr = (-N/2:N/2-1).' * cfg.fs / N;
P = 20*log10(abs(fftshift(fft(x .* hann(N)))) / N + eps);
f = newFig(1100, 420);
plot(fr/1e3, P, 'Color', blue); grid on; box on;
xlabel('Frequency offset (kHz)'); ylabel('Power (dBFS)');
title('100 kHz test tone received over the air (TX antenna \rightarrow RX antenna)', 'Color', navy);
set(gca, 'FontSize', 13, 'GridAlpha', 0.15);
exportgraphics(f, fullfile(outDir, 'loopback_tone.png'), 'Resolution', 200);
close(f);

fprintf('Figures saved to %s\n', outDir);

function saveConf(yt, yp, ttl, fname, blue, newFig)
f = newFig(760, 640);
cc = confusionchart(yt, yp, 'RowSummary', 'row-normalized');
cc.Title = ttl;
cc.FontSize = 13;
cc.DiagonalColor = blue; cc.OffDiagonalColor = [0.85 0.33 0.25];
exportgraphics(f, fname, 'Resolution', 200);
close(f);
end
