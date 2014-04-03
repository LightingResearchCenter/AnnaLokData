function plotactivity(filePath,timeArray,activityArray,bedTimeArray,getupTimeArray,subject,week)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

titleLine1 = ['Subject ',num2str(subject),'  Week ',num2str(week)];
titleLine2 = [datestr(timeArray(1),'yyyy-mm-dd HH:MM'),' to ',datestr(timeArray(end),'yyyy-mm-dd HH:MM')];
titleArray = {titleLine1;titleLine2};

maxY = max(activityArray);
nNights = numel(bedTimeArray);
hold('on');
for i1 = 1:nNights
    xArray = [bedTimeArray(i1),bedTimeArray(i1),...
        getupTimeArray(i1),getupTimeArray(i1)];
    yArray = [0,maxY,maxY,0];
    zArray = [-10,-10,-10,-10];
    faceColor = [184,213,255]/255;
    
    h = patch(xArray,yArray,zArray,1,'FaceColor',faceColor,'EdgeColor','none');
    
%     set(h,'FaceAlpha',0.5);
end

plot(timeArray,smooth(activityArray),'-k');

datetick2('KeepLimits');

title(titleArray);

hold('off');

saveas(h,filePath);
clf;

end

