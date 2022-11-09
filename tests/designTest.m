function tests = designTest
tests = functiontests(localfunctions); 
end

function testSettlingTime(testCase) 
%%Test that the system settles to within 0.001 of zero under 2 seconds.

[position, time] = simulateSystem(springMassDamperDesign); 

positionAfterSettling = position(time > 2);


verifyEqual(testCase, positionAfterSettling, repmat(0,size(positionAfterSettling)), 'AbsTol', .001,...
    "Settling time violation. MAximum settling time is 2 seconds.");
end

function testOvershoot(testCase)
 %Test to ensure that overshoot is less than 0.01

[position, ~] = simulateSystem(springMassDamperDesign);
overshoot = max(position);

verifyLessThan(testCase, overshoot, 0.01, "Overshoot violation! Maximum overshoot is 0.01");
end

function testInvalidInput(testCase)
% Test to ensure we fail gracefully with bogus input

testCase.verifyError(@() simulateSystem('bunk'), ...
   'simulateSystem:InvalidDesign:ShouldBeStruct');
end



