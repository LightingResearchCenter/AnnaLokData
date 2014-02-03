function [ActualSleep,ActualSleepPercent,...
    ActualWake,ActualWakePercent,SleepEfficiency,Latency,SleepBouts,...
    WakeBouts,MeanSleepBout,MeanWakeBout] = ...
    CalcSleepParams(Activity,Time,bedTime,wakeTime)
%CALCSLEEPPARAMS Calculate sleep parameters using Actiware method
%   Values and calculations are taken from Avtiware-Sleep
%   Version 3.4 documentation Appendix: A-1 Actiwatch Algorithm

Epoch = etime(datevec(Time(2)),datevec(Time(1))); % Find epoch length
n = ceil(300/Epoch); % Number of points in a 5 minute interval
serialEpoch = Epoch / 60 / 60 / 24;

%prevWakeTrim = Time >= prevWakeTime & Time <= bedTime;
wakeActivityAvg = mean(Activity);

% Trim Activity and Time to times within the Start and End of the analysis
% period
sleepTrim = Time >= bedTime - 113*serialEpoch & Time <= wakeTime;
Activity = Activity(sleepTrim);
kfActivity = kalmanFilter(Activity);

% Find the sleep state
sleepState = FindSleepState(kfActivity, wakeActivityAvg, .888);

sleepTrim = Time >= bedTime & Time <= wakeTime;
Time = Time(sleepTrim);

sleepStarts = [];
sleepEnds = [];
i = 1;
j = 1;

while i <= length(sleepState) - n*6 && j <= length(sleepState) - n*2
	% Find Sleep Start
	hasStart = true;
	while i <= length(sleepState) - n*6
		numSleepingPts = length(find(sleepState(i:i+n*6)));
		if numSleepingPts >= 0.9*(n*6)
			sleepStarts = [sleepStarts, Time(i)];
			break
		elseif i+1 == length(sleepState) - n*6
			hasStart = false;
            i = i+1;
		else
			i = i+1;
		end
	end
	
	if ~hasStart
		break;
	end

	% Find Sleep End
	j = i;
	while j < length(sleepState) - n*2
		numSleepingPts = length(find(sleepState(j:j+n*2)));
		if numSleepingPts <= 0.1*(n*2)
			sleepEnds = [sleepEnds, Time(j)];
			break
		elseif j+1 == length(sleepState) - n*2
			sleepEnds = [sleepEnds, Time(j+1)];
			break;
		else
			j = j+1;
		end
	end
	i = j;
end


%% Calculate the parameters
inBedSleeping = [];
for k = 1:length(sleepStarts)
	if k == 1
		inBedSleeping = Time >= sleepStarts(1) & Time <= sleepEnds(1);
	else
		inBedSleeping = inBedSleeping |...
			(Time >= sleepStarts(k) & Time <= sleepEnds(k));
	end
end
% Calculate Actual Sleep Time in minutes
ActualSleep = sum(sleepState(inBedSleeping))*Epoch/60;
% Calculate Actual Wake Time in minutes
ActualWake = sum(sleepState(inBedSleeping)==0)*Epoch/60;
% Calculate Assumed Sleep in minutes
AssumedSleep = ActualSleep + ActualWake;
% Calculate Actual Sleep Time Percentage
ActualSleepPercent = ActualSleep/AssumedSleep;
% Calculate Actual Wake Time Percentage
ActualWakePercent = ActualWake/AssumedSleep;
% Calculate Sleep Efficiency in minutes
TimeInBed = etime(datevec(wakeTime),datevec(bedTime))/60;
SleepEfficiency = ActualSleep/TimeInBed;
% Calculate Sleep Latency in minutes
Latency = etime(datevec(sleepStarts(1)),datevec(bedTime))/60;
% Find Sleep Bouts and Wake Bouts
SleepBouts = 0;
WakeBouts = 0;
for i = 2:length(sleepState)
    if sleepState(i) == 1 && sleepState(i-1) == 0
        SleepBouts = SleepBouts+1;
    end
    if sleepState(i) == 0 && sleepState(i-1) == 1
        WakeBouts = WakeBouts+1;
    end
end
% Calculate Mean Sleep Bout Time in minutes
if SleepBouts == 0
    MeanSleepBout = 0;
else
    MeanSleepBout = ActualSleep/SleepBouts;
end
% Claculate Mean Wake Bout Time in minutes
if WakeBouts == 0
    MeanWakeBout = 0;
else
    MeanWakeBout = ActualWake/WakeBouts;
end

end