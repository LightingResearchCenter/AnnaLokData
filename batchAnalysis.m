function batchAnalysis
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here
[parentDir,~,~] = fileparts(pwd);
CDFtoolkit = fullfile(parentDir,'LRC-CDFtoolkit');
addpath('IO',CDFtoolkit,'phasorAnalysis');


%% File handling
projectFolder = fullfile([filesep,filesep],'root','projects',...
    'NIH Alzheimers','AnnaLokData');
indexPath = fullfile(projectFolder,'index.xlsx');
textFolder = fullfile(projectFolder,'textData');
cdfFolder = fullfile(projectFolder,'reprocessedCdfData');
resultsFolder = fullfile(projectFolder,'results');

% Import the index
[subject,AIM,dimeSN,dimeFile,startTime,stopTime,bedTime,wakeTime] = ...
    importIndex(indexPath);

% Construct path names to data
dimePath = fullfile(textFolder,dimeFile);
CDFDimePath = fullfile(cdfFolder,regexprep(dimeFile,'\.txt','.cdf'));

%% Preallocate output
nSub = length(subject);
output = dataset;
output.subject = subject;
output.AIM = AIM;
output.wakingCS = cell(nSub,1);
output.meanCS = cell(nSub,1);
output.logLux = cell(nSub,1);
output.logCLA = cell(nSub,1);
output.ActualSleep = cell(nSub,1);
output.ActualSleepPercent = cell(nSub,1);
output.ActualWake = cell(nSub,1);
output.ActualWakePercent = cell(nSub,1);
output.SleepEfficiency = cell(nSub,1);
output.Latency = cell(nSub,1);
output.SleepBouts = cell(nSub,1);
output.WakeBouts = cell(nSub,1);
output.MeanSleepBout = cell(nSub,1);
output.MeanWakeBout = cell(nSub,1);
output.phasorMagnitude = cell(nSub,1);
output.phasorAngle = cell(nSub,1);
output.IS = cell(nSub,1);
output.IV = cell(nSub,1);
output.MagH = cell(nSub,1);
output.f24abs = cell(nSub,1);

%% Begin main loop
for i1 = 7:nSub
    %% Load Dimesimeter file
    % Check if CDF versions exist
    if exist(CDFDimePath{i1},'file') == 2 % CDF Dimesimeter file exists
        dimeData = ProcessCDF(CDFDimePath{i1});
        Time1 = dimeData.Variables.time;
        CS = dimeData.Variables.CS;
        Lux = dimeData.Variables.illuminance;
        CLA = dimeData.Variables.CLA;
        Activity = dimeData.Variables.activity;
    else % CDF Dimesimeter file does not exist
        % Check if Dimesimeter file exists
        if exist(dimePath{i1},'file') ~= 2
            warning(['Dimesimeter file does not exist. File: ',dimePath{i1}]);
            continue;
        end
        % Reads the data from the dimesimeter data file
        [Time1,Lux,CLA,CS,Activity] = importDime(dimePath{i1},dimeSN(i1));
        % Create a CDF version
        WriteDaysimeterCDF(CDFDimePath{i1},Time1,Lux,CLA,CS,Activity);
    end
    
    %% Crop data
    idx1 = Time1 >= startTime(i1) & Time1 <= stopTime(i1);
    Time = Time1(idx1);
    CS = CS(idx1);
    Lux = Lux(idx1);
    CLA = CLA(idx1);
    Activity = Activity(idx1);
    
    %% Check for over cropping
    if isempty(Time)
        warning(['No data in bounds for subject ',num2str(subject(i1)),...
            ', AIM ',num2str(AIM(i1)),', dates: ',datestr(Time1(1)),...
            ' to ',datestr(Time1(end))]);
        continue;
    end
    
    %% Perform analysis
    output.wakingCS{i1} = ...
        wakingCS(Time,CS,Activity,bedTime(i1),wakeTime(i1));
    
    output.meanCS{i1} = mean(CS);
    idx2 = Lux == 0;
    Lux(idx2) = 0.01;
    output.logLux{i1} = mean(log(Lux));
    idx3 = CLA == 0;
    CLA(idx3) = 0.01;
    output.logCLA{i1} = mean(log(CLA));
    
    [output.ActualSleep{i1},output.ActualSleepPercent{i1},...
        output.ActualWake{i1},output.ActualWakePercent{i1},...
        output.SleepEfficiency{i1},output.Latency{i1},...
        output.SleepBouts{i1},output.WakeBouts{i1},...
        output.MeanSleepBout{i1},output.MeanWakeBout{i1}] = ...
        AnalyzeFile(Time,Activity,bedTime(i1),wakeTime(i1));
    
    [output.phasorMagnitude{i1},output.phasorAngle{i1},output.IS{i1},...
        output.IV{i1},~,output.MagH{i1},output.f24abs{i1}] = ...
        phasorAnalysis(Time,CS,Activity);
end

%% Save output
outputPath = fullfile(resultsFolder,['output_',datestr(now,'yy-mm-dd'),'.mat']);
save(outputPath,'output');
% Convert to Excel
organizeExcel(outputPath);

end

