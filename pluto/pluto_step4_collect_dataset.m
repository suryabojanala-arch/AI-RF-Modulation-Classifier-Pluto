%% STEP 4 - Build a real over-the-air Pluto dataset
% For every modulation and several TX gains (= several SNRs) the Pluto
% transmits, receives, and stores labelled 2 x 128 I/Q frames, in the
% same format as RadioML. SNR is estimated from a noise-only capture.

clear; clc;
cfg = plutoConfig();

% TX gain steps relative to cfg.txGain (lower -> lower SNR). gainUsed
% stores these offsets, so steps 5 and 6 work for any antenna/cable setup.
txGains          = [0 -10 -20 -30 -40];
baseTxGain       = cfg.txGain;
framesPerSetting = 1000;

if ~isfile(cfg.refFile)
    error('Run pluto_step2_reference.m first.');
end
load(cfg.refFile, 'refRMS');

[tx, rx] = plutoRadios(cfg);

% noise floor with nothing transmitted
noisePow = NaN;
if ~cfg.simulate
    for k = 1:cfg.flushBuffers, rx(); end
    n = zeros(0,1);
    for k = 1:5, n = [n; rx()]; end %#ok<AGROW>
    noisePow = mean(abs(n - mean(n)).^2);
    fprintf('Noise power: %.2f dBFS\n', 10*log10(noisePow));
end

nSettings = numel(cfg.classes) * numel(txGains);
total     = nSettings * framesPerSetting;
XSeq      = cell(total, 1);
labels    = strings(total, 1);
snrEst    = zeros(total, 1);
gainUsed  = zeros(total, 1);
pos = 0; s = 0;

for m = 1:numel(cfg.classes)
    modType = cfg.classes{m};
    txWave  = genModWaveform(modType, cfg);
    for g = txGains
        s = s + 1;
        cfg.txGain   = baseTxGain + g;
        cfg.simSNRdB = 20 + g/2;          % used only in simulation
        startTransmit(tx, rx, cfg, txWave);

        got = 0; snrs = [];
        while got < framesPerSetting
            x = captureBuffer(rx, cfg, txWave);
            if cfg.simulate
                thisSNR = cfg.simSNRdB;
            else
                sigPow  = mean(abs(x - mean(x)).^2);
                thisSNR = 10*log10(max(sigPow - noisePow, eps) / noisePow);
            end
            seq  = frameAndNormalize(x, cfg, refRMS);
            take = min(numel(seq), framesPerSetting - got);
            idx  = pos + (1:take);
            XSeq(idx)     = seq(1:take);
            labels(idx)   = modType;
            snrEst(idx)   = thisSNR;
            gainUsed(idx) = g;
            pos = pos + take; got = got + take;
            snrs(end+1) = thisSNR; %#ok<AGROW>
        end
        fprintf('[%2d/%2d] %-6s  TX gain %4d dB (offset %3d)  ->  SNR ~ %5.1f dB  (%d frames)\n', ...
            s, nSettings, modType, cfg.txGain, g, median(snrs), got);
    end
end

if ~cfg.simulate
    release(tx); release(rx);
end

Y = categorical(labels, cfg.classes);
captureCfg = cfg;
save(cfg.captureFile, 'XSeq', 'Y', 'snrEst', 'gainUsed', 'captureCfg');
fprintf('\nSaved %d frames to %s\n', numel(XSeq), cfg.captureFile);
