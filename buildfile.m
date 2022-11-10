function plan = buildfile

plan = buildplan(localfunctions);

plan("mex").Inputs = files(plan, "mex/**/*.c");
plan("mex").Outputs = files(plan, ...
    plan("mex").Inputs.paths ...
    .replace("mex/","toolbox/") ...
    .replace(".c", "." + mexext));

plan("pcode").Inputs = files(plan, "pcode/**/*.m");
plan("pcode").Outputs = files(plan, ...
    plan("pcode").Inputs.paths ...
    .replace("pcode/","toolbox/") ...
    .replace(".m",".p"));

plan("pcode").Dependencies = "pcodeHelp";

plan("pcodeHelp").Inputs = plan("pcode").Inputs;
plan("pcodeHelp").Outputs = files(plan, ...
    plan("pcodeHelp").Inputs.paths ...
    .replace("pcode/", "toolbox/"));

plan("lint").Inputs = files(plan, ["toolbox/**/*.m", "pcode/**/*.m"]);

plan("test").Inputs = [...
    plan("mex").Outputs, ...
    plan("pcode").Outputs, ...
    files(plan, "toolbox/**/*.m")];

plan("toolbox").Dependencies = ["lint", "test", "doc", "pcodeHelp"];
plan("toolbox").Inputs = files(plan, ["pcode", "mex", "toolbox", "Mass-Spring-Damper.prj"]);
plan("toolbox").Outputs = files(plan, "release/*.mltbx");

plan("doc").Dependencies = "docTest";
plan("doc").Inputs = files(plan, "toolbox/doc/**/*.mlx");
plan("doc").Outputs = files(plan, plan("doc").Inputs.paths ...
    .replace(".mlx",".html"));

plan("docTest").Inputs = [...
    plan("doc").Inputs, ...
    plan("pcode").Outputs, ...
    files(plan, "test/doc/**/*.m")];

plan("install").Dependencies = "integTest";
plan("integTest").Dependencies = "toolbox";
plan("integTest").Inputs = files(plan, ["toolbox", "tests"]);

plan("lintAll") = matlab.buildtool.Task("Description","Find code issues in source and tests");
plan("lintAll").Dependencies = ["lint", "lintTests"];

plan.DefaultTasks = "integTest";
end


function lintTask(context)
% Find static codeIssues
lintFcn(fileparts(context.Inputs.paths));

end

function lintTestsTask(~)
% Find code issues in test code
lintFcn("tests");
end

function lintFcn(paths)
issues = codeIssues(paths);
errorIdx = issues.Issues.Severity == "error";
errors = issues.Issues(errorIdx,:);
disp("Errors:")
disp(formattedDisplayText(errors));
assert(isempty(errors), "Found critical errors in code." );
disp("Other Issues:")
disp(formattedDisplayText(issues.Issues(~errorIdx,:)));

if ~isempty(issues.SuppressedIssues)
    disp("Some issues were suppressed")
    disp(formattedDisplayText(groupsummary(issues.SuppressedIssues,"Severity"),"SuppressMarkup",feature("hotlinks")));
end

end

function loadTask(ctx)
% Load the project
matlab.project.loadProject(ctx.Plan.RootFolder);
end

function mexTask(context)
% Compile mex files

inputs = context.Inputs.paths;
outputs = context.Outputs.paths;

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

function docTestTask(~)
% Test the doc and examples

results = runtests("tests/doc");
disp(results);
assertSuccess(results);
end

function testTask(~)
% Run the unit tests

results = runtests("tests");
disp(results);
assertSuccess(results);
end


function toolboxTask(~)
% Create an mltbx toolbox package
outputFile = "release/Mass-Spring-Damper.mltbx";
disp("Packaging toolbox: " + outputFile);
matlab.addons.toolbox.packageToolbox("Mass-Spring-Damper.prj",outputFile);

end

function pcodeHelpTask(context)
% Extract help text for p-coded m-files

outputPaths = context.Outputs.paths;

for idx = 1:numel(context.Inputs.paths)

    % Grab the help text for the pcoded function to generate a help-only m-file
    mfile = context.Inputs.paths{idx};

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

function pcodeTask(context)
% Obfuscate m-files

startDir = pwd;
cleaner = onCleanup(@() cd(startDir));

srcFolders = unique(fileparts(context.Inputs.paths));
outFolders = unique(fileparts(context.Outputs.paths));

rootFolder = context.Plan.RootFolder;
for idx = 1:numel(srcFolders)
    disp("P-coding files in " + srcFolders(idx));
    % Now pcode the file
    outFolder = fullfile(rootFolder, outFolders(idx));
    srcFolder = fullfile(rootFolder, srcFolders(idx));

    makeFolder(outFolder);

    cd(outFolder);
    pcode(srcFolder);
end
end

function makeFolder(folder)
if exist(folder,"dir")
    return
end
disp("Creating """ + folder + """ folder");
mkdir(folder);
end

function cleanTask(ctx, task)
% Clean all derived artifacts

arguments
    ctx
    task (1,:) string = missing;
end

if ismissing(task)
    outputs = [ctx.Plan.Tasks.Outputs];
    v = extract(string(version), textBoundary + digitsPattern + "." + digitsPattern + "." + digitsPattern + "." + digitsPattern);
    deleteFolders(fullfile(".buildtool",v));
else
    outputs = [ctx.Plan(task).Outputs];
end

deleteFiles(outputs.paths);

end

function integTestTask(~)
% Run integration tests

sourceFile = which("simulateSystem");

% Remove source
sourcePaths = cellstr(fullfile(pwd, ["toolbox", "toolbox" + filesep + "doc"]));
origPath = rmpath(sourcePaths{:});
pathCleaner = onCleanup(@() path(origPath));

% Install Toolbox

tbx = matlab.addons.toolbox.installToolbox("release/Mass-Spring-Damper.mltbx");
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


function deleteFiles(files)

arguments
    files string
end

for file = files(:).'
    if ~isempty(file) && exist(file,"file")
        disp("Deleting file: " + file);
        delete(file);
    end
end
end

function deleteFolders(folders)

arguments
    folders string;
end

oldWarn = warning("off",'MATLAB:RMDIR:RemovedFromPath');
cl = onCleanup(@() warning(oldWarn));

for folder = folders(:).'
    if exist(folder,"dir")
        disp("Deleting folder: " + folder);
        rmdir(folder, "s");
    end
end
end



