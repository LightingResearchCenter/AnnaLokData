function batchSleep
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here
[parentDir,~,~] = fileparts(pwd);
CDFtoolkit = fullfile(parentDir,'LRC-CDFtoolkit');
DaysimeterSleepAlgorithm = fullfile(parentDir,'DaysimeterSleepAlgorithm');
addpath('IO','sleepAnalysis',CDFtoolkit,DaysimeterSleepAlgorithm);


%% File handling
projectFolder = fullfile([filesep,filesep],'root','projects',...
    'NIH Alzheimers','Aim 3 Local (AnnaLokData)');
indexPath = fullfile(projectFolder,'index.xlsx');
textFolder = fullfile(projectFolder,'textData');
cdfFolder = fullfile(projectFolder,'cdfData');
resultsFolder = fullfile(projectFolder,'results');

% Import the index
[subject,AIM,dimeSN,dimeFile,startTime,stopTime,bedTime,getupTime] = ...
    importIndex(indexPath);

% Construct path names to data
dimePath = fullfile(textFolder,dimeFile);
CDFDimePath = fullfile(cdfFolder,regexprep(dimeFile,'\.txt','.cdf'));

%% Preallocate output
nSub = length(subject);
output = struct;
output.line = [];
output.subject = [];
output.AIM = [];
output.Date = {};
output.ActualSleep = {};
output.ActualSleepPercent = {};
output.ActualWake = {};
output.ActualWakePercent = {};
output.SleepEfficiency = {};
output.Latency = {};
output.SleepBouts = {};
output.WakeBouts = {};
output.MeanSleepBout = {};
output.MeanWakeBout = {};
output.ImmobilityBouts =  {};
output.MobilityBouts =  {};
output.MeanImmobileBoutTime =  {};
output.MeanMobileBouts =  {};
output.Immobile1MinBouts =  {};
output.Immobile1MinPercent =  {};

%% Begin main loop
for i1 = 1:nSub
    %% Load Dimesimeter file
    % Check if CDF versions exist
    if exist(CDFDimePath{i1},'file') == 2 % CDF Dimesimeter file exists
        dimeData = ProcessCDF(CDFDimePath{i1});
        time = dimeData.Variables.time;
        CS = dimeData.Variables.CS;
        Lux = dimeData.Variables.illuminance;
        CLA = dimeData.Variables.CLA;
        activity = dimeData.Variables.activity;
    else % CDF Dimesimeter file does not exist
        % Check if Dimesimeter file exists
        if exist(dimePath{i1},'file') ~= 2
            warning(['Dimesimeter file does not exist. File: ',dimePath{i1}]);
            continue;
        end
        % Reads the data from the dimesimeter data file
        [time,Lux,CLA,CS,activity] = importDime(dimePath{i1},dimeSN(i1));
        % Create a CDF version
        WriteDaysimeterCDF(CDFDimePath{i1},time,Lux,CLA,CS,activity);
    end
    
    %% Crop data
    Time1 = time;
    idx1 = time >= startTime(i1) & time <= stopTime(i1);
    time = time(idx1);
    CS = CS(idx1);
    Lux = Lux(idx1);
    CLA = CLA(idx1);
    activity = activity(idx1);
    
    %% Check for over cropping
    if isempty(time)
        warning(['No data in bounds for subject ',num2str(subject(i1)),...
            ', AIM ',num2str(AIM(i1)),', dates: ',datestr(Time1(1)),...
            ' to ',datestr(Time1(end))]);
        continue;
    end
    
    %% Perform analysis
    % Run sleep analysis
    [tempLine,tempSubject,tempAIM,tempDate,tempActualSleep,tempActualSleepPercent,...
        tempActualWake,tempActualWakePercent,...
        tempSleepEfficiency,tempLatency,...
        tempSleepBouts,tempWakeBouts,...
        tempMeanSleepBout,tempMeanWakeBout,...
        tempImmobilityBouts, tempMobilityBouts,...
        tempMeanImmobileBoutTime, tempMeanMobileBoutTime,...
        tempImmobile1MinBouts, tempImmobile1MinPercent] = ...
        AnalyzeFile(subject(i1),AIM(i1),time,activity,bedTime(i1),getupTime(i1));
    
    %% Combine variables
    output.line = [output.line;tempLine];
    output.subject = [output.subject;tempSubject];
    output.AIM = [output.AIM;tempAIM];
    output.Date = [output.Date;tempDate];
    output.ActualSleep = [output.ActualSleep;tempActualSleep];
    output.ActualSleepPercent = [output.ActualSleepPercent;tempActualSleepPercent];
    output.ActualWake = [output.ActualWake;tempActualWake];
    output.ActualWakePercent = [output.ActualWakePercent;tempActualWakePercent];
    output.SleepEfficiency = [output.SleepEfficiency;tempSleepEfficiency];
    output.Latency = [output.Latency;tempLatency];
    output.SleepBouts = [output.SleepBouts;tempSleepBouts];
    output.WakeBouts = [output.WakeBouts;tempWakeBouts];
    output.MeanSleepBout = [output.MeanSleepBout;tempMeanSleepBout];
    output.MeanWakeBout = [output.MeanWakeBout;tempMeanWakeBout];
    output.ImmobilityBouts = [output.ImmobilityBouts;tempImmobilityBouts];
    output.MobilityBouts =  [output.MobilityBouts;tempMobilityBouts];
    output.MeanImmobileBoutTime = [output.MeanImmobileBoutTime;tempMeanImmobileBoutTime];
    output.MeanMobileBouts = [ output.MeanMobileBouts;tempMeanMobileBoutTime];
    output.Immobile1MinBouts = [output.Immobile1MinBouts;tempImmobile1MinBouts];
    output.Immobile1MinPercent = [output.Immobile1MinPercent;tempImmobile1MinPercent];
end

close all;

%% Save output
outputPath = fullfile(resultsFolder,['sleep_',datestr(now,'yyyy-mm-dd_HH-MM')]);
save([outputPath,'.mat'],'output');
organizeExcel([outputPath,'.mat'])
end

