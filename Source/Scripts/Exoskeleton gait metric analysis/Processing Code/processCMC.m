% A script to process CMC, done separately since originally CMC was not
% part of the analysis chain.
first_root = 'F:\Dropbox\PhD\Exoskeleton Metrics';
second_root = 'F:\structs_with_metrics';
first_save_dir = 'F:\cmc_only';
second_save_dir = 'F:\structs_with_cmc';

mkdir(first_save_dir);
mkdir(second_save_dir);

%% Run CMCs first to just generate the files. .
subjects = 1:3;
feet = 1;
contexts = 2:2:10;
assistances = 1:2;

% Choose functions to execute.
handles = {@prepareBatchCMC};

% Process data, loading in existing structs. 
dataLoop(...
    first_root, subjects, feet, contexts, assistances, handles, first_save_dir);

% %% Update the structs.
% handles = {@prepareCMCFromFile};
% dataLoop(...
%     first_root, subjects, feet, contexts, assistances, handles, second_save_dir);