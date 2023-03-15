function plan = buildfile
plan = buildplan(localfunctions);

plan("test").Dependencies = "mex";
plan.DefaultTasks = ["codeIssues" "test"];
end

function mexTask(~)
% Compile mex files
mex mex/convec.c -outdir toolbox/;
end

function testTask(~)
% Run the unit tests
results = runtests;
disp(results);
assertSuccess(results);
end

function codeIssuesTask(~)
% Get all the issues under toolbox
allIssues = codeIssues("toolbox");

% Assert that no errors creep into the codebase
errorIdx = allIssues.Issues.Severity == "error";
errors = allIssues.Issues(errorIdx,:);
otherIssues = allIssues.Issues(~errorIdx,:);
if ~isempty(errors)
    disp("Failed! Found critical errors in code:");
    disp(errors);
else
    disp("No critical errors found.");
end


otherIssues = preprocessIssues(otherIssues);
% Load the the known warnings baseline
newWarnings = [];
if isfile("knownIssues.csv")
    opts = detectImportOptions("knownIssues.csv");
    types = varfun(@class, otherIssues,"OutputFormat","cell");
    opts.VariableTypes = types;
    knownIssues = readtable("knownIssues.csv",opts);

    otherIssues = setdiff(otherIssues, knownIssues);
    newWarningIdx = otherIssues.Severity == "warning";
    newWarnings = otherIssues(newWarningIdx,:);
    if ~isempty(newWarnings)
        disp("Failed! Found new warnings in code:");
        disp(newWarnings);
    else
        disp("No new warnings found.");
    end

    otherIssues = [knownIssues; otherIssues(~newWarningIdx,:)];
end

% Display all the other issues
if ~isempty(otherIssues)
    disp("Other Issues:")
    disp(otherIssues);
else
    disp("No other issues found either. (wow, good for you!)")
end

assert(isempty(errors));
assert(isempty(newWarnings));
end

function captureWarningsBaselineTask(~)
% Captures the current codeIssues warnings and creates a baseline csv file
allIssues = codeIssues("toolbox");
warningIdx = allIssues.Issues.Severity == "warning";
warnings = allIssues.Issues(warningIdx,:);

warnings =  preprocessIssues(warnings);
if ~isempty(warnings)
    disp("Saving a new ""knownIssues.csv"" baseline file for code warnings")
    writetable(warnings, "knownIssues.csv");
else
    disp("No warnings to create a baseline for")
end

end



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
theTable.Severity = categorical(string(theTable.Severity));
end

