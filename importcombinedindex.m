function datasetout = importcombinedindex(workbookFile,sheetName,startRow,endRow)
%IMPORTCOMBINEDINDEX Import data from a spreadsheet
%   DATA = IMPORTCOMBINEDINDEX(FILE) reads data from the first worksheet in
%   the Microsoft Excel spreadsheet file named FILE and returns the data as
%   a dataset array.
%
%   DATA = IMPORTCOMBINEDINDEX(FILE,SHEET) reads from the specified worksheet.
%
%   DATA = IMPORTCOMBINEDINDEX(FILE,SHEET,STARTROW,ENDROW) reads from the specified
%   worksheet for the specified row interval(s). Specify STARTROW and
%   ENDROW as a pair of scalars or vectors of matching size for
%   dis-contiguous row intervals. To read to the end of the file specify an
%   ENDROW of inf.
%
%	Date formatted cells are converted to MATLAB serial date number format
%	(datenum).
%   Non-numeric cells are replaced with: NaN
%
% Example:
%   combinedIndex = importcombinedindex('combinedIndex.xlsx','Sheet1',2,34);
%
%   See also XLSREAD.

% Auto-generated by MATLAB on 2014/05/23 10:03:17

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 3
    startRow = 2;
    endRow = 26;
end

%% Import the data, extracting spreadsheet dates in MATLAB serial date number format (datenum)
[~, ~, raw, dateNums] = xlsread(workbookFile, sheetName, sprintf('A%d:K%d',startRow(1),endRow(1)),'' , @convertSpreadsheetDates);
for block=2:length(startRow)
    [~, ~, tmpRawBlock,tmpDateNumBlock] = xlsread(workbookFile, sheetName, sprintf('A%d:K%d',startRow(block),endRow(block)),'' , @convertSpreadsheetDates);
    raw = [raw;tmpRawBlock]; %#ok<AGROW>
    dateNums = [dateNums;tmpDateNumBlock]; %#ok<AGROW>
end
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
cellVectors = raw(:,[3,5]);
raw = raw(:,[1,2,4,6,7,8,9,10,11]);
dateNums = dateNums(:,[1,2,4,6,7,8,9,10,11]);

%% Replace date strings by MATLAB serial date numbers (datenum)
R = ~cellfun(@isequalwithequalnans,dateNums,raw) & cellfun('isclass',raw,'char'); % Find spreadsheet dates
raw(R) = dateNums(R);

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
data = reshape([raw{:}],size(raw));

%% Create dataset array
datasetout = dataset;

%% Allocate imported array to column variable names
datasetout.subject = data(:,1);
datasetout.condition = data(:,2);
datasetout.conditionName = cellVectors(:,1);
datasetout.SN = data(:,3);
datasetout.file = cellVectors(:,2);
datasetout.startTime = data(:,4);
datasetout.stopTime = data(:,5);
datasetout.removeStart = data(:,6);
datasetout.removeStop = data(:,7);
datasetout.bedTime = data(:,8);
datasetout.getupTime = data(:,9);

