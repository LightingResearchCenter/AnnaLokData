function batchPhasor
%BATCHANALYSIS Summary of this function goes here
%   Detailed explanation goes here
[parentDir,~,~] = fileparts(pwd);
CDFtoolkit = fullfile(parentDir,'LRC-CDFtoolkit');
addpath('IO',CDFtoolkit,'phasorAnalysis');


% File handling
projectFolder = '\\ROOT\projects\NIH Alzheimers\Aim 3 Local (AnnaLokData)';
indexPath = fullfile(projectFolder,'phasorIndex.xlsx');
cdfFolder = fullfile(projectFolder,'cdfData');
resultsFolder = fullfile(projectFolder,'results');
plotDir = fullfile(projectFolder,'phasorSourceDataPlots');

% Import the index
[subject,week,~,cdfFile,startTime,stopTime,cropStart1,cropStop1] = importphasorindex(indexPath);

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
    if ~isnan(cropStart1(i1))
        idx2 = time >= cropStart1(i1) & time <= cropStop1(i1);
        idx3 = idx1 & ~idx2;
    else
        idx3 = idx1;
    end
    time = time(idx3);
    CS = CS(idx3);
    Lux = Lux(idx3);
    CLA = CLA(idx3);
    activity = activity(idx3);
    
    % Check for over cropping
    epoch = round(mode(diff(time))*24*3600*1000)/1000;
    nPoints = numel(time);
    if isempty(time) || (nPoints*epoch < 24*3600)
        warning(['Not enough data in bounds for subject ',num2str(subject(i1)),...
            ', AIM ',num2str(week(i1)),', dates: ',datestr(Time1(1)),...
            ' to ',datestr(Time1(end))]);
        continue;
    end
    
    % Plot the data and save to file
    plotName = ['sub',num2str(subject(i1),'%02.0f'),'_wk',num2str(week(i1)),'_',datestr(time(1),'yyyy-mm-dd'),'.png'];
    plotPath = fullfile(plotDir,plotName);
    plotactivityandcs(plotPath,time,activity,CS,subject(i1),week(i1));
    
    % Perform analysis
    output{i1} = phasorAnalysis(time, CS, activity, subject(i1), week(i1));
    
end

close('all');

% Save output
outputPath = fullfile(resultsFolder,['phasor_',datestr(now,'yyyy-mm-dd_HH-MM')]);
save([outputPath,'.mat'],'output');
organizephasorexcel([outputPath,'.mat'])
end

