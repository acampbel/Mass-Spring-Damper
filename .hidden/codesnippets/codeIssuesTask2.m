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
    % Load the baseline file
    opts = detectImportOptions("knownIssues.csv");
    types = varfun(@class, otherIssues,"OutputFormat","cell");
    opts.VariableTypes = types;
    knownIssues = readtable("knownIssues.csv",opts);

    % Find the new warnings by subtracting the known issues in the baseline
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