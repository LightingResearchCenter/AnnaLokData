function dfatrial
%DFATRIAL Summary of this function goes here
%   Detailed explanation goes here

% Find full path to github directory
[githubDir,~,~] = fileparts(pwd);
% Contruct repo paths
cdfPath         = fullfile(githubDir,'LRC-CDFtoolkit');
dfaPath         = fullfile(githubDir,'DetrendedFluctuationAnalysis');
% Enable repos
addpath(cdfPath,dfaPath);

% File handling
projectFolder = '\\ROOT\projects\NIH Alzheimers\Aim 3 Local (AnnaLokData)';
combinedIndexPath = fullfile(projectFolder,'combinedIndex.xlsx');
cdfFolder = fullfile(projectFolder,'cdfData');
resultsFolder = fullfile(projectFolder,'results');

% Import the index
Index = importcombinedindex(combinedIndexPath);
% Construct path names to data
cdfPathArray = fullfile(cdfFolder,Index.file);

% Preallocate and intialize resources
nFiles          = numel(cdfPathArray);
order           = 1;
timeScaleRange  = [duration(1,30,0),duration(8,0,0)];
templateCell    = cell(nFiles,1);

subject  = Index.subject;
condition = Index.conditionName;
alpha    = templateCell;

% Begin main loop
parfor i1 = 1:nFiles
    
    % Import data
    Data = ProcessCDF(cdfPathArray{i1});
    
    timeArray = Data.Variables.time;
    datetimeArray = datetime(timeArray,'ConvertFrom','datenum');
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
    datetimeArray = datetimeArray(idx3);
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
    
    % Perform DFA
    alpha{i1} = dfa(datetimeArray,activityArray,order,timeScaleRange);
    
end

% Save output
Output          = dataset;
Output.subject  = subject;
Output.condition = condition;
Output.alpha    = alpha;

outputCell = dataset2cell(Output);
varNameArray = outputCell(1,:);
prettyVarNameArray = lower(regexprep(varNameArray,'([^A-Z])([A-Z0-9])','$1 $2'));
outputCell(1,:) = prettyVarNameArray;

runtime = datestr(now,'yyyy-mm-dd_HHMM');
resultsPath = fullfile(resultsFolder,['dfa-trial_',runtime,'_AnnaLok.xlsx']);
xlswrite(resultsPath,outputCell);
end

