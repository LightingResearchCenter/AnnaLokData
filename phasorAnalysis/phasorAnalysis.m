function output = phasorAnalysis(time, CS, activity, subject, week)
%PHASORANALYSIS Performs analysis on CS and activity

%% Process and analyze data
epoch = round(mode(diff(time))*24*3600*1000)/1000;
Srate = 1/epoch; % sample rate in Hertz
% Calculate inter daily stability and variablity
[IS,IV] = IS_IVcalc(activity,epoch);

% Apply gaussian filter to data
window = ceil(300/epoch);
CS = gaussian(CS, window);
activity = gaussian(activity, window);

% Calculate phasors
[phasorMagnitude, phasorAngle] = cos24(CS, activity, time);
[f24H,f24] = phasor24Harmonics(CS,activity,Srate); % f24H returns all the harmonics of the 24-hour rhythm (as complex numbers)
MagH = sqrt(sum((abs(f24H).^2))); % the magnitude including all the harmonics

mCS = mean(CS(CS>0));
f24abs = abs(f24);

%% Assign output

output = struct;
output.subject = subject;
output.week = week;
output.phasorMagnitude = phasorMagnitude;
output.phasorAngle = phasorAngle;
output.magnitudeWithHarmonics = MagH;
output.magnitudeFirstHarmonic = f24abs;
output.interdailyStability = IS;
output.intradailyVariability = IV;
output.meanNonzeroCS = mCS;

end
