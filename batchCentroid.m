function batchCentroid
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

%% Random stuff
% Find unique subject numbers
unqSub = unique(subject);

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

%% Calculate usable space for plots
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

%% Begin loops

for i1 = 1:length(unqSub) % Begin main loop through all subjects
    %% Plot the annotation
    dateStamp(fig,xMargin,yMargin);
    titleStr = {['Subject ',num2str(unqSub(i1))],'Anna Lok Data'};
    plotTitle(fig,titleStr,yMargin);
    
    for i2 = 1:3 % Begin loop through one subject's weeks
        idx1 = subject == unqSub(i1) & AIM == i2-1;
        % Skip empty entries
        if max(idx1) == 0;
            continue;
        end
        
        %% Load Dimesimeter file
        % Check if Dimesimeter file exists
        if exist(dimePath{idx1},'file') ~= 2
            warning(['Dimesimeter file does not exist. File: ',dimePath{idx1}]);
            continue;
        end
        % Check if CDF versions exist
        if exist(CDFDimePath{idx1},'file') == 2 % CDF Dimesimeter file exists
            dimeData = ProcessCDF(CDFDimePath{idx1});
            Time1 = dimeData.Variables.Time;
            CS = dimeData.Variables.CS;
            Activity = dimeData.Variables.Activity;
        else % CDF Actiwatch file does not exist
            % Reads the data from the dimesimeter data file
            [Time1,Lux,CLA,CS,Activity] = importDime(dimePath{idx1},dimeSN(idx1));
            % Create a CDF version
            WriteDimesimeterCDF(CDFDimePath{idx1},Time1,Lux,CLA,CS,Activity);
        end
        
        %% Crop data
        idx2 = Time1 >= startTime(idx1) & Time1 <= stopTime(idx1);
        Time = Time1(idx2);
        CS = CS(idx2);
        Activity = Activity(idx2);

        %% Check for over cropping
        if isempty(Time)
            warning(['No data in bounds for subject ',num2str(subject(i1)),...
                ', AIM ',num2str(AIM(i1)),', dates: ',datestr(Time1(1)),...
                ' to ',datestr(Time1(end))]);
            continue;
        end
        
        %% Plot the data
        % Create axes
        axes('Parent',fig,...
            'Position',[axX(i2),axY(i2),axWidth,axHeight]);
        % Plot the data
        [~,~] = millerDot(Time,CS,Activity,subTitle);
        % Plot bed time and wake time
        thetaBed = bedTime(idx1)*2*pi;
        line([0,.7*cos(thetaBed)],[0,.7*sin(thetaBed)],...
            'Color','k','LineWidth',1.5);
        thetaWake = wakeTime(idx1)*2*pi;
        line([0,.7*cos(thetaWake)],[0,.7*sin(thetaWake)],...
            'Color','k','LineWidth',1.5,'LineStyle','--');
        % Plot one legend
        if i2 == 1
            legend1 = legend('Activity','CS','CS Centroid',...
                'Bed Time','Wake Time','Orientation','horizontal');
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
    fileBase = ['subject',num2str(unqSub(i1),'%02.f'),'millerDot.pdf'];
    reportFile = fullfile(resultsFolder,fileBase);
    saveas(gcf,reportFile);
    clf;
end % End of main loop
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
