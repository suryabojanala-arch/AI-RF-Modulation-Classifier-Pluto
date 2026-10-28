function cfg = plutoConfig()
% PLUTOCONFIG  Shared settings for the ADALM-Pluto stage of the
% AI-Powered RF Digital Twin project. Edit values here only.

%% Mode
% true  -> no hardware: waveforms go through a simulated channel
%          (use this to test the whole pipeline before the Pluto arrives)
% false -> real ADALM-Pluto (TX port looped to RX port)
cfg.simulate = false;

%% Radio
cfg.radioID     = 'usb:0';      % from findPlutoRadio
cfg.fc          = 915e6;        % centre frequency (Hz), over the air between the two antennas
cfg.fs          = 1e6;          % baseband sample rate (Hz)
cfg.txGain      = -30;          % dB, range -89.75 .. 0
                                % (-30 with antennas; 0 with nothing attached)
cfg.rxGainMode  = 'Manual';     % 'Manual' or 'AGC Slow Attack'
cfg.rxGain      = 30;           % dB, used when rxGainMode = 'Manual'
                                % (tuned for the two antennas on TX/RX;
                                %  was 60 with nothing attached)

%% Signal format (matches RadioML 2016.10a)
cfg.classes     = {'AM-DSB','BPSK','QAM16','QPSK','WBFM'};
cfg.frameLen    = 128;          % samples per CNN input frame
cfg.sps         = 8;            % samples per symbol (digital mods)
cfg.rolloff     = 0.35;         % RRC roll-off
cfg.rrcSpan     = 10;           % RRC span in symbols
cfg.nSymbols    = 4000;         % symbols per transmitted digital burst
cfg.amIndex     = 0.8;          % AM modulation index
cfg.fmDev       = 20e3;         % WBFM peak frequency deviation (Hz)
cfg.audioSec    = 0.5;          % seconds of audio for analog mods

%% Receive
cfg.framesPerBuffer = 64;                         % CNN frames per rx() call
cfg.samplesPerFrame = cfg.frameLen*cfg.framesPerBuffer;
cfg.flushBuffers    = 5;                          % stale buffers to drop

%% Files
% Paths are relative to the repository root (one level above this
% folder), so the scripts work whatever MATLAB's current folder is.
%   models/  trained networks      data/  datasets and saved results
cfg.projectDir   = fileparts(fileparts(mfilename('fullpath')));
m = @(name) fullfile(cfg.projectDir, 'models', name);
d = @(name) fullfile(cfg.projectDir, 'data', name);
cfg.modelFile    = m('RF_Modulation_AI_v2.mat');    % RadioML CNN, 70/15/15 split
                                                    % (train_radioml_tvt.m)
cfg.midReviewModelFile = m('RF_Modulation_AI.mat'); % mid-review CNN (80/20)
cfg.datasetFile  = d('RadioML2016_mid.mat');        % not in the repo (199 MB), see README
cfg.refFile      = d('pluto_ref.mat');              % reference RMS (step 2)
cfg.captureFile  = d('Pluto_Captured_Dataset.mat'); % step 4 output
cfg.tunedFile    = m('RF_Modulation_AI_Pluto.mat'); % step 6 output
cfg.liveModelFile = cfg.tunedFile;               % model used by the step 3
                                                 % live dashboard (set to
                                                 % cfg.modelFile for original)

%% Simulation channel (only when cfg.simulate = true)
cfg.simSNRdB     = 15;
cfg.simCFOHz     = 200;
end
