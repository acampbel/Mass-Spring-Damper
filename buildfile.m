function plan = buildfile

plan = buildplan(localfunctions);

plan("test").Dependencies = ["mex", "pcode","setup"];
plan("toolbox").Dependencies = ["lint", "test", "doc"];

plan("rerunFailed").Dependencies = "pcode";

plan("doc").Dependencies = "docTest";
plan("docTest").Dependencies = "setup";

plan("install").Dependencies = "integTest";
plan("integTest").Dependencies = "toolbox";

plan("lintAll") = matlab.buildtool.Task("Description","Find code issues in source and tests");
plan("lintAll").Dependencies = ["lint", "lintTests"];

plan.DefaultTasks = "integTest";
end

function setupTask(context)
% Setup paths for the build
addpath(fullfile(context.Plan.RootFolder,"toolbox"));
addpath(fullfile(context.Plan.RootFolder,"toolbox","doc"));
end

function lintTask(~)
% Find static code issues

issues = codeIssues(["toolbox", "pcode"]);
if ~isempty(issues.Issues)
    disp(formattedDisplayText(issues.Issues,"SuppressMarkup",true));
    disp("Detected code issues in source")
end
if ~isempty(issues.SuppressedIssues)
    disp(formattedDisplayText(issues.SuppressedIssues,"SuppressMarkup",true));
    disp("Detected suppressed issues in source")
end
end

function mexTask(~)
% Compile mex files

mex mex/convec.c -outdir toolbox/;
end

function docTask(~)
% Generate the doc pages
connector.internal.startConnectionProfile("loopbackHttps");
com.mathworks.matlabserver.connector.api.Connector.ensureServiceOn();

export("toolbox/doc/GettingStarted.mlx","toolbox/doc/GettingStarted.html");
end

function docTestTask(~)
% Test the doc and examples

results = runtests("tests/doc");
disp(results);
assertSuccess(results);
end

function testTask(~)
% Run the unit tests

results = runtests("tests");
save("toolbox/test-results.mat", "results");
disp(results);
assertSuccess(results);
end

function lintTestsTask(~)
% Find code issues in test code 

issues = codeIssues("tests");
if ~isempty(issues.Issues)
    disp(formattedDisplayText(issues.Issues,"SuppressMarkup",feature("hotlinks")));
    disp("Detected code issues in tests")
end
if ~isempty(issues.SuppressedIssues)
    disp(formattedDisplayText(issues.SuppressedIssues,"SuppressMarkup",feature("hotlinks")));
    disp("Detected suppressed issues in tests")
end
end

function toolboxTask(~)
% Create an mltbx toolbox package
dir toolbox/*.mex*
matlab.addons.toolbox.packageToolbox("Mass-Spring-Damper.prj","release/Mass-Spring-Damper.mltbx");
end

function pcodeTask(context)
% Obfuscate m-files

% Grab the help text for the pcoded function to generate a help-only m-file
mfile = "pcode/springMassDamperDesign.m";

helpText = deblank(string(help(mfile)));
helpText = split(helpText,newline);
helpText = replaceBetween(helpText, 1, 1, "%"); % Add comment symbols

% Write the file
fid = fopen("toolbox/springMassDamperDesign.m","w");
closer = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", helpText);

% Now pcode the file
startDir = cd("toolbox/");
cleaner = onCleanup(@() cd(startDir));
pcode(fullfile(context.Plan.RootFolder,"pcode/springMassDamperDesign.m"));

end

function cleanTask(~)
% Clean all derived artifacts

derivedFiles = [...
    "toolbox/springMassDamperDesign.m"
    "toolbox/springMassDamperDesign.p"
    "toolbox/convec." + mexext
    "toolbox/doc/GettingStarted.html"
    "release/Mass-Spring-Damper.mltbx"
    ];

arrayfun(@deleteFile, derivedFiles);
end

function integTestTask(~)
% Run integration tests

import matlab.addons.toolbox.installToolbox;
import matlab.addons.toolbox.uninstallToolbox;

sourceFile = which("simulateSystem");

% Remove source
sourcePaths = cellstr(fullfile(pwd, ["toolbox", "toolbox" + filesep + "doc"]));
origPath = rmpath(sourcePaths{:});
pathCleaner = onCleanup(@() path(origPath));

% Install Toolbox
tbx = installToolbox("release/Mass-Spring-Damper.mltbx");
tbxCleaner = onCleanup(@() uninstallToolbox(tbx));

assert(~strcmp(sourceFile,which("simulateSystem")), ...
    "Did not setup integ environment toolbox correctly");

results = runtests("tests","IncludeSubfolders",true);
disp(results);
assertSuccess(results);

clear pathCleaner tbxCleaner;
assert(strcmp(sourceFile,which("simulateSystem")), ...
    "Did not restore integ environment correctly");

end

function installTask(~)
% Install the toolbox locally
matlab.addons.toolbox.installToolbox("release/Mass-Spring-Damper.mltbx");
end

function rerunFailedTask(~)
rerunFailedTests("artifact.zip");
end


function deleteFile(file)
if exist(file,"file")
    delete(file);
end
end

