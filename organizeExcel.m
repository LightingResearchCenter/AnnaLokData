function organizeExcel(inputFile)
%ORGANIZEEXCEL Organize input data and save to Excel
%   Format for Mariana
load(inputFile);
saveFile = regexprep(inputFile,'\.mat','\.xlsx');
inputData = struct2dataset(output);
clear output;

%% Determine variable names
varNames = get(inputData,'VarNames');
% Remove line from varNames
varNameIdx = strcmpi(varNames,'line');
varNames(varNameIdx) = [];
% Count the number of variables
varCount = length(varNames);

%% Create header labels
% Prepare first header row
AIM0Txt = 'baseline (0)';
AIM1Txt = 'intervention (1)';
AIM2Txt = 'post intervention (2)';
spacer = cell(1,varCount-1);
header1 = [{[]},{[]},AIM0Txt,spacer,{[]},AIM1Txt,spacer,{[]},AIM2Txt,spacer]; % Combine parts of header1

% Prepare second header row
% Make variable names pretty
prettyNames = lower(regexprep(varNames,'([^A-Z])([A-Z])','$1 $2'));
header2 = [{'line'},{[]},prettyNames,{[]},prettyNames,{[]},prettyNames];

% Combine headers
header = [header1;header2];

%% Organize data
% Seperate subject and AIM from rest of inputData
inputData1 = dataset;
inputData1.line = inputData.line;
inputData1.AIM = inputData.AIM;

% Copy inputData and remove subject and AIM
inputData2 = inputData;
inputData2.line = [];

% Convert inputData2 to cells
inputData2Cell = dataset2cell(inputData2);
inputData2Cell(1,:) = []; % Remove variable names

% Identify unique subject numbers
line = unique(inputData1.line);

% Organize subject data by AIM
nRows = numel(line);
nColumns = numel(header2);
outputData1 = cell(nRows,nColumns);

aim0start = 3;
aim0end = aim0start + varCount - 1;

aim1start = aim0end + 2;
aim1end = aim1start + varCount - 1;

aim2start = aim1end + 2;
aim2end = aim2start + varCount - 1;

for i1 = 1:nRows
    % Subject number
    outputData1{i1,1} = line(i1);
    % AIM 0
    idx0 = inputData1.line == line(i1) & inputData2.AIM == 0;
    if sum(idx0) == 1
        outputData1(i1,aim0start:aim0end) = inputData2Cell(idx0,:);
    end
    % AIM 1
    idx1 = inputData1.line == line(i1) & inputData2.AIM == 1;
    if sum(idx1) == 1
        outputData1(i1,aim1start:aim1end) = inputData2Cell(idx1,:);
    end
    % AIM 2
    idx2 = inputData1.line == line(i1) & inputData2.AIM == 2;
    if sum(idx2) == 1
        outputData1(i1,aim2start:aim2end) = inputData2Cell(idx2,:);
    end
end


%% Combine headers and data
output1 = [header;outputData1];

%% Write to file
xlswrite(saveFile,output1); % Create sheet1

end

