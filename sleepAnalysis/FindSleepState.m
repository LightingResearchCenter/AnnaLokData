function sleepState = FindSleepState(activity,threshold,f)
%SLEEPSTATE Calculate sleep state using LRC simple method

% Set Threshold value
if strcmpi(threshold,'auto')
    if min(activity) > 0
        threshold = min(activity)*f;
    else
        threshold = .03*f;
    end
end

% Make Activity array vertical
activity = activity(:);

% Calculate Sleep State 1 = sleeping 0 = not sleeping
sleepState = activity <= threshold;

end

