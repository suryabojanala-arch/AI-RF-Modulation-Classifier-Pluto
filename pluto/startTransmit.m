function startTransmit(tx, rx, cfg, txWave)
% STARTTRANSMIT  Begin continuously repeating txWave on the Pluto TX
% port (replacing whatever was playing) and drop the first few RX
% buffers, which still hold stale samples.

if cfg.simulate
    return;
end
release(tx);
tx.Gain = cfg.txGain;
% Setting up the TX re-configures the shared AD9363 and can reset the RX
% gain, and a receiver that keeps running still holds buffers of the
% previous waveform. So the RX is released here and set up again (by the
% rx() calls below) after the TX. Without this the signal arrives only a
% few ADC steps tall and the first buffers carry the previous modulation.
release(rx);
transmitRepeat(tx, txWave);
pause(0.5);
for k = 1:cfg.flushBuffers
    rx();
end
end
