function testTask(~)
% Run the unit tests

results = runtests("tests");
disp(results);
assertSuccess(results);
end