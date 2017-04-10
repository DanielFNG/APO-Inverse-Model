classdef FrameJacobians
    %FRAMEJACOBIANS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        trial % OpenSimTrial with RRA calculated 
        names % array of names given to the contact points in the setup file
        jacobians % array of data objects holding the time indexed jacobians  
    end
    
    methods
        
        function obj = FrameJacobians(OpenSimTrial, ContactPointSettings, dir)
            % OpenSimTrial is the OpenSimTrial for which frame Jacobians
            % are sought. dir is the results directory in which output
            % files are stored. ContactPointSettings is a string describing
            % the ContactPointSettings to use. A corresponding settings
            % file 'ContactPointSettings.xml' (where ContactPointSettings
            % is the string input) should be located in
            % Exopt/Defaults/ContactPointSettings.
            if nargin > 0
                obj.trial = OpenSimTrial;
                dir = createUniqueDirectory(dir);
                obj.calculateFrameJacobians(ContactPointSettings, dir)
            end
        end
        
        function calculateFrameJacobians(obj, ContactPointSettings, dir)
            current_dir = pwd;
            home = getenv('EXOPT_HOME');
            setupfile = [home '\defaults\ContactPointsSettings\' ...
                ContactPointSettings '.xml'];
            cd([home '\bin']);
            [run_status, cmdout] = system(['getFrameJacobians.exe'...
                ' "' obj.trial.model_path '" '...
                ' "' obj.trial.rra.states_path '" '...
                ' "' setupfile '" '...
                ' "' getFullPath(dir) '" ']);
            if ~(run_status == 0)
                display(cmdout);
                error('Failed to run getFrameJacobians.');
            end
            cd(current_dir);
        end
        
    end
    
end

