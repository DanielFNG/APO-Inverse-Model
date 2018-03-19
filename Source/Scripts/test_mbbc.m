% This script creates modified IK and GRF files for the 7 subjects from 
% the ROBIO 2017 Exoskeleton Gait Analsyis. The ROBIO 2017 files are 
% conventional in that the gait cycle begins at heel strike. The modified 
% files are defined to begin at the point of maximal hip flexion. 

root = 'D:\Dropbox\PhD\Exoskeleton Metrics';

subjects = [1:4, 6:8];

for subject = subjects
    data_dir = [root '\S' num2str(subject) ...
        '\dynamicElaborations\rightStSt\NE2'];
    % Identify two consecutive recorded gait cycles. 
    for i=1:4
        gait1 = Data([data_dir '\IK_Results\ik' num2str(i) '.mot']);
        gait2 = Data([data_dir '\IK_Results\ik' num2str(i+1) '.mot']);
        if (gait2.Timesteps(1) - gait1.Timesteps(end)) < 0.03
            hip1 = gait1.getDataCorrespondingToLabel('hip_flexion_r');
            hip2 = gait2.getDataCorrespondingToLabel('hip_flexion_r');
            [~, start_index] = max(hip1);
            [~, end_index] = max(hip2);
            start_time = gait1.Timesteps(start_index);
            end_time = gait2.Timesteps(end_index);
            two_gait = extend(gait1, gait2);
            new_gait = slice(two_gait, start_index, end_index + gait1.Frames);
            break;
        elseif i == 4
            error('No consecutive data.');
        end
    end
end

