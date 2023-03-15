function theTable = preprocessIssues(theTable)
% Make an issues table conducive for baselining via a few small tweaks

% Make the Full Filenames in the table Relative
varNames = theTable.Properties.VariableNames;
varNames{varNames == "FullFilename"} = 'RelativeFilename';
theTable.Properties.VariableNames = varNames;
theTable.RelativeFilename = replace(theTable.RelativeFilename, string(pwd)+filesep, "");
theTable = movevars(theTable,"RelativeFilename",'Before',1);

% Remove the Location, which can have links/references to full paths
theTable.Location = [];

% Convert the Severity to categorical, which serializes nicely to string
theTable.Severity = categorical(theTable.Severity);
end