function plan = buildfile

plan = buildplan(localfunctions);

plan("test").Dependencies = ["mex", "setup"];

plan.DefaultTasks = "test";
end