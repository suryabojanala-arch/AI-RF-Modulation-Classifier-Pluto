%% STEP 7 - Independent hardware test (fresh capture, never used in training)
% Transmits NEW random data for every modulation (genModWaveform draws new
% bits each call), captures it over the air and classifies it with both
% CNNs. Because the frames come from a separate capture session, this is
% the fair real-world accuracy, free of any overlap with step 4's data.

clear; clc;
cfg = plutoConfig();
txOffsets      = [0 -10 -20];        % signal-present settings (as step 6)
framesPerClass = 640;                % per offset (10 buffers of 64)

load(cfg.refFile, 'refRMS');
A = load(cfg.modelFile, 'net1D');    % original (RadioML only)
B = load(cfg.tunedFile, 'net1D');    % fine-tuned on Pluto data
baseTxGain = cfg.txGain;

[tx, rx] = plutoRadios(cfg);
Ytrue = strings(0,1); pA = strings(0,1); pB = strings(0,1); off = zeros(0,1); XFresh = {};
for m = 1:numel(cfg.classes)
    modType = cfg.classes{m};
    txWave  = genModWaveform(modType, cfg);          % fresh random data
    for g = txOffsets
        cfg.txGain = baseTxGain + g;
        startTransmit(tx, rx, cfg, txWave);
        seq = {};
        while numel(seq) < framesPerClass
            seq = [seq; frameAndNormalize(captureBuffer(rx, cfg, txWave), cfg, refRMS)]; %#ok<AGROW>
        end
        seq = seq(1:framesPerClass);
        XFresh = [XFresh; seq]; %#ok<AGROW>
        Ytrue = [Ytrue; repmat(string(modType), framesPerClass, 1)]; %#ok<AGROW>
        pA    = [pA; string(classify(A.net1D, seq, 'MiniBatchSize', 512))]; %#ok<AGROW>
        pB    = [pB; string(classify(B.net1D, seq, 'MiniBatchSize', 512))]; %#ok<AGROW>
        off   = [off; repmat(g, framesPerClass, 1)]; %#ok<AGROW>
    end
end
if ~cfg.simulate, release(tx); release(rx); end

fprintf('\n====== INDEPENDENT HARDWARE TEST (fresh capture) ======\n');
fprintf('Frames: %d (%d per modulation)\n', numel(Ytrue), numel(Ytrue)/numel(cfg.classes));
fprintf('Original CNN   : %6.2f%%\n', mean(pA == Ytrue)*100);
fprintf('Fine-tuned CNN : %6.2f%%\n', mean(pB == Ytrue)*100);
fprintf('\n%-8s %12s %12s\n', 'Class', 'Original', 'Fine-tuned');
for m = 1:numel(cfg.classes)
    k = cfg.classes{m}; s = Ytrue == k;
    fprintf('%-8s %11.1f%% %11.1f%%\n', k, mean(pA(s) == k)*100, mean(pB(s) == k)*100);
end
fprintf('\n%-10s %12s %12s\n', 'TX offset', 'Original', 'Fine-tuned');
for g = txOffsets
    s = off == g;
    fprintf('%7d dB %11.1f%% %11.1f%%\n', g, mean(pA(s) == Ytrue(s))*100, mean(pB(s) == Ytrue(s))*100);
end

save(fullfile(cfg.projectDir, 'data', 'independent_test_results.mat'), 'Ytrue', 'pA', 'pB', 'off', 'XFresh');
