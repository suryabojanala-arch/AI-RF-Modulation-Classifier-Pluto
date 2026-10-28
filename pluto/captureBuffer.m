function x = captureBuffer(rx, cfg, txWave)
% CAPTUREBUFFER  One buffer of received samples, from the Pluto or from
% the simulated channel. Warns on overflow (samples dropped by USB).

if cfg.simulate
    x = simChannel(txWave, cfg, cfg.samplesPerFrame);
    return;
end

[x, ~, overflow] = rx();
if overflow
    warning('Pluto RX overflow: samples were dropped. Lower cfg.fs or close other programs.');
end
end
