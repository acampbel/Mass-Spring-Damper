function tests = failTest
tests = functiontests(localfunctions);
end

function testSuccess(testCase)
testCase.verifyTrue(true);
end

function testFailure(testCase)
testCase.verifyTrue(true);
end