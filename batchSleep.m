function batchSleep
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here
[parentDir,~,~] = fileparts(pwd);
CDFtoolkit = fullfile(parentDir,'LRC-CDFtoolkit');
DaysimeterSleepAlgorithm = fullfile(parentDir,'DaysimeterSleepAlgorithm');
addpath('IO',CDFtoolkit,DaysimeterSleepAlgorithm);


% File handling
projectFolder = '\\ROOT\projects\NIH Alzheimers\Aim 3 Local (AnnaLokData)';
indexPath = fullfile(projectFolder,'index.xlsx');
cdfFolder = fullfile(projectFolder,'cdfData');
resultsFolder = fullfile(projectFolder,'results');

% Import the index
[subject,AIM,dimeSN,cdfFile,startTime,stopTime,bedTime,getupTime] = ...
    importIndex(indexPath);

% Construct path names to data
cdfPath = fullfile(cdfFolder,cdfFile);

% Preallocate output
nCDF = numel(cdfPath);
output = cell(nCDF,1);

% Begin main loop
for i1 = 1:nCDF
    % Load Dimesimeter file
    % Check if CDF versions exist
    dimeData = ProcessCDF(cdfPath{i1});
    time = dimeData.Variables.time;
    CS = dimeData.Variables.CS;
    Lux = dimeData.Variables.illuminance;
    CLA = dimeData.Variables.CLA;
    activity = dimeData.Variables.activity;
    
    % Crop data
    Time1 = time;
    idx1 = time >= startTime(i1) & time <= stopTime(i1);
    time = time(idx1);
    CS = CS(idx1);
    Lux = Lux(idx1);
    CLA = CLA(idx1);
    activity = activity(idx1);
    
    % Check for over cropping
    if isempty(time)
        warning(['No data in bounds for subject ',num2str(subject(i1)),...
            ', AIM ',num2str(AIM(i1)),', dates: ',datestr(Time1(1)),...
            ' to ',datestr(Time1(end))]);
        continue;
    end
    
    % Perform analysis
    % Run sleep analysis
    output{i1} = ...
        AnalyzeFile(subject(i1),AIM(i1),time,activity,bedTime(i1),getupTime(i1));
    
end

close('all');

% Save output
outputPath = fullfile(resultsFolder,['sleep_',datestr(now,'yyyy-mm-dd_HH-MM')]);
save([outputPath,'.mat'],'output');
organizeExcel([outputPath,'.mat'])
end

