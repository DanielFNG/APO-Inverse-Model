function value = MBBCObjective(input_table)

    % Use a global variable.
    global folder

    % Import the OpenSim modelling classes.
    import org.opensim.modeling.*
    
    % Load the model, rra and grf data from the folder.
    model = Model([folder filesep 'model_adjusted_mass_changed.osim']);
    rra = Data([folder filesep 'RRA_q_1.sto']);
    grfs = Data([folder filesep 'NE21.mot']);
    
    % Calculate the total mass of the model. 
    % state = model.initSystem();
    % mass = model.getModelMass(state);
    
    % Define fixed parameters.
    % gravity = -9.80665;
    % peak_force = abs(0.3*mass*gravity);
    
    % Generate the assistive pattern. 
    n_points = 1000;
    peak_torque = 15;
    pattern = generateAssistiveProfile(n_points, peak_torque, ...
        input_table.peak_timing, input_table.offset_timing);
    
    % Isolate the hip trajectories. 
    left_hip = rra.getDataCorrespondingToLabel('hip_flexion_l');
    right_hip = rra.getDataCorrespondingToLabel('hip_flexion_r');
    
    % Set half of each trajectory to 0 to isolate the maximal pre-stance
    % hip flexion, not during stance. For the leading foot this is the
    % first half, for the off-foot this is the second half. Right leads.
    left_hip(round(rra.Frames/2)+1:end) = 0;
    right_hip(1:round(rra.Frames/2)) = 0;
    
    % Identify point and time of maximal pre-stance hip flexion. 
    [~, left_start] = max(left_hip);
    [~, right_start] = max(right_hip);
    left_time = rra.Timesteps(left_start);
    right_time = rra.Timesteps(right_start);
    
    % Find the corresponding grf frames. 
    left_grf = find(round(grfs.Timesteps, 3) == round(left_time, 2));
    right_grf = find(round(grfs.Timesteps, 3) == round(right_time, 2));
    
    % Stretch the assistive pattern to be on the same number of frames as
    % the grfs.
    n_timesteps = grfs.Frames;
    stretched_pattern = stretchVector(pattern, n_timesteps);
    
    % Shift the pattern to create left/right APO torque commands. 
    apo_left_torque = circshift(stretched_pattern, left_grf, 1);
    apo_right_torque = circshift(stretched_pattern, right_grf, 1);
    
    %% Create new GRF file. 
    
    % Make the labels.
    labels = {'time',...
        'apo_force_vx','apo_force_vy','apo_force_vz',...
        'apo_force_px','apo_force_py','apo_force_pz',...
        'apo_torque_x','apo_torque_y','apo_torque_z',...
        '1_apo_force_vx','1_apo_force_vy','1_apo_force_vz',...
        '1_apo_force_px','1_apo_force_py','1_apo_force_pz',...
        '1_apo_torque_x','1_apo_torque_y','1_apo_torque_z',...
        'apo_group_force_vx','apo_group_force_vy','apo_group_force_vz',...
        'apo_group_force_px','apo_group_force_py','apo_group_force_pz',...
        'apo_group_torque_x','apo_group_torque_y','apo_group_torque_z',...
        '1_apo_group_force_vx','1_apo_group_force_vy','1_apo_group_force_vz',...
        '1_apo_group_force_px','1_apo_group_force_py','1_apo_group_force_pz',...
        '1_apo_group_torque_x','1_apo_group_torque_y','1_apo_group_torque_z'};
    
    % Stretch the APO torque values.
    n_timesteps = grfs.Frames;
    apo_right_torque = stretchVector(pattern, n_timesteps);
    apo_left_torque = stretchVector(pattern_left, n_timesteps);
    
    % Form the values for the APO grfs. 
    values = zeros(n_timesteps, length(labels) - 1);
    values(1:end,1) = grf.Timesteps;
    values(1:end,2:9) = 0;
    values(1:end,10) = apo_right_torque;
    values(1:end,11:18) = 0;
    values(1:end,19) = apo_left_torque;
    values(1:end,20:27) = 0;
    values(1:end,28) = -apo_right_torque;
    values(1:end,29:36) = 0;
    values(1:end,37) = -apo_left_torque;
    
    % Create an empty data object then assign these labels and
    % values.
    apo_data = Data();
    apo_data.Values = values;
    apo_data.Labels = labels;
    apo_data.Timesteps = grfs.Timesteps;
    apo_data.isTimeSeries = true;
    apo_data.Frames = grfs.Frames;
    apo_data.Header = grfs.Header;
    apo_data.hasHeader = true;
    apo_data.isLabelled = true;
    apo_data = apo_data.updateHeader();
    
    % Create and write out the modified GRF file which includes the APO
    % contribution. 
    new_grfs = grfs + apo_data;
    new_grfs.writeToFile([folder filesep 'grfs_hip_apo.mot'],1,1);
    

end