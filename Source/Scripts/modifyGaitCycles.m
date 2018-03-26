% This script creates modified IK and GRF files for the 7 subjects from 
% the ROBIO 2017 Exoskeleton Gait Analsyis. The ROBIO 2017 files are 
% conventional in that the gait cycle begins at heel strike. The modified 
% files are defined to begin at the point of maximal hip flexion. 

root = 'D:\Dropbox\PhD\Exoskeleton Metrics';
output_dir = 'D:\Dropbox\PhD\MBBC\Testing\';

subjects = [1:4, 6:8];

for subject = subjects
    data_dir = [root '\S' num2str(subject) ...
        '\dynamicElaborations\rightStSt\NE2\'];
    % Identify two consecutive recorded gait cycles. 
    for i=1:4
        % Access adjacent gait cycles. 
        gait1 = Data([data_dir 'RRA_Results\RRA_q_' num2str(i) '.sto']);
        gait2 = Data([data_dir 'RRA_Results\RRA_q_' num2str(i+1) '.sto']);
        
        % Check that they actually are adjacent. 
        if (gait2.Timesteps(1) - gait1.Timesteps(end)) < 0.03
            %  Load in corresponding grfs.
            grfs1 = Data([data_dir 'NE2' num2str(i) '.mot']);
            grfs2 = Data([data_dir 'NE2' num2str(i+1) '.mot']);
            
            % Isolate hip trajectories. 
            hip1 = gait1.getDataCorrespondingToLabel('hip_flexion_r');
            hip2 = gait2.getDataCorrespondingToLabel('hip_flexion_r');
            
            % Set the first half of the hip trajectories to 0 so that we 
            % find the maximal pre-stance hip flexion, not during stance. 
            hip1(1:round(gait1.Frames/2)) = 0; 
            hip2(1:round(gait2.Frames/2)) = 0;
            
            % Get stard indices for kinematics and grfs. 
            [~, start_index] = max(hip1);
            [~, end_index] = max(hip2);
            start_time = gait1.Timesteps(start_index);
            end_time = gait2.Timesteps(end_index);
            rra_start = find(round(gait1.Timesteps, 3) == round(start_time, 2));
            rra_end = find(round(gait2.Timesteps, 3) == round(end_time, 2));
            grf_start = find(round(grfs1.Timesteps, 3) == round(start_time, 2));
            grf_end = find(round(grfs2.Timesteps, 3) == round(end_time, 2));
            
            % Append the gait cycles/grfs.
            two_gait = gait1.extend(gait2);
            two_grfs = grfs1.extend(grfs2);
            
            % Isolate the slices we want. 
            new_gait = ...
                two_gait.slice(rra_start, rra_end + gait1.Frames);
            new_grfs = ...
                two_grfs.slice(grf_start, grf_end + grfs1.Frames);
            
            % Write new gait cycles to file. 
            new_gait.writeToFile([output_dir 'S' num2str(subject) ...
                filesep 'rra_hip.sto'], 1, 1);
            new_grfs.writeToFile([output_dir 'S' num2str(subject) ...
                filesep 'grfs_hip.mot'], 1, 1);
            
            % Move to next subject. 
            break;
            
        elseif i == 4
            error('No consecutive data.');
        end
    end
end

