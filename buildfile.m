function plan = buildfile

plan = buildplan(localfunctions);

plan("test").Dependencies = ["mex", "setup"];

plan.DefaultTasks = "test";
end

function setupTask(context)
% Setup path for the build
addpath(fullfile(context.Plan.RootFolder,"toolbox"));
end

function mexTask(~)
% Compile mex files

mex mex/convec.c -outdir toolbox/;
end

function testTask(~)
% Run the unit tests

results = runtests("tests");
disp(results);
assertSuccess(results);
end

