function codeIssuesTask(~)
% Get all the issues under toolbox
allIssues = codeIssues("toolbox");

% Assert that no errors creep into the codebase
errorIdx = allIssues.Issues.Severity == "error";
errors = allIssues.Issues(errorIdx,:);
otherIssues = allIssues.Issues(~errorIdx,:);
if ~isempty(errors)
    disp("Found critical errors in code:");
    disp(errors);
else
    disp("No critical errors found.");
end

% Display all the other issues
if ~isempty(otherIssues)
    disp("Other Issues:")
    disp(otherIssues);
else
    disp("No other issues found either. (wow, good for you!)")
end

assert(isempty(errors));
end