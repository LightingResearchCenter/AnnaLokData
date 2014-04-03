function organizephasorexcel(inputFile)
%ORGANIZEEXCEL Organize input data and save to Excel
%   Format for Mariana
load(inputFile);
saveFile = regexprep(inputFile,'\.mat','\.xlsx');

flatOut = cat(1,output{:});
% Determine variable names
varNames = fieldnames(flatOut)';

% Flatten nested data and convert to dataset
tempDataset = struct2dataset(flatOut);
dataCell = dataset2cell(tempDataset);
dataCell(1,:) = [];

%% Create header labels
% Remove week from varNames
weekIdx = strcmpi(varNames,'week');
varNames(weekIdx) = [];
% Count the number of variables
varCount = length(varNames);
% Make variable names pretty
prettyNames = lower(regexprep(varNames,'([^A-Z])([A-Z0-9])','$1 $2'));

% Prepare first header row
wk0Txt = 'Week 0 - Baseline';
wk1Txt = 'Week 1 - Intervention';
wk2Txt = 'Week 2 - Post Intervention';
spacer = cell(1,varCount-1);
header1 = [wk0Txt,spacer,{[]},wk1Txt,spacer,{[]},wk2Txt,spacer]; % Combine parts of header1

% Prepare second header row
header2 = [prettyNames,{[]},prettyNames,{[]},prettyNames];

% Combine headers
header = [header1;header2];

%% Organize data
% Seperate line number and AIM from rest of inputData
subjectIdx = strcmpi(varNames,'subject');
subjectArray = cell2mat(dataCell(:,subjectIdx));
weekArray = cell2mat(dataCell(:,weekIdx));
% Remove line number from input data
dataCell(:,weekIdx) = [];

% Identify unique line numbers numbers
unqSub = unique(subjectArray);

% Organize data by AIM
nRows = numel(unqSub);
nColumns = numel(header2);
organizedData = cell(nRows,nColumns);

aim0start = 1;
aim0end = aim0start + varCount - 1;

aim1start = aim0end + 2;
aim1end = aim1start + varCount - 1;

aim2start = aim1end + 2;
aim2end = aim2start + varCount - 1;

for i1 = 1:nRows
    % AIM 0
    idx0 = subjectArray == unqSub(i1) & weekArray == 0;
    if sum(idx0) == 1
        organizedData(i1,aim0start:aim0end) = dataCell(idx0,:);
    end
    % AIM 1
    idx1 = subjectArray == unqSub(i1) & weekArray == 1;
    if sum(idx1) == 1
        organizedData(i1,aim1start:aim1end) = dataCell(idx1,:);
    end
    % AIM 2
    idx2 = subjectArray == unqSub(i1) & weekArray == 2;
    if sum(idx2) == 1
        organizedData(i1,aim2start:aim2end) = dataCell(idx2,:);
    end
end


%% Combine headers and data
newOutput = [header;organizedData];

%% Write to file
xlswrite(saveFile,newOutput); % Create sheet1

end

