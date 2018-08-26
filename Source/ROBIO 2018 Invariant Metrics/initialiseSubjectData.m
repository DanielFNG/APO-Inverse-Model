function result = initialiseSubjectData(subject)

weights = [0 0 0 0 0 0 0 57.7];
leg_lengths = [0 0 0 0 0 0 0 0.77];

% Note the reason for the rows of 0's - constant walking speed is only a
% thing at the steady state contexts!
walking_speeds = [0 0 0 0 0 0 0 0.5;...
    0 0 0 0 0 0 0 0.5;...
    0 0 0 0 0 0 0 0.5;...
    0 0 0 0 0 0 0 0.7;...
    0 0 0 0 0 0 0 0.3];

result.Name = ['subject' num2str(subject)];
result.Properties.LegLength = leg_lengths(subject);
result.Properties.WalkingSpeed = walking_speeds(1:end,subject);
result.Properties.Weight = weights(subject);
end

