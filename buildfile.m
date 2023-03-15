function plan = buildfile

plan = buildplan(localfunctions);

plan("test").Dependencies = "mex";

plan.DefaultTasks = "test";
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

