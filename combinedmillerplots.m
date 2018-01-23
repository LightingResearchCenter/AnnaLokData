function combinedmillerplots
%COMBINEDMILLERPLOTS Summary of this function goes here
%   Detailed explanation goes here
[parentDir,~,~] = fileparts(pwd);
CDFtoolkit = fullfile(parentDir,'LRC-CDFtoolkit');
addpath(CDFtoolkit);

% Specifiy valid subjects
% validSubjectArray = [5,8,10,11,12,13,15,16,19,20];
validSubjectArray = [5,8,10,11,12,13,15,16,20];

% File handling
projectFolder = '\\ROOT\projects\NIH Alzheimers\Aim 3 Local (AnnaLokData)';
indexPath = fullfile(projectFolder,'phasorIndex.xlsx');
cdfFolder = fullfile(projectFolder,'reprocessedCdfData');
plotDir = fullfile(projectFolder,'combinedMillerPlots');

% Import the index
[subject,week,~,cdfFile,startTime,stopTime,cropStart1,cropStop1] = importphasorindex(indexPath);
validIdx = false(size(subject));
for i0 = 1:numel(validSubjectArray)
    validIdx = validIdx | (subject == validSubjectArray(i0));
end

% Keep only the valid subjects
subject    = subject(validIdx);
week       = week(validIdx);
cdfFile    = cdfFile(validIdx);
startTime  = startTime(validIdx);
stopTime   = stopTime(validIdx);
cropStart1 = cropStart1(validIdx);
cropStop1  = cropStop1(validIdx);

% Construct path names to data
cdfPath = fullfile(cdfFolder,cdfFile);


unqWeek = unique(week);
figure('Renderer','painters');
% Begin main loop
for i1 = 1:numel(unqWeek)
    idxWeek = week == unqWeek(i1);
    weekCdfPathArray = cdfPath(idxWeek);
    weekStartTime = startTime(idxWeek);
    weekStopTime = stopTime(idxWeek);
    weekCropStart = cropStart1(idxWeek);
    weekCropStop = cropStop1(idxWeek);
    
    % Begin secondary loop
    for i2 = 1:numel(weekCdfPathArray)
        % Load Dimesimeter file
        Data = ProcessCDF(weekCdfPathArray{i2});
        timeArray = Data.Variables.time;
        csArray = Data.Variables.CS;
        activityArray = Data.Variables.activity;
        
        % Crop the data
        [timeArray,csArray,activityArray] = ...
            cropdata(timeArray,csArray,activityArray,...
            weekStartTime(i2),weekStopTime(i2),weekCropStart(i2),weekCropStop(i2));
        
        % Check for overcropping
        overcropped = checkovercropping(timeArray);
        if overcropped
            continue;
        end
        
        % Average the data by time
        [hourArray,mCsArray,mActivityArray] = millerizedata(timeArray,csArray,activityArray);
        combinedHourArray{1,i2} = hourArray(:);
        combinedCsArray{1,i2} = mCsArray(:);
        combinedActivityArray{1,i2} = mActivityArray(:);
    end
    % Combine and average data for week
    combinedHourArray = cell2mat(combinedHourArray);
    combinedCsArray = cell2mat(combinedCsArray);
    combinedActivityArray = cell2mat(combinedActivityArray);
    
    mWeekHourArray = mean(combinedHourArray,2);
    mWeekCsArray = mean(combinedCsArray,2);
    mWeekActivityArray = mean(combinedActivityArray,2);
    
    % Plot data and save to file
    plotdata(mWeekHourArray,mWeekCsArray,mWeekActivityArray,unqWeek(i1));
    savePath = fullfile(plotDir,['millerPlotWeek',num2str(unqWeek(i1))]);
    saveas(gcf,[savePath,'.pdf']);
    saveas(gcf,[savePath,'.jpg']);
    saveas(gcf,[savePath,'.eps']);
    clf;
    clear('combinedHourArray','combinedCsArray','combinedActivityArray');
end

close('all');

end


function [timeArray,csArray,activityArray] = cropdata(timeArray,csArray,activityArray,startTime,stopTime,cropStart1,cropStop1)

