function y = genModWaveform(modType, cfg)
% GENMODWAVEFORM  Baseband waveform for one of the 5 project classes,
% generated the same way as RadioML 2016.10a (8 samples/symbol, RRC
% shaping for digital, real audio for analog). Output is a complex
% column vector scaled to a 0.7 peak, ready for transmitRepeat.

switch modType
    case {'BPSK','QPSK','QAM16'}
        switch modType
            case 'BPSK',  M = 2;
            case 'QPSK',  M = 4;
            case 'QAM16', M = 16;
        end
        data = randi([0 M-1], cfg.nSymbols, 1);
        if M == 2
            sym = pskmod(data, 2);
        elseif M == 4
            sym = pskmod(data, 4, pi/4);
        else
            sym = qammod(data, 16, 'UnitAveragePower', true);
        end
        txFilt = comm.RaisedCosineTransmitFilter( ...
            'RolloffFactor', cfg.rolloff, ...
            'FilterSpanInSymbols', cfg.rrcSpan, ...
            'OutputSamplesPerSymbol', cfg.sps);
        y = txFilt(sym);

    case {'AM-DSB','WBFM'}
        m = audioMessage(cfg);
        if strcmp(modType, 'AM-DSB')
            % double sideband with carrier
            y = complex(1 + cfg.amIndex*m);
        else
            phase = 2*pi*cfg.fmDev*cumsum(m)/cfg.fs;
            y = exp(1i*phase);
        end

    otherwise
        error('Unknown modulation: %s', modType);
end

% complex() again: MATLAB drops an all-zero imaginary part (AM-DSB) after
% arithmetic, and the Pluto only accepts complex input
y = complex(0.7 * y / max(abs(y)));
end

function m = audioMessage(cfg)
% Music clip shipped with MATLAB, resampled to the radio sample rate
% and normalised to [-1, 1].
s = load('handel.mat');          % gives y, Fs = 8192
nIn = round(cfg.audioSec * s.Fs);
a = s.y(1:nIn);
m = resample(a, round(cfg.fs), s.Fs);
m = m - mean(m);
m = m / max(abs(m));
end
