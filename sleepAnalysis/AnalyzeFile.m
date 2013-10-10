function [ActualSleep,ActualSleepPercent,ActualWake,...
    ActualWakePercent,SleepEfficiency,Latency,SleepBouts,WakeBouts,...
    MeanSleepBout,MeanWakeBout] = AnalyzeFile(Time,Activity,bedTime,wakeTime)

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

nDays = length(bedTimes);

%% Preallocate sleep parameters
dActualSleep = zeros(nDays,1);
dActualSleepPercent = zeros(nDays,1);
dActualWake = zeros(nDays,1);
dActualWakePercent = zeros(nDays,1);
dSleepEfficiency = zeros(nDays,1);
dLatency = zeros(nDays,1);
dSleepBouts = zeros(nDays,1);
dWakeBouts = zeros(nDays,1);
dMeanSleepBout = zeros(nDays,1);
dMeanWakeBout = zeros(nDays,1);
%% Call function to calculate sleep parameters for each day
for i = 1:nDays
    [~,~,dActualSleep(i),dActualSleepPercent(i),dActualWake(i),...
        dActualWakePercent(i),dSleepEfficiency(i),dLatency(i),...
        dSleepBouts(i),dWakeBouts(i),dMeanSleepBout(i),dMeanWakeBout(i)]...
        = CalcSleepParams(Activity,Time,bedTimes(i),wakeTimes(i));
end

%% Average the parameters
ActualSleep = mean(dActualSleep);
ActualSleepPercent = mean(dActualSleepPercent);
ActualWake = mean(dActualWake);
ActualWakePercent = mean(dActualWakePercent);
SleepEfficiency = mean(dSleepEfficiency);
Latency = mean(dLatency);
SleepBouts = mean(dSleepBouts);
WakeBouts = mean(dWakeBouts);
MeanSleepBout = mean(dMeanSleepBout);
MeanWakeBout = mean(dMeanWakeBout);
end