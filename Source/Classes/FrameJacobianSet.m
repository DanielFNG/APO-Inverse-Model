classdef FrameJacobianSet
    % Class for calculating and storing FrameJacobians. 
    %   Given an OpenSimTrial and a set of contact points for which
    %   FrameJacobians are desired, described by the appropriate
    %   ContactPointSettings xml file, this function computes and stores
    %   these Jacobians.
    %
    %   This class contains functions for returning parameters relating to
    %   a specific contact point given the name. See comments below for
    %   usage guidelines.
    
    properties
        Trial % OpenSimTrial with RRA calculated 
        Names % array of names given to the contact points in the setup file
        Jacobians % map from names to FrameJacobian objects 
    end
    
    methods
        
        function obj = FrameJacobianSet(OpenSimTrial, ContactPointSettings, dir)
            % OpenSimTrial is the OpenSimTrial for which frame Jacobians
            % are sought. dir is the results directory in which output
            % files are stored. ContactPointSettings is a string describing
            % the ContactPointSettings to use. A corresponding settings
            % file 'ContactPointSettings.xml' (where ContactPointSettings
            % is the string input) should be located in
            % Exopt/Defaults/ContactPointSettings.
            if nargin > 0
                obj.Trial = OpenSimTrial;
                dir = createUniqueDirectory(dir);
                obj.calculateFrameJacobianSet(ContactPointSettings, dir)
            end
        end
        
        function calculateFrameJacobianSet(obj, ContactPointSettings, dir)
            if isa(obj.Trial.rra, 'char')
                error(['RRA has not yet been calculated '...
                    'for this OpenSimTrial. Value classes!']);
            end
            current_dir = pwd;
            home = getenv('EXOPT_HOME');
            setupfile = [home '\defaults\ContactPointSettings\' ...
                ContactPointSettings '.xml'];
            cd([home '\bin']);
            % Remove headers and labels. 
            states_without_header = obj.removeHeaderFromStatesFile(dir);
            [run_status, cmdout] = system(['getFrameJacobians.exe'...
                ' "' obj.Trial.model_path '" '...
                ' "' states_without_header '" '...
                ' "' setupfile '" '...
                ' "' getFullPath(dir) '" ']);
            if ~(run_status == 0)
                display(cmdout);
                error('Failed to run getFrameJacobians.');
            end
            cd(current_dir);
        end
        
        function no_header = removeHeaderFromStatesFile(obj, dir)
            no_header = [dir '\no_header.sto'];
            obj.Trial.rra.states.writeToFile(no_header,0,0);
        end
        
    end
    
end

