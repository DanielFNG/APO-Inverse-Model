function result = prepareKneeROM(~, ~, foot, context, assistance, result)
% Calculates the hip range of motion for a given subject and gait cycle 
% as indexed by a {foot, context, assistance} triple.

% Create correct label.
switch foot
    case 1
        label = 'knee_angle_r';
    case 2
        label = 'knee_angle_l';
end

% Gain access to the hip trajectories as set of data objects.
IK = result.IK.IK_array{foot, context, assistance};

% Create temp cell array.
temp{vectorSize(IK)} = {};

% Calculate hip ROM for each individual trajectory and save it.
for i=1:vectorSize(IK)
    temp{i} = calculateKneeROM(IK{i}, label);
end

result.MetricsData.KneeROM{foot, context, assistance} = temp;

end