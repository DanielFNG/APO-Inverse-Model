classdef DataTest < matlab.unittest.TestCase
    % Test cases for the Data class
    
    methods (Test)
        
        function testEquality(testCase)
            dataIn = Data('test-in.mot');
            copyIn = Data('test-in-copy.mot');
            noHeaderIn = Data('test-in-no-header.mot');
            noLabelsIn = Data('test-in-no-labels.mot');
            noValuesIn = Data('test-in-no-values.mot');
            actSolution = [dataIn.isEqual(copyIn) ...
                dataIn.isEqual(noHeaderIn) dataIn.isEqual(noLabelsIn) ...
                dataIn.isEqual(noValuesIn)];
            expSolution = [1 0 0 0];
            testCase.verifyEqual(actSolution,expSolution);
        end
        
    end
end

