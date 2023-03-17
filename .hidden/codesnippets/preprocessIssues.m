function theTable = preprocessIssues(theTable)
% Make an issues table conducive for baselining via a few small tweaks

% Overwrite the location field with relative paths, and remove absolute paths
basePath = string(pwd) + filesep;
theTable.Location = erase(theTable.FullFilename, basePath);
theTable.Properties.VariableNames{"Location"} = 'RelativeFilename';
theTable.FullFilename = [];

% Convert the Severity to categorical, which serializes nicely to string
theTable.Severity = categorical(theTable.Severity);

end