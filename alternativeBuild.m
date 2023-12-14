function plan = alternativeBuild

plan = buildplan(localfunctions);

plan("mex").Inputs = "mex/**/*.c";
plan("mex").Outputs = plan("mex").Inputs ....
    .replace("mex/","toolbox/") ...
    .replace(".c", "." + mexext);

plan("pcode").Inputs = "pcode/**/*.m";
plan("pcode").Outputs = plan("pcodeHelp").Inputs.replace("pcode/", "toolbox/").replace(".m", ".p");
plan("pcode").Dependencies = "pcodeHelp";

plan("pcodeHelp").Inputs = plan("pcode").Inputs;
plan("pcodeHelp").Outputs = plan("pcodeHelp").Inputs.replace("pcode/", "toolbox/");

plan("lint").Inputs = ["toolbox/**/*.m", "pcode/**/*.m"]; % Want to use this for finding files to operate on but dont want incremental

plan("test").Inputs = plan(["mex" "pcode"]);

plan("toolbox").Dependencies = ["lint", "test", "doc", "pcodeHelp"];
plan("toolbox").Inputs = ["pcode", "mex", "toolbox"];
plan("toolbox").Outputs = "release/*.mltbx";

plan("doc").Dependencies = "docTest";
plan("doc").Inputs = "toolbox/doc/**/*.mlx";
plan("doc").Outputs = "toolbox/doc/**/*.html";

plan("docTest").Inputs = [plan(["doc" "pcode"]), "test/doc/**/*.m"];

plan("install").Dependencies = "integTest";
plan("integTest").Dependencies = "toolbox";
plan("integTest").Inputs = ["toolbox", "tests"];

plan("lintAll") = matlab.buildtool.Task("Description","Find code issues in source and tests");
plan("lintAll").Dependencies = ["lint", "lintTests"];

plan.DefaultTasks = "integTest";
end