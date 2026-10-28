%% Spectrum scan - which radio signals are around us? (receive only)
% Sweeps the ADALM-Pluto across 325 MHz - 3.8 GHz, measures the power
% spectrum at every step, finds the strong signals and matches them to
% known frequency bands in India. Nothing is transmitted.
%
% Note: the CNN is NOT used here. Real nearby signals (4G/5G, Wi-Fi,
% Bluetooth) use modulations such as OFDM that the CNN was never trained
% on, so they are identified by their frequency band instead.

clear; clc; close all;
cfg = plutoConfig();

fStart   = 325e6;        % Pluto (AD9363) lower limit
fStop    = 3800e6;       % Pluto upper limit
fs       = 20e6;         % capture bandwidth per step
useBW    = 16e6;         % keep the clean middle 16 MHz of each capture
nfft     = 1024;
nAvg     = 4;            % buffers averaged per step
rxGain   = 45;           % dB, fixed so levels are comparable across steps
minRise  = 10;           % dB above the noise floor to count as a signal

rx = sdrrx('Pluto', 'RadioID', cfg.radioID, 'CenterFrequency', fStart + useBW/2, ...
    'BasebandSampleRate', fs, 'SamplesPerFrame', nfft * 16, ...
    'OutputDataType', 'double', 'GainSource', 'Manual', 'Gain', rxGain);

centres = (fStart + useBW/2) : useBW : (fStop - useBW/2);
binHz   = fs / nfft;
keep    = abs(((-nfft/2):(nfft/2 - 1)) * binHz) <= useBW/2 & ...
          abs(((-nfft/2):(nfft/2 - 1)) * binHz) > 3 * binHz;   % drop DC spike
freqs = []; psd = [];
win = hann(nfft);

fprintf('Scanning %.0f MHz to %.0f MHz in %d steps...\n', fStart/1e6, fStop/1e6, numel(centres));
for k = 1:numel(centres)
    rx.CenterFrequency = centres(k);
    rx(); rx();                                   % let the LO settle
    p = zeros(nfft, 1);
    for a = 1:nAvg
        x = rx();
        segs = reshape(x(1:floor(numel(x)/nfft)*nfft), nfft, []);
        p = p + mean(abs(fftshift(fft(segs .* win, [], 1), 1)).^2, 2);
    end
    p = 10*log10(p / nAvg / sum(win.^2) + eps);
    f = centres(k) + ((-nfft/2):(nfft/2 - 1)).' * binHz;
    freqs = [freqs; f(keep)]; psd = [psd; p(keep)];   %#ok<AGROW>
end
release(rx);

%% find the signals
floorDb = median(psd);
above   = psd > floorDb + minRise;
edges   = diff([0; above; 0]);
startI  = find(edges == 1); stopI = find(edges == -1) - 1;
sig = struct('fLow', {}, 'fHigh', {}, 'peakHz', {}, 'peakDb', {}, 'band', {});
for s = 1:numel(startI)
    idx = startI(s):stopI(s);
    if (freqs(idx(end)) - freqs(idx(1))) < 50e3, continue; end   % ignore tiny spurs
    [pk, j] = max(psd(idx));
    sig(end+1) = struct('fLow', freqs(idx(1)), 'fHigh', freqs(idx(end)), ...
        'peakHz', freqs(idx(j)), 'peakDb', pk - floorDb, 'band', bandName(freqs(idx(j)))); %#ok<SAGROW>
end
% merge pieces of the same band that sit close together
if ~isempty(sig)
    m = sig(1);
    for s = 2:numel(sig)
        if sig(s).fLow - m(end).fHigh < 2e6 && strcmp(sig(s).band, m(end).band)
            m(end).fHigh = sig(s).fHigh;
            if sig(s).peakDb > m(end).peakDb, m(end).peakDb = sig(s).peakDb; m(end).peakHz = sig(s).peakHz; end
        else
            m(end+1) = sig(s); %#ok<AGROW>
        end
    end
    sig = m;
end

fprintf('\nNoise floor: %.1f dB. Signals at least %d dB above it:\n\n', floorDb, minRise);
fprintf('%-12s %-14s %-9s %s\n', 'Peak (MHz)', 'Width (MHz)', 'Above', 'Likely source');
[~, order] = sort([sig.peakDb], 'descend');
for s = order
    fprintf('%-12.1f %-14.2f %-9s %s\n', sig(s).peakHz/1e6, (sig(s).fHigh - sig(s).fLow)/1e6, ...
        sprintf('%.0f dB', sig(s).peakDb), sig(s).band);
end

%% plot
f = figure('Color', 'w', 'Position', [60 60 1400 520], 'Theme', 'light');
plot(freqs/1e6, psd - floorDb, 'Color', [0.23 0.36 0.69]); hold on; grid on;
yline(minRise, '--', 'detection threshold', 'Color', [0.5 0.5 0.5]);
for s = order(1:min(12, numel(order)))
    text(sig(s).peakHz/1e6, sig(s).peakDb + 2, sig(s).band, 'Rotation', 90, 'FontSize', 9, ...
        'Color', [0.09 0.11 0.30]);
end
xlabel('Frequency (MHz)'); ylabel('Power above noise floor (dB)');
title('Radio signals around us: ADALM-Pluto scan, 325 MHz - 3.8 GHz');
xlim([fStart fStop]/1e6);
outDir = fullfile(cfg.projectDir, 'results');
if ~isfolder(outDir), mkdir(outDir); end
exportgraphics(f, fullfile(outDir, '15_spectrum_scan_nearby_signals.png'), 'Resolution', 150);
save(fullfile(cfg.projectDir, 'data', 'spectrum_scan.mat'), 'freqs', 'psd', 'floorDb', 'sig');
fprintf('\nSaved the plot to Results_Photos and the data to spectrum_scan.mat\n');

function name = bandName(f)
% Common bands in India (downlink = what a phone receives from the tower)
mhz = f / 1e6;
bands = { ...
    433.05, 434.79, 'ISM 433 MHz (remotes, sensors)';
    470,    698,    'UHF TV broadcast';
    758,    803,    '4G LTE band 28 (700 MHz) downlink';
    865,    867,    'ISM 865-867 MHz (RFID, IoT)';
    869,    894,    '4G/2G band 5 (850 MHz) downlink';
    925,    960,    '2G/4G band 8 (900 MHz) downlink';
    1559,   1610,   'GNSS (GPS / NavIC L5 nearby)';
    1805,   1880,   '4G LTE band 3 (1800 MHz) downlink';
    1880,   1920,   'Band 39 / DECT region';
    2110,   2170,   '3G/4G band 1 (2100 MHz) downlink';
    2300,   2400,   '4G LTE band 40 (2300 MHz)';
    2400,   2483.5, 'Wi-Fi / Bluetooth 2.4 GHz';
    2496,   2690,   'Band 41 (2.5 GHz)';
    3300,   3800,   '5G NR n78 (3.5 GHz)'};
name = 'unknown / other';
for b = 1:size(bands, 1)
    if mhz >= bands{b, 1} && mhz <= bands{b, 2}, name = bands{b, 3}; return; end
end
end
