%%% PEER analysis software by Olave E. Krigolson
%%% Version 1.0, November 18th, 2018
%%% Version 1.1, December 5th, 2018
%%% Removed convert VIHA - this is now to be done before using
%%% convertAspire.m
%%% now supports batch analysis of PEER.csv files
%%% files are loaded from an EXCEL summary file

clear all;
close all;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VARIABLES

% display channel variance
showChannelVariance = 0;                % set to 0 for batch scripts

% remove channels
channelsToRemove = {'AF7','AF8'};

% reference paramters (0 = none, 1 = front to back, 2 = all to back)
referenceChannels = {'TP9','TP10'};
channelsRereferenced = {'ALL'};

% filter parameters
filterOrder = 2;
filterLow = 0.1;                        % always keep at 0.1
filterHigh = 30;                        % set to 15 for ERP analyses, set to 30 or higher for FFT
filterNotch = 60;                       % unless in Europe use 60

% epoch parameters
epochMarkers = {'5','6'};               % the markers 5 is control 6 is oddball
currentEpoch = [-200 798];             % the time window

% baseline window
baseline = [-200 0];                    % the baseline, recommended -200 to 0

% trials to keep (if used)
trialsToKeep = 200;                     % basically a way to trim trials, do not use unless you understand what you are doing

% artifact criteria
typeOfArtifactRejction = 'Difference';  % max - min difference
artifactCriteria = 50;                  % recommend maxmin of 75
individualChannelAveraging = 0;         % set to one for individual channel averaging

% internal consistency
computeInternalConsistency = 0;         % set to 1 to do odd even averaging to allow computation of internal consistency

% wavelet analysis
waveletBaseline = [-200 -100];
waveletMin = 1;
waveletMax = 30;
waveletSteps = 30;
mortletParameter = 7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% DO NOT CHANGE STUFF BELOW HERE

% select the files to load
[filePath] = uigetdir('Select the directory where the data is');

%Change directory to where the data is
cd(filePath);

% load the EXCEL summary sheet that controls batch processing
try 
    EXCEL = readtable('SUMMARY.xlsx');
    numberOfFiles = size(EXCEL,1);
catch
    error('NO SUMMARY.xlsx FILE PRESENT TO LOAD');
end

for fileCounter = 1:numberOfFiles

    fileName = EXCEL.Filename{1};
    
    EEG = doLoadPEER(fileName);

    % compute channel variances
    EEG = doChannelVariance(EEG,showChannelVariance);

    % option to remove front channels
    % EEG = doRemoveChannels(EEG,channelsToRemove,EEG.chanlocs);

    % reference the data
    % EEG = doRereference(EEG,referenceChannels,channelsRereferenced,EEG.chanlocs);

    % filter the data
    EEG = doFilter(EEG,filterLow,filterHigh,filterOrder,filterNotch,EEG.srate);

    % epoch data
    EEG = doSegmentData(EEG,epochMarkers,currentEpoch);

    % remove trials if needed
    % EEG = doRemoveTrials(EEG,trialsToKeep)

    % concatenate data to increase SNR
    % EEG = doIncreasePEERSNR(EEG,2);

    % apply a linear detrend to the data if asked for
    % EEG = doDetrend(EEG);

    % baseline correction
    EEG = doBaseline(EEG,baseline);

    % identify artifacts
    EEG = doArtifactRejection(EEG,typeOfArtifactRejction,artifactCriteria);

    % remove bad trials
    EEG = doRemoveEpochs(EEG,EEG.artifactPresent,individualChannelAveraging);

    % make ERPs
    ERP = doERP(EEG,epochMarkers,computeInternalConsistency);

    % do a FFT on the data
    FFT = doFFT(EEG,epochMarkers);

    % do Wavelet analysis
    % WAV = doWAV(EEG,epochMarkers,waveletBaseline,waveletMin,waveletMax,waveletSteps,mortletParameter);

    OUTPUT{fileCounter}.EEG = EEG;
    
    OUTPUT{fileCounter}.ERP = ERP;

    OUTPUT{fileCounter}.FFT = FFT;
    
    % OUTPUT{fileCounter}.WAV = WAV;
    
    OUTPUT.EXCEL = EXCEL;
    
end

save('OUTPUT','OUTPUT');

clear a* c* D* e* E* F* f* i* m* n* o* r* s* t* v*