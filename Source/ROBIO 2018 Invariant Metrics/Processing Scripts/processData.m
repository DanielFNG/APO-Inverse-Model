%% Obtain data directory. 

% Get the root folder using a UI.
root = ['C:\Users\Daniel\Documents\Dropbox\PhD\Testing MOtoNMS\ElaboratedData'];

%% Preliminaries: required steps for RRA adjustment.


%% Full data processing pipeline. 

subjects = 8;
feet = 1:2;
contexts = 1:5;  % Only steady-state contexts for now.
assistances = 1:3;

% Choose functions to execute. 
handles = {@prepareGRFFromFile, @prepareBatchIK};

% Choose periodic save destination.
save_dir = 'D:\with_apo_torques';

% Process data.
try
    dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);
catch ME
    fid = fopen('F:\Dropbox\PhD\Exoskeleton Metrics\Matlab Data Files\new_structs\error_message.txt', 'a+');
    fprintf(fid, '%s', ME.getReport('extended', 'hyperlinks', 'off'));
    rethrow(ME)
end
