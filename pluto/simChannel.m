function y = simChannel(x, cfg, nSamp)
% SIMCHANNEL  Stand-in for the Pluto when cfg.simulate = true.
% Takes a random nSamp-long slice of the repeating TX waveform and adds
% a random phase, a small carrier frequency offset and AWGN.

x = x(:);
start = randi(numel(x));
idx = mod(start + (0:nSamp-1) - 1, numel(x)) + 1;
y = x(idx);

t = (0:nSamp-1).' / cfg.fs;
cfo = cfg.simCFOHz * (2*rand - 1);
y = y .* exp(1i*(2*pi*cfo*t + 2*pi*rand));
y = awgn(y, cfg.simSNRdB, 'measured');
end
