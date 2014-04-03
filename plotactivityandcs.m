function plotactivityandcs(filePath,timeArray,activityArray,csArray,subject,week)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

titleLine1 = ['Subject ',num2str(subject),'  Week ',num2str(week)];
titleLine2 = [datestr(timeArray(1),'yyyy-mm-dd HH:MM'),' to ',datestr(timeArray(end),'yyyy-mm-dd HH:MM')];
titleArray = {titleLine1;titleLine2};

plot(timeArray(:),[smooth(activityArray(:)),smooth(csArray(:))]);

datetick2('KeepLimits');

legend('activity','circadian stimulus');

title(titleArray);

hold('off');

saveas(gcf,filePath);
clf;

end

