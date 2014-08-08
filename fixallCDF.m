function fixallCDF
%FIXALLCDF Summary of this function goes here
%   Detailed explanation goes here
[githubDir,~,~] = fileparts(pwd);
cdfPath = fullfile(githubDir,'LRC-CDFtoolkit');
addpath(cdfPath);

projectDir = fullfile([filesep,filesep],'root','projects','NIH Alzheimers',...
    'Aim 3 Local (AnnaLokData)');
originalDir = fullfile(projectDir,'originalCdfData');
reprocessedDir = fullfile(projectDir,'reprocessedCdfData');

[cdfNameArray, cdfPathArray]  = searchdir(originalDir,'.cdf');

for i1 = 1:numel(cdfNameArray)
    reprocesscdf(cdfPathArray{i1},false,reprocessedDir);
end

end

