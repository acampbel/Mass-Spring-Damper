function captureWarningsBaselineTask(~)
% Captures the current codeIssues warnings and creates a baseline csv file
allIssues = codeIssues("toolbox");
warningIdx = allIssues.Issues.Severity == "warning";
warnings = allIssues.Issues(warningIdx,:);

warnings = prepIssuesForBaseline(warnings);
if ~isempty(warnings)
    disp("Saving a new ""knownIssues.csv"" baseline file for code warnings")
    writetable(warnings, "knownIssues.csv");
else
    disp("No warnings to create a baseline for")
end

end