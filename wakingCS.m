function meanWakingCS = wakingCS(Time,CS,Activity,bedTime,wakeTime)
%WAKINGCS Summary of this function goes here
%   Detailed explanation goes here

addpath('sleepAnalysis');

Activity = gaussian(Activity,4);

%% Vectorize bed times and wake times
startDays = floor(min(Time));
bedTime = startDays + bedTime;
if bedTime > wakeTime
    wakeTime = startDays + 1 + wakeTime;
else
    wakeTime = startDays + wakeTime;
end

wakeTrim = Time <= bedTime | Time >= wakeTime;
wakeActivityAvg = mean(Activity(wakeTrim));

% Find sleep state, 1 = sleeping, 0 = not sleeping
sleepState = FindSleepState(Activity, wakeActivityAvg ,0.888);

% Find if in bed, 1 = in bed, 0 = not in bed
if bedTime > wakeTime % In bed through midnight
    inBed = mod(Time,1) >= bedTime | mod(Time,1) <= wakeTime;
else % Not in bed through midnight
    inBed = mod(Time,1) >= bedTime & mod(Time,1) <= wakeTime;
end

% Find instances where asleep in bed
idx = inBed & sleepState;

% Calcualte mean CS while awake
meanWakingCS = mean(CS(~idx));

end

