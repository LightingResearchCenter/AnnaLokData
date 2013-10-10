function organizeExcel(inputFile)
%ORGANIZEEXCEL Organize input data and save to Excel
%   Format for Mariana
load(inputFile);
saveFile = regexprep(inputFile,'\.mat','\.xlsx');
inputData = output;
clear output;

%% Determine variable names
varNames = get(inputData,'VarNames');
% Remove subject, AIM, and season from varNames
varNameIdx = strcmpi(varNames,'subject') | strcmpi(varNames,'AIM');
varNames(varNameIdx) = [];
% Count the number of variables
varCount = length(varNames);

%% Create header labels
% Prepare first header row
AIM0Txt = 'baseline (0)';
AIM0Mat = repmat(AIM0Txt,varCount,1);
AIM0Head =  mat2cell(AIM0Mat,ones(1,varCount),length(AIM0Txt))';

AIM1Txt = 'intervention (1)';
AIM1Mat = repmat(AIM1Txt,varCount,1);
AIM1Head =  mat2cell(AIM1Mat,ones(1,varCount),length(AIM1Txt))';

AIM2Txt = 'post intervention (2)';
AIM2Mat = repmat(AIM2Txt,varCount,1);
AIM2Head =  mat2cell(AIM2Mat,ones(1,varCount),length(AIM2Txt))';

header1 = [{[]},AIM0Head,AIM1Head,AIM2Head]; % Combine parts of header1

% Prepare second header row
header2 = [{'subject'},varNames,varNames,varNames];

% Combine headers
header = [header1;header2];

%% Organize data
% Seperate subject and AIM from rest of inputData
inputData1 = dataset;
inputData1.subject = inputData.subject;
inputData1.AIM = inputData.AIM;

% Copy inputData and remove subject and AIM
inputData2 = inputData;
inputData2.subject = [];
inputData2.AIM = [];

% Convert inputData2 to cells
inputData2Cell = dataset2cell(inputData2);
inputData2Cell(1,:) = []; % Remove variable names

% Identify unique subject numbers
subject = unique(inputData1.subject);

% Organize patient data by AIM
nSubjects = length(subject);
outputData1 = cell(nSubjects,varCount*3+1);
for i1 = 1:nSubjects
    % Subject number
    outputData1{i1,1} = subject(i1);
    % AIM 0
    idx0 = inputData1.subject == subject(i1) & inputData1.AIM == 0;
    if sum(idx0) == 1
        outputData1(i1,2:varCount+1) = inputData2Cell(idx0,:);
    end
    % AIM 1
    idx1 = inputData1.subject == subject(i1) & inputData1.AIM == 1;
    if sum(idx1) == 1
        outputData1(i1,varCount+2:varCount*2+1) = inputData2Cell(idx1,:);
    end
    % AIM 2
    idx2 = inputData1.subject == subject(i1) & inputData1.AIM == 2;
    if sum(idx2) == 1
        outputData1(i1,varCount*2+2:varCount*3+1) = inputData2Cell(idx2,:);
    end
end


%% Combine headers and data
output1 = [header;outputData1];

%% Create Excel file and write output to appropriate sheet
% Set sheet names
sheet1 = 1;
% Write to file
xlswrite(saveFile,output1,sheet1); % Create sheet1

end

