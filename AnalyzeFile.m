function output = AnalyzeFile(subject,AIM,time,activity,bedTime,wakeTime)

%% Vectorize bed times and wake times
startDays = floor(min(time)):floor(max(time));
bedTimes = startDays + bedTime;
if bedTime > wakeTime
    wakeTimes = startDays + 1 + wakeTime;
else
    wakeTimes = startDays + wakeTime;
end

if bedTimes(end) > max(time) || wakeTimes(end) > max(time)
    bedTimes(end) = [];
    wakeTimes(end) = [];
end

if bedTimes(1) < min(time) || wakeTimes(1) < min(time)
    bedTimes(1) = [];
    wakeTimes(1) = [];
end

% Set analysis start and end times
analysisStartTime = bedTimes - 20/60/24;
analysisEndTime = wakeTimes + 20/60/24;

%% Plot the data and save to file
plotDir = '\\ROOT\projects\NIH Alzheimers\Aim 3 Local (AnnaLokData)\plots';
plotName = ['sub',num2str(subject,'%02.0f'),'_wk',num2str(AIM),'_',datestr(time(1),'yyyy-mm-dd'),'.png'];
plotPath = fullfile(plotDir,plotName);
plotactivity(plotPath,time,activity,bedTimes,wakeTimes,subject,AIM);

%% Preallocate sleep parameters
nNights = numel(bedTimes);

output = cell(nNights,1);

dateFormat = 'mm/dd/yyyy';

%% Call function to calculate sleep parameters for each day
for i1 = 1:nNights
    try
        output{i1} = sleepAnalysis(time,activity,...
                analysisStartTime(i1),analysisEndTime(i1),...
                bedTimes(i1),wakeTimes(i1),'auto');
        tempFields = fieldnames(output{i1})';
    catch err
        display(err.message);
        display(err.stack);
        tempFields = {};
    end
    
    
    output{i1}.line = subject + i1/10;
    output{i1}.subject = subject;
    output{i1}.AIM = AIM;
    output{i1}.date = datestr(floor(analysisStartTime(i1)),dateFormat,'local');
    
    output{i1} = orderfields(output{i1},[{'line','subject','AIM','date'},tempFields]);
end

end