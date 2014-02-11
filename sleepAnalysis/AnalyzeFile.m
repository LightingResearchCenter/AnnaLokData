function [Subject,AIM,Date,ActualSleep,ActualSleepPercent,ActualWake,...
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

% Calculate Epoch to the nearest second
epoch = round(mean(diff(Time)*24*60*60));

nDays = length(bedTimes);

%% Preallocate sleep parameters
Subject = cell(nDays,1);
AIM = cell(nDays,1);
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
%% Call function to calculate sleep parameters for each day
for i1 = 1:nDays
    Subject{i1} = subject;
    AIM{i1} = aim;
    Date{i1} = datestr(floor(analysisStartTime(i1)),dateFormat);
    try
        param = fullSleepAnalysis(Time,Activity,epoch,...
                analysisStartTime(i1),analysisEndTime(i1),...
                bedTimes(i1),wakeTimes(i1),'auto');
    catch err
        display(err.message);
        %display(err.stack);
        continue;
    end
    
    if param.sleepEfficiency == 1
        plot(Time,Activity);
        hold on;
        patch([analysisStartTime(i1),analysisStartTime(i1),...
            analysisEndTime(i1),analysisEndTime(i1)],...
            [0,maxActi,maxActi,0],'r','FaceAlpha',.5);
            
        title({['Subject ',num2str(subject),' AIM ',num2str(aim)];...
            [datestr(analysisStartTime(i1),dateTimeFormat),' - ',datestr(analysisEndTime(i1),dateTimeFormat)]});
        datetick2;
        saveas(gcf,['sub',num2str(subject),'_AIM',num2str(aim),'_',datestr(analysisStartTime(i1),'dd-mm-yyyy'),'.png']);
%         display('Program paused. Press any key to continue.')
%         pause;
        hold off;
    end
    
    ActualSleep{i1} = m2hm(param.actualSleepTime);
    ActualSleepPercent{i1} = param.actualSleepPercent;
    ActualWake{i1} = m2hm(param.actualWakeTime);
    ActualWakePercent{i1} = param.actualWakePercent;
    SleepEfficiency{i1} = param.sleepEfficiency;
    Latency{i1} = m2hm(param.sleepLatency);
    SleepBouts{i1} = param.sleepBouts;
    WakeBouts{i1} = param.wakeBouts;
    MeanSleepBout{i1} = m2hms(param.meanSleepBoutTime);
    MeanWakeBout{i1} = m2hms(param.meanWakeBoutTime);
    
    clear param;
end

end