function plan = buildfile
import matlab.buildtool.tasks.*;

plan = buildplan(localfunctions);

plan("mex").Inputs = files(plan, "mex/**/*.c");
plan("mex").Outputs = files(plan, ...
    plan("mex").Inputs.paths ...
    .replace("mex/","toolbox/") ...
    .replace(".c", "." + mexext));

plan("pcode") = PcodeTask("pcode","toolbox");
%plan("pcode").Dependencies = "pcodeHelp";

plan("pcodeHelp").Inputs = "pcode/**/*.m";
plan("pcodeHelp").Outputs = plan("pcodeHelp").Inputs ...
    .replace("pcode/", "toolbox/");

plan("lint") = CodeIssuesTask(["toolbox/**/*.m", "pcode/**/*.m"]);
plan("lintTests") = CodeIssuesTask("tests");


plan("test") = TestTask("tests",SourceFiles=["toolbox","pcode"], ...
    TestResults="results/test-results/index.html",...
    CodeCoverageResults="results/coverage/index.html", ...
    Dependencies=["mex", "pcode"]);


plan("archiveResults").Dependencies = "test";
plan("archiveResults").Inputs = "results/*/";
plan("archiveResults").Outputs = transform(plan("archiveResults").Inputs,...
    @(p) p.replaceBetween(strlength(p),strlength(p), ".zip"));

plan("docTest") = TestTask("tests/doc",SourceFiles="toolbox/doc");

plan("toolbox").Dependencies = ["lint", "test", "doc", "pcodeHelp"];
plan("toolbox").Inputs = ["pcode", "mex", "toolbox", "ToolboxPackaging.prj"];
plan("toolbox").Outputs = "release/*.mltbx";

plan("doc").Dependencies = "docTest";
plan("doc").Inputs = "toolbox/doc/**/*.mlx";


plan("clean") = CleanTask;
%plan("doc").Outputs = plan("doc").Inputs.replace(".mlx",".html");

%plan("docTest").Inputs = [...
 %   plan("doc").Inputs, ...
  %  plan("pcode").Outputs, ...
   %  "test/doc/**/*.m"];

plan("integTest").Inputs = [...
    plan("toolbox").Outputs, ...
    "tests"];


plan("install").Dependencies = "integTest";

plan("lintAll") = matlab.buildtool.Task(...
    Description="Find code issues in source and tests",...
    Dependencies=["lint", "lintTests"]);

plan.DefaultTasks = "archiveResults";
end

function archiveResultsTask(cxt)
% Create ZIP file
subdirs = cxt.Task.Inputs.paths;

zipFiles = cxt.Task.Outputs.paths;

for idx = 1:numel(subdirs)
    zip(zipFiles(idx),subdirs(idx) + filesep + "*")
end
end


function mexTask(context)
% Compile mex files

inputs = context.Task.Inputs.paths;
outputs = context.Task.Outputs.paths;

for idx = 1:numel(inputs)
    thisInput = inputs(idx);
    thisOutput = outputs(idx);

    makeFolder(fileparts(thisOutput));

    disp("Building " + thisInput);

    mex(thisInput,"-output", thisOutput);
    disp(" ")
end
end

function docTask(context, options)
% Generate the doc pages

arguments
    context
    options.Env (1,:) string = "standard"
end

if options.Env == "ci"
    fprintf("Starting connector...");
    connector.internal.startConnectionProfile("loopbackHttps");
    com.mathworks.matlabserver.connector.api.Connector.ensureServiceOn();
    disp("Done");
end

docFiles = context.Inputs.paths;
for idx = 1:numel(docFiles)
    [thisPath, thisFile] = fileparts(docFiles(idx));
    exportedFile = fullfile(thisPath, thisFile + ".html");
    export(docFiles(idx), exportedFile);
end
end

function toolboxTask(~)
% Create an mltbx toolbox package
outputFile = "release/msd.mltbx";
disp("Packaging toolbox: " + outputFile);
matlab.addons.toolbox.packageToolbox("ToolboxPackaging.prj",outputFile);

end

function pcodeHelpTask(context)
% Extract help text for p-coded m-files

outputPaths = context.Task.Outputs.paths;

for idx = 1:numel(context.Task.Inputs.paths)

    % Grab the help text for the pcoded function to generate a help-only m-file
    mfile = context.Task.Inputs.paths{idx};

    helpText = deblank(string(help(mfile)));
    helpText = split(helpText,newline);
    if helpText == ""
        disp("No help text to extract for " + mfile);
    else
        disp("Extracting help for for " + mfile);
        helpText = replaceBetween(helpText, 1, 1, "%"); % Add comment symbols

        % Write the file
        folder = fileparts(outputPaths(idx));
        makeFolder(folder);

        fid = fopen(outputPaths(idx),"w");
        closer = onCleanup(@() fclose(fid));
        fprintf(fid, "%s\n", helpText);
    end
end
end


function makeFolder(folder)
if exist(folder,"dir")
    return
end
disp("Creating """ + folder + """ folder");
mkdir(folder);
end


function integTestTask(ctx)
% Run integration tests

sourceFile = which("simulateSystem");

% Remove source
sourcePaths = cellstr(fullfile(pwd, ["toolbox", "toolbox" + filesep + "doc"]));
origPath = rmpath(sourcePaths{:});
pathCleaner = onCleanup(@() path(origPath));

% Install Toolbox

tbx = matlab.addons.toolbox.installToolbox(ctx.Inputs(1).paths);
tbxCleaner = onCleanup(@() matlab.addons.toolbox.uninstallToolbox(tbx));

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