% Crop data
idx1 = timeArray >= startTime & timeArray <= stopTime;
if ~isnan(cropStart1)
    idx2 = timeArray >= cropStart1 & timeArray <= cropStop1;
    idx3 = idx1 & ~idx2;
else
    idx3 = idx1;
end
timeArray = timeArray(idx3);
csArray = csArray(idx3);
activityArray = activityArray(idx3);

end

function overcropped = checkovercropping(timeArray)

% Check for over cropping
epoch = mode(round(diff(timeArray)*24*60*60));
nPoints = numel(timeArray);
if isempty(timeArray) || (nPoints*epoch < 24*3600)
    warning('Not enough data in bounds');
    overcropped = true;
else
    overcropped = false;
end

end

function [hourArray,mCsArray,mActivityArray] = millerizedata(timeArray,csArray,activityArray)
timeIndex = timeArray - floor(timeArray(1));

% Reshape data into columns of full days
% ASSUMES CONSTANT SAMPLING RATE
epoch = mode(round(diff(timeArray)*24*60*60));
dayIdx = floor((24*60*60)/epoch);
extra = rem(length(timeIndex),dayIdx)-1;
csArray(end-extra:end) = [];
activityArray(end-extra:end) = [];
csArray = reshape(csArray,dayIdx,[]);
activityArray = reshape(activityArray,dayIdx,[]);

% Average data across days
mCsArray = mean(csArray,2);
mActivityArray = mean(activityArray,2);

% Trim time index
timeIndex = timeIndex(1:dayIdx);
% Convert time index into hours from start
hourArray = mod(timeIndex,1)*24;

% Order the data
[hourArray,sortIdx] = sort(hourArray);
mCsArray = mCsArray(sortIdx);
mActivityArray = mActivityArray(sortIdx);

end

function plotdata(hourArray,csArray,activityArray,week)
% Create axes to plot on
hAxes = axes;
hold(hAxes,'on');

hAxes2=axes('yaxislocation','right','color','none');

set(hAxes,'XTick',0:2:24);
set(hAxes,'TickDir','out');

set(hAxes2,'XTick',[]);
set(hAxes2,'XTickLabel','');
set(hAxes2,'TickDir','out');

xlim(hAxes,[0 24]);
xlim(hAxes2,[0 24]);

yMax = 0.7;
if max(activityArray) > yMax
    yMax = max(activityArray);
else
    yTick = 0:0.1:0.7;
    set(hAxes,'YTick',yTick);
    set(hAxes2,'YTick',yTick);
end
ylim(hAxes,[0 yMax]);
ylim(hAxes2,[0 yMax]);
box('off');

% Plot AI

area1 = area(hAxes,hourArray,activityArray,'LineStyle','none');
set(area1,...
    'FaceColor',[180, 211, 227]/256,'EdgeColor','none',...
    'DisplayName','Activity');

% Plot CS
plot1 = plot(hAxes,hourArray,csArray);
set(plot1,...
    'Color','k','LineWidth',2,...
    'DisplayName','Circadian Stimulus');

% Create legend
legend1 = legend([area1,plot1]);
set(legend1,'Orientation','horizontal','Location','North');

% Create x-axis label
xlabel(hAxes,'Time (hours)');

ylabel(hAxes,'Circadian Stimulus (CS)');
ylabel(hAxes2,'Activity Index (AI)');

% Create title
switch week
    case 0
        plotTitle = 'Baseline';
    case 1
        plotTitle = 'Intervention';
    case 2
        plotTitle = 'Post Intervention';
    otherwise
        plotTitle = 'Unknown';
end
title(plotTitle);

% Plot a box
z = [100,100];
hLine1 = line([0 24],[yMax yMax],z,'Color','k');
hLine2 = line([24 24],[0 yMax],z,'Color','k');
hLine3 = line([0 24],[0 0],z,'Color','k');
hLine4 = line([0 0],[0 yMax],z,'Color','k');

set(hLine1,'Clipping','off');
set(hLine2,'Clipping','off');
set(hLine3,'Clipping','off');
set(hLine4,'Clipping','off');
end
