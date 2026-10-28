function seq = frameAndNormalize(x, cfg, refRMS)
% FRAMEANDNORMALIZE  Cut a received complex buffer into 128-sample
% frames and convert each to the 2 x 128 [I; Q] format used by net1D.
% Every frame is scaled to the average RMS of the RadioML training
% frames, so the CNN sees the same amplitude range it was trained on.

x = x(:);
x = x - mean(x);                                 % remove DC / LO leakage
nFrames = floor(numel(x) / cfg.frameLen);
seq = cell(nFrames, 1);
for k = 1:nFrames
    f = x((k-1)*cfg.frameLen + (1:cfg.frameLen));
    f = f * (refRMS / max(rms(f), eps));
    seq{k} = single([real(f).'; imag(f).']);
end
end
