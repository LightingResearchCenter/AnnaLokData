function batchAnalysis
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here

addpath('IO','CDF');

%% File handling
projectFolder = fullfile([filesep,filesep],'root','projects',...
    'NIH Alzheimers','AnnaLokData');
indexPath = fullfile(projectFolder,'index.xlsx');
textFolder = fullfile(projectFolder,'textData');
cdfFolder = fullfile(projectFolder,'cdfData');
resultsFolder = fullfile(projectFolder,'results');

% Import the index
[subject,AIM,dimeSN,dimeFile,startTime,stopTime,bedTime,wakeTime] = ...
    importIndex(indexPath);

% Construct path names to data
dimePath = fullfile(textFolder,dimeFile);
CDFdimePath = fullfile(cdfFolder,regexprep(dimeFile,'\.txt','.cdf'));

%% Preallocate output
nSub = length(subject);


%% Begin main loop
for i1 = 1:nSub
    %% Load Dimesimeter file
    % Check if Dimesimeter file exists
    if exist(dimePath{i1},'file') ~= 2
        warning(['Dimesimeter file does not exist. File: ',dimePath{i1}]);
        continue;
    end
    % Check if CDF versions exist
    if exist(CDFdimePath{i1},'file') == 2 % CDF Dimesimeter file exists
        dimeData = ProcessCDF(CDFdimePath{i1});
        dTime = dimeData.Variables.Time;
        CS = dimeData.Variables.CS;
        AI = dimeData.Variables.Activity;
    else % CDF Actiwatch file does not exist
        % Reads the data from the dimesimeter data file
        [dTime,lux,CLA,CS,AI] = importDime(dimePath{i1},dimeSN(i1));
        % Create a CDF version
        WriteDimesimeterCDF(CDFdimePath{i1},dTime,lux,CLA,CS,AI);
    end
end

end

