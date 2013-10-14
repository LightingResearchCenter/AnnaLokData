function groupCentroid
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

addpath('IO','CDF','centroidAnalysis');

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
CDFDimePath = fullfile(cdfFolder,regexprep(dimeFile,'\.txt','.cdf'));

%% Import data
% Preallocate cells
n = length(dimePath);
Time = cell(n,1);
CS = cell(n,1);
Activity = cell(n,1);

for i1 = 1:n % Begin main loop through all subjects
    %% Load Dimesimeter file
    % Check if Dimesimeter file exists
    if exist(dimePath{i1},'file') ~= 2
        warning(['Dimesimeter file does not exist. File: ',dimePath{i1}]);
        continue;
    end
    % Check if CDF versions exist
    if exist(CDFDimePath{i1},'file') == 2 % CDF Dimesimeter file exists
        dimeData = ProcessCDF(CDFDimePath{i1});
        Time1 = dimeData.Variables.Time;
        tempCS = dimeData.Variables.CS;
        tempActivity = dimeData.Variables.Activity;
    else % CDF Actiwatch file does not exist
        % Reads the data from the dimesimeter data file
        [Time1,Lux,CLA,tempCS,tempActivity] = importDime(dimePath{i1},dimeSN(i1));
        % Create a CDF version
        WriteDimesimeterCDF(CDFDimePath{i1},Time1,Lux,CLA,tempCS,tempActivity);
    end

    %% Crop data
    idx1 = Time1 >= startTime(i1) & Time1 <= stopTime(i1);
    tempTime = Time1(idx1);
    tempCS = tempCS(idx1);
    tempActivity = tempActivity(idx1);
    
    % Check for over cropping
    if isempty(tempTime)
        warning(['No data in bounds for subject ',num2str(subject(i1)),...
            ', AIM ',num2str(AIM(i1)),', dates: ',datestr(Time1(1)),...
            ' to ',datestr(Time1(end))]);
        continue;
    end
    
    %% Store data in cells
    Time{i1} = tempTime;
    CS{i1} = tempCS;
    Activity{i1} = tempActivity;
    
end


%% Random stuff
% Set sub-title values
subTitle = {'Baseline (AIM 0)',...
    'Intervention (AIM 1)',...
    'Post-Intervention (AIM 2)'};

%% Create figure window
close all;
fig = figure;
paperPosition = [0 0 11 8.5];
set(fig,'PaperUnits','inches',...
    'PaperType','usletter',...
    'PaperOrientation','landscape',...
    'PaperPositionMode','manual',...
    'PaperPosition',paperPosition,...
    'Units','inches',...
    'Position',paperPosition);

%% Set spacing values
xMargin = 0.5/paperPosition(3);
xSpace = 0.25/paperPosition(3);
yMargin = 0.5/paperPosition(4);
ySpace = 0.25/paperPosition(4);

% Calculate usable space for plots
workHeight = 1-2*ySpace-2*yMargin;
workWidth = 1-2*xMargin;

%% Position axes
axWidth = (workWidth-2*xSpace)/3;
axHeight = axWidth*paperPosition(3)/paperPosition(4);
% Check if height is taller than possible
if axHeight > workHeight
    axHeight = workHeight;
    axWidth = axHeight*paperPosition(4)/paperPosition(3);
end
axY = (yMargin + (workHeight - axHeight)/2)*ones(3,1); % Center vertically
axX = [xMargin,xMargin+axWidth+xSpace,xMargin+2*axWidth+2*xSpace];

%% Plot the annotation
dateStamp(fig,xMargin,yMargin);
titleStr = {'All Subjects','Anna Lok Data'};
plotTitle(fig,titleStr,yMargin);

