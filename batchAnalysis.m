function batchAnalysis
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here

%% File handling
projectFolder = fullfile([filesep,filsep],'root','projects',...
    'NIH Alzheimers','TroyALZ2011');
rawFolder = fullfile(projectFolder,'rawData');
indexPath = fullfile(rawFolder,'index.xlsx');
cdfFolder = fullfile(projectFolder,'cdfData');

% Import the index
[subject,AIM,dimeSN,dimeFile,startTime,stopTime,bedTime,wakeTime] = ...
    importIndex(file);

end

