function batchphasorsanssleep
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here
[parentDir,~,~] = fileparts(pwd);
CDFtoolkit = fullfile(parentDir,'LRC-CDFtoolkit');
addpath('IO',CDFtoolkit,'phasorAnalysis');


% File handling
projectFolder = '\\ROOT\projects\NIH Alzheimers\Aim 3 Local (AnnaLokData)';
combinedIndexPath = fullfile(projectFolder,'combinedIndex.xlsx');
cdfFolder = fullfile(projectFolder,'cdfData');
resultsFolder = fullfile(projectFolder,'results');

% Import the index
Index = importcombinedindex(combinedIndexPath);

% Construct path names to data
cdfPath = fullfile(cdfFolder,Index.file);

% Preallocate output
nCDF = numel(cdfPath);
output = cell(nCDF,1);

% Begin main loop
for i1 = 1:nCDF
    % Load Dimesimeter file
    % Check if CDF versions exist
    Data = ProcessCDF(cdfPath{i1});
    timeArray = Data.Variables.time;
    csArray = Data.Variables.CS;
    claArray = Data.Variables.CLA;
    activityArray = Data.Variables.activity;
    
    % Crop data
    timeArrayCopy = timeArray;
    idx1 = timeArray >= Index.startTime(i1) & timeArray <= Index.stopTime(i1);
    if ~isnan(Index.removeStart(i1))
        idx2 = timeArray >= Index.removeStart(i1) & timeArray <= Index.removeStop(i1);
        idx3 = idx1 & ~idx2;
    else
        idx3 = idx1;
    end
    timeArray = timeArray(idx3);
    csArray = csArray(idx3);
    claArray = claArray(idx3);
    activityArray = activityArray(idx3);
    
    % Check for over cropping
    epoch = round(mode(diff(timeArray))*24*3600*1000)/1000;
    nPoints = numel(timeArray);
    if isempty(timeArray) || (nPoints*epoch < 24*3600)
        warning(['Not enough data in bounds for subject ',num2str(subject(i1)),...
            ', AIM ',num2str(week(i1)),', dates: ',datestr(timeArrayCopy(1)),...
            ' to ',datestr(timeArrayCopy(end))]);
        continue;
    end
    
    % Replace time in bed
    modTimeArray = mod(timeArray,1);
    idxInBed = modTimeArray >= Index.bedTime(i1) | modTimeArray <= Index.getupTime(i1);
    csArray(idxInBed) = 0;
    claArray(idxInBed) = 0;
    activityArray(idxInBed) = 0;
    
    % Perform analysis
    output{i1} = phasorAnalysis(timeArray, csArray, activityArray, claArray, Index.subject(i1), Index.condition(i1));
    
end

close('all');

% Save output
outputPath = fullfile(resultsFolder,['phasorSansSleep_',datestr(now,'yyyy-mm-dd_HH-MM')]);
save([outputPath,'.mat'],'output');
organizephasorexcel([outputPath,'.mat'])
end