for i2 = 1:3
    %% Combine the data
    idx2 = AIM == i2-1;
    [grpTime,grpCS,grpActivity] = mergeData(Time(idx2),CS(idx2),Activity(idx2));
    
    
    %% Plot the data
    % Create axes
    axes('Parent',fig,...
        'Position',[axX(i2),axY(i2),axWidth,axHeight]);
    % Plot the data
    [~,~] = millerDot(grpTime,grpCS,grpActivity);
    % Plot one legend
    if i2 == 1
        legend1 = legend('Activity','CS','CS Centroid',...
            'Orientation','horizontal');
        posLeg = get(legend1,'Position');
        set(legend1,'Position',...
            [0.5-posLeg(3)/2,axY(i2)-ySpace-posLeg(4),posLeg(3:4)]);
    end
    % Plot the sub-title
    stX = axX(i2) + axWidth/2;
    stY = axY(i2) + axHeight;
    plotSubTitle(fig,subTitle{i2},stX,stY);
end % End of subject loop

% Save plot to file
fileBase = 'combinedeMillerDot.pdf';
reportFile = fullfile(resultsFolder,fileBase);
saveas(gcf,reportFile);
clf;
    
close all;
end


%% Subfunction to plot a centered title block
function plotTitle(fig,titleStr,yMargin)
% Create title
titleHandle = annotation(fig,'textbox',...
    [0.5,1-yMargin,0.1,0.1],...
    'String',titleStr,...
    'FitBoxToText','on',...
    'HorizontalAlignment','center',...
    'LineStyle','none',...
    'FontSize',14);
% Center the title and shift down
titlePosition = get(titleHandle,'Position');
titlePosition(1) = 0.5-titlePosition(3)/2;
titlePosition(2) = 1-yMargin-titlePosition(4);
set(titleHandle,'Position',titlePosition);
end

%% Subfunction to plot a date stamp in the top right corner
function dateStamp(fig,xMargin,yMargin)
% Create date stamp
dateStamp = ['Printed: ',datestr(now,'mmm. dd, yyyy HH:MM')];
datePosition = [0.8,1-yMargin,0.1,0.1];
dateHandle = annotation(fig,'textbox',datePosition,...
    'String',dateStamp,...
    'FitBoxToText','on',...
    'HorizontalAlignment','right',...
    'LineStyle','none');
% Shift left and down
datePosition = get(dateHandle,'Position');
datePosition(1) = 1-xMargin-datePosition(3);
datePosition(2) = 1-yMargin-datePosition(4); 
set(dateHandle,'Position',datePosition);
end

%% Subfunction to plot a centered sub-title block
function plotSubTitle(fig,subTitle,stX,stY)
% Create sub-title
subTitleHandle = annotation(fig,'textbox',...
    [stX,stY,0.1,0.1],...
    'String',subTitle,...
    'FitBoxToText','on',...
    'HorizontalAlignment','center',...
    'LineStyle','none',...
    'FontSize',11);
% Center the sub-title
subTitlePosition = get(subTitleHandle,'Position');
subTitlePosition(1) = stX-subTitlePosition(3)/2;
set(subTitleHandle,'Position',subTitlePosition);
end

%% Subfunction to merge data
function [grpTime,grpCS,grpActivity] = mergeData(Time,CS,Activity)
n = length(Time);
t1 = zeros(n,1);
t2 = zeros(n,1);

% Make time relative
for i1 = 1:n
    Time{i1} = Time{i1} - floor(Time{i1}(1));
    t1(i1) = Time{i1}(1);
    t2(i1) = Time{i1}(end);
end

% Find extreme end points
maxt1 = max(t1);
mint2 = min(t2);

% Trim data to extremes
for i2 = 1:n
    idx1 = Time{i2} >= maxt1 & Time{i2} <= mint2;
    Time{i2} = Time{i2}(idx1);
    CS{i2} = CS{i2}(idx1);
    Activity{i2} = Activity{i2}(idx1);
end

% Convert cells to matrices
Time = cell2mat(Time');
CS = cell2mat(CS');
Activity = cell2mat(Activity');

% Average data
grpTime = mean(Time,2);
grpCS = mean(CS,2);
grpActivity = mean(Activity,2);

end