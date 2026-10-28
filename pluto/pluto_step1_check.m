%% STEP 1 - ADALM-Pluto connection and loopback check
% Setup: one antenna on TX1 and one on RX1, about 2 cm apart (over the air).
% (With an SMA cable instead, add a 30 dB attenuator and retune the gains.)
% Transmits a 100 kHz tone and checks it comes back at the right
% frequency with a healthy level.

clear; clc; close all;
cfg = plutoConfig();

if ~cfg.simulate
    radios = findPlutoRadio;
    if isempty(radios)
        error(['No ADALM-Pluto found. Check the USB cable, install the ' ...
               '"Communications Toolbox Support Package for ADALM-PLUTO Radio", ' ...
               'and run configurePlutoRadio if this is the first use.']);
    end
    fprintf('Found Pluto: RadioID = %s, Serial = %s\n', ...
        radios(1).RadioID, radios(1).SerialNum);
    cfg.radioID = radios(1).RadioID;
end

toneHz = 100e3;
t = (0:cfg.fs/1000*10-1).' / cfg.fs;       % 10 ms, whole number of cycles
txWave = 0.7 * exp(1i*2*pi*toneHz*t);

[tx, rx] = plutoRadios(cfg);
startTransmit(tx, rx, cfg, txWave);
x = captureBuffer(rx, cfg, txWave);

N = numel(x);
f = (-N/2:N/2-1).' * cfg.fs / N;
P = 20*log10(abs(fftshift(fft(x .* hann(N)))) / N + eps);
[peakDB, k] = max(P);
peakHz = f(k);

fprintf('\nTone sent at   : %.1f kHz\n', toneHz/1e3);
fprintf('Peak received  : %.1f kHz (%.1f dBFS)\n', peakHz/1e3, peakDB);
fprintf('RX RMS level   : %.3f (full scale = 1)\n', rms(x));
if abs(peakHz - toneHz) < 2e3
    fprintf('Result         : LOOPBACK OK\n');
else
    fprintf('Result         : CHECK WIRING / GAINS\n');
end
if max(abs([real(x); imag(x)])) > 0.95
    warning('RX is clipping. Lower cfg.txGain or cfg.rxGain, or add attenuation.');
end

figure('Name','Pluto loopback check','Color','w');
subplot(2,1,1);
plot(f/1e3, P); grid on;
xlabel('Frequency (kHz)'); ylabel('dBFS'); title('Received spectrum');
subplot(2,1,2);
plot(real(x(1:200))); hold on; plot(imag(x(1:200))); grid on;
legend('I','Q'); title('Received I/Q (first 200 samples)');

if ~cfg.simulate
    release(tx); release(rx);
end
