global folder;

n_iterations = 20; % Does this include the seed points? It should.

peak_timing = optimizableVariable('peak_timing', [15.0, 40.0]);
offset_timing = optimizableVariable('offset_timing', [30.0, 55.0]);

constraint = @xconstraint;
fun = @MBBCObjective;

subjects = [1:4, 6:8];

for subject = subjects
    
    folder = ['D:\Dropbox\PhD\MBBC\Testing\S' num2str(subject)]; 

    results = bayesopt(fun, [peak_timing, offset_timing], ...
        'XConstraintFcn', constraint, ...
        'AcquisitionFunctionName', 'expected-improvement', ...
        'NumSeedPoints', 6, ...
        'MaxObjectiveEvaluations', n_iterations, ...
        'IsObjectiveDeterministic', true, ...
        'OutputFcn', @saveToFile, ...
        'SaveFileName', [folder filesep 'MBBC.mat']);
    
end