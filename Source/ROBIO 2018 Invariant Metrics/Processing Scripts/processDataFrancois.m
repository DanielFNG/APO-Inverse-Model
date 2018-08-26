%% Obtain data directory. 

% Get the root folder using a UI.
root = ['C:\Users\Daniel\Documents\Dropbox\PhD\Testing MOtoNMS\ElaboratedData'];

%% Full data processing pipeline. 

subjects = 8;
feet = 1:2;
contexts = 1:5;  % Only steady-state contexts for now.
assistances = 1:3;

% Choose functions to execute. 
handles = {@prepareGRFFromFile, @prepareIKFromFile, ...
    @prepareBodyKinematicsFromFile};

% Choose periodic save destination.
save_dir = 'C:\Users\Daniel\Documents\Dropbox\PhD\Francois Data';

%dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);

% Metrics
handles = {@prepareCoMD, @prepareCoPD, @prepareHipROM, @prepareKneeROM, ...
    @prepareMoS, @prepareSF, @prepareSW};

% Process.
dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir, save_dir);