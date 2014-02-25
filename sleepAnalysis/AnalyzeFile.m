function [Line,Subject,AIM,Date,ActualSleep,ActualSleepPercent,ActualWake,...
    ActualWakePercent,SleepEfficiency,Latency,SleepBouts,WakeBouts,...
    MeanSleepBout,MeanWakeBout] = AnalyzeFile(subject,aim,Time,Activity,bedTime,wakeTime)

% Find maximum activity
maxActi = max(Activity);

%% Vectorize bed times and wake times
startDays = floor(min(Time)):floor(max(Time));
bedTimes = startDays + bedTime;
if bedTime > wakeTime
    wakeTimes = startDays + 1 + wakeTime;
else
    wakeTimes = startDays + wakeTime;
end

if bedTimes(end) > max(Time) || wakeTimes(end) > max(Time)
    bedTimes(end) = [];
    wakeTimes(end) = [];
end

if bedTimes(1) < min(Time) || wakeTimes(1) < min(Time)
    bedTimes(1) = [];
    wakeTimes(1) = [];
end

% Set analysis start and end times
analysisStartTime = bedTimes - 20/60/24;
analysisEndTime = wakeTimes + 20/60/24;

nDays = length(bedTimes);

%% Preallocate sleep parameters
Line = zeros(nDays,1);
Subject = zeros(nDays,1);
AIM = -1.*ones(nDays,1);
Date = cell(nDays,1);
ActualSleep = cell(nDays,1);
ActualSleepPercent = cell(nDays,1);
ActualWake = cell(nDays,1);
ActualWakePercent = cell(nDays,1);
SleepEfficiency = cell(nDays,1);
Latency = cell(nDays,1);
SleepBouts = cell(nDays,1);
WakeBouts = cell(nDays,1);
MeanSleepBout = cell(nDays,1);
MeanWakeBout = cell(nDays,1);

dateFormat = 'dd-mmm-yy';
dateTimeFormat = 'dd-mmm-yyyy HH:MM';

plot(Time,Activity);
datetick2;
title({['Subject ',num2str(subject),' AIM ',num2str(aim)];...
        [datestr(analysisStartTime(1),dateFormat),' - ',datestr(analysisEndTime(end),dateFormat)]});
hold on;

%% Call function to calculate sleep parameters for each day
for i1 = 1:nDays
    Line(i1) = subject + i1/10;
    Subject(i1) = subject;
    AIM(i1) = aim;
    Date{i1} = datestr(floor(analysisStartTime(i1)),dateFormat);
    
    patch([analysisStartTime(i1),analysisStartTime(i1),...
            analysisEndTime(i1),analysisEndTime(i1)],...
            [0,maxActi,maxActi,0],'r','FaceAlpha',.5);
    
    try
        param = fullSleepAnalysis(Time,Activity,...
                analysisStartTime(i1),analysisEndTime(i1),...
                bedTimes(i1),wakeTimes(i1),'auto');
    catch err
        display(err.message);
        %display(err.stack);
        continue;
    end
        
    ActualSleep{i1} = param.actualSleepTime;
    ActualSleepPercent{i1} = param.actualSleepPercent;
    ActualWake{i1} = param.actualWakeTime;
    ActualWakePercent{i1} = param.actualWakePercent;
    SleepEfficiency{i1} = param.sleepEfficiency;
    Latency{i1} = param.sleepLatency;
    SleepBouts{i1} = param.sleepBouts;
    WakeBouts{i1} = param.wakeBouts;
    MeanSleepBout{i1} = param.meanSleepBoutTime;
    MeanWakeBout{i1} = param.meanWakeBoutTime;
    
    clear param;
end

saveas(gcf,['plots',filesep,'sub',num2str(subject),'_AIM',num2str(aim),'_',datestr(analysisStartTime(1),'yyyy-mm-dd'),'.png']);
hold off;

end