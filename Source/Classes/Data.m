classdef Data
    % Class for storing and working with OpenSim data. 
    %   Easy access to reading and writing of data files in the correct
    %   format to be used within OpenSim. Methods for data handling
    %   including subsampling, ensuring time syncronisation of various data
    %   inputs, etc. Filenames are not stored since the data is designed to
    %   be worked with and so the original filename is likely to be out of
    %   date anyway. Data should be numerical. Text can appear in labels or
    %   in the header, but text in the main body of the data leads to
    %   incompatability. 
    
    properties
        Values 
        Labels
        Header
        Frames
        Timesteps
        hasHeader = false
        isLabelled = false 
        isTimeSeries = false
        isConsistentFrequency = false
        Frequency
    end
    
    properties (SetAccess = private)
        % Should be most (all?) of the properties above. 
    end
    
    methods
        
        % Construct Data object from filename.
        function obj = Data(filename)
            if nargin > 0
                if ischar(filename)
                    dataArray = importdata(filename);
                    % If there is a textdata property, check the last
                    % (potentially only) row. If this is a single cell
                    % (i.e. 1x1 rather than 1xn), run it through detectSpaces
                    % to see if it's a long string of headers. If it is
                    % (i.e. you get at least a 1x2 cell array) OR if the
                    % original thing was at least a 1x2 cell array, assume
                    % that this row corresponds to labels.
                    
                    % If there is anything else in textdata before this,
                    % put it as a header. 
                    
                    % Not using colheaders of the importdata function because 
                    % sometimes in my testcases this property doesn't exist 
                    % even when the data is labelled. 
                    if isa(dataArray,'struct')
                        obj = obj.getHeaderAndLabels(dataArray.textdata);
                        if sum(strcmp('',obj.Labels)) > 0 
                            error('Data file has one or more empty labels.')
                        end
                        obj.Values = dataArray.data;
                        if size(obj.Labels, 2) ~= size(obj.Values, 2)
                            error(['Number of labels does not match the '...
                                   'number of columns of data.'])
                        end
                        obj.Frames = size(dataArray.data,1);
                    elseif isa(dataArray,'double')
                        obj.Values = dataArray;
                        obj.Frames = size(dataArray,1);
                    else
                        error('Unrecognised data file format.')
                    end
                else
                    error(['Error in construction: expected input filename '...
                           'as string, got %s.'], class(filename))
                end
                obj.checkValues();
                if sum(strcmpi('time',obj.Labels)) == 1
                    obj.isTimeSeries = true;
                    obj.Timesteps = obj.getTimeColumn();
                    obj = obj.checkFrequency();
                elseif sum(strcmpi('time',obj.Labels)) > 1
                    error(['More than one column recognised as time data. '...
                           'Check column labels in data file.'])
                end
            end
        end
        
        % Get header and column labels from textdata. 
        function obj = getHeaderAndLabels(obj, textData)
            if size(textData(end,:),2) == 1
                potentialLabels = obj.detectSpaces(textData(end,:));
                if size(potentialLabels, 2) == 1
                    obj.isLabelled = false;
                    obj.hasHeader = true;
                    obj.Header = textData;
                else
                    obj.Labels = potentialLabels;
                    obj.isLabelled = true;
                end
            else
                obj.Labels = textData(end,:);
                obj.isLabelled = true;
            end
            if obj.isLabelled
                if size(textData,1) > 1
                    obj.hasHeader = true;
                    obj.Header = textData(1:end-1,:);
                end
            end
        end
        
        % Check that the entries of the Values array are well defined, if not 
        % return an error.
        function obj = checkValues(obj)
            if sum(sum(isnan(obj.Values))) ~= 0
                error(['One or more elements of the data array interpreted '...
                       'as NaN. Could be an error in the data set, or a '...
                       'blank cell/row/column. There should be no space '...
                       'between the data labels/header (if they exist) and '...
                       'the beginning of the data entries. Check your data '...
                       'set.'])
            end
        end
            
        % Verify that the frequency at which the data is presented is constant 
        % and if so store the data frequency. 
        function obj = checkFrequency(obj)
            if obj.isTimeSeries == 0 
                error(['Can''t check frequency because data is not a time '...
                      'series.'])
            else
                % Find the time column. 
                [~, location] = max(strcmp('time', obj.Labels));
                apparent_frequency = obj.Values(2,location) ...
                                     - obj.Values(1,location);
                averaged_frequency = ...
                        sum(obj.Values(2:end,location) ...
                        - obj.Values(1:end-1,location))/(size(obj.Values,1)-1);
                if abs(apparent_frequency - averaged_frequency) < 1e-4
                    disp('Data is at consistent frequency.');
                    obj.isConsistentFrequency = true;
                    obj.Frequency = round(1/apparent_frequency, 2);
                    disp('Frequency calculated.');
                else
                    disp('Data is not at a consistent frequency.')
                end
            end
            
        end
        
        % Check if the data can be subsampled to a requested frequency. 
        function subsamplingChecks(obj, desiredFrequency)
            if obj.isLabelled == false
                error(['Input data is not labelled. Can''t tell which '...
                       'column(s), if any, refer to time.'])
            elseif obj.isTimeSeries == false
                error(['Attempting to subsample data which does not belong '...
                      'to a time series.'])
            end
            if obj.isConsistentFrequency == false
                error(['Data you are attempting to subsample is not of '...
                       'consistent frequency. Use findConsistentSlice.'])
            elseif desiredFrequency > obj.Frequency
                error(['Attempting to subsample to a higher frequency than '...
                       'the original data.'])
%             elseif mod(obj.Frequency,desiredFrequency) ~= 0
%                 [upFreq, lowFreq] = obj.recommendSubsamplingFrequency(...
%                                     obj.Frequency, desiredFrequency);
%                 error(['Desired frequency is not achievable given the '...
%                        'original data set. If the desired frequency is '...
%                        'that of a second data set which you want to match'...
%                        ', the alternative is to subsample both datasets '...
%                        'to %d Hz. If not, and you are just seeking to '...
%                        'subsample, the two nearest alternatives are %d '...
%                        'and %d Hz.'], gcd(obj.Frequency, desiredFrequency)...
%                        ,lowFreq, upFreq)
%             % The above function was intended to recommend a good
%             % subsampling frequency. Currently not used because things are
%             % not integrated well in terms of using integer frequencies.
%             % Not sure if it should be rounded before calling this or if
%             % throughout I should assume integer frequencies for data, will
%             % have to have a think about this and come back to it. 
            end
        end
        
        % Get time column.
        function timeColumn = getTimeColumn(obj)
            if ~obj.isTimeSeries
                error(['Can''t find the time column if the data isn''t a '...
                       'time series.'])
            end
            [~, timeLocation] = max(strcmp('time', obj.Labels));
            timeColumn = obj.Values(1:end,timeLocation);
        end
        
        % Get start time. 
        function startTime = getStartTime(obj)
            timeColumn = obj.getTimeColumn();
            startTime = timeColumn(1);
        end
        
        % Get end time.
        function endTime = getEndTime(obj)
            timeColumn = obj.getTimeColumn();
            endTime = timeColumn(end);
        end
        
        % Subsample data. 
        function obj = subsample(obj, desiredFrequency)
            obj.subsamplingChecks(desiredFrequency);
            if ~isa(desiredFrequency, 'double')
                desiredFrequency = eval(desiredFrequency);
            end
            % The above is necessary because we used sym to obtain
            % desiredFrequency, which means results of operations using
            % desiredFrequency end up as fractions and mess things up. 
            initialFrames = obj.Frames;
            initialFrequency = obj.Frequency;
            for i=obj.Frames:-1:1
                % The testing value of 0.5*desiredFreq/obj.Freq should work,
                % but if you're having trouble with this later check to
                % make sure that this isn't too high/too low (causing
                % frames to be passed/chopped off unnecessarily).
                if abs(round(obj.Timesteps(i)*desiredFrequency,4) ...
                            - round(obj.Timesteps(i)*desiredFrequency)) ...
                            >= 0.6*(desiredFrequency/obj.Frequency)
                    obj.Timesteps(i) = [];
                    obj.Values(i,:) = [];
                end
            end
            % Removing duplicates. 
            for i=size(obj.Timesteps):-1:2
                if ((round(obj.Timesteps(i-1)*desiredFrequency) ...
                            - round(obj.Timesteps(i)*desiredFrequency)) == 0)
                    obj.Timesteps(i-1) = [];
                    obj.Values(i-1,:) = [];
                end
            end
            obj.Frames = size(obj.Timesteps,1);
            if (abs(initialFrequency/desiredFrequency ...
                        - initialFrames/obj.Frames) ...
                        > (initialFrequency/desiredFrequency - 1))
                error('Subsampling data was not accurate enough.')
            end
            obj = obj.updateHeader();
            obj = obj.checkFrequency();
        end
        
        % Subsample two data objects to a common frequency. 
        function [obj, anotherobj] = ...
                    subsampleDataToCommonFrequency(obj, anotherobj)
            highFrequency = max(obj.Frequency, anotherobj.Frequency);
            lowFrequency = min(obj.Frequency, anotherobj.Frequency);
            if (mod(highFrequency,lowFrequency) == 0)
                subsamplingFrequency = lowFrequency;
            else
                subsamplingFrequency = gcd(highFrequency,lowFrequency);
            end
            obj = obj.subsample(subsamplingFrequency);
            anotherobj = anotherobj.subsample(subsamplingFrequency);
        end
        
        % Find the common frequency given a set of Data objects. 
        function commonFrequency = findCommonFrequency(varargin)
            % Rounds the frequencies to the nearest integer to find the
            % nearest integer common frequency. 
            frequencyList = [];
            for i=1:size(varargin,2)
                if ~isa(varargin{i},'Data')
                    error('findCommonFrequency accepts only Data objects');
                elseif ~varargin{i}.isTimeSeries
                    error(['At least one input to findCommonFrequency is '...
                           'not time series data.']);
                elseif ~varargin{i}.isConsistentFrequency
                    error(['At least one input to findCommonFrequency is '...
                           'not consistent.']);
                end
                % My solution to the above feels really messy, not just in
                % this function but in others. Feels like this could be
                % solved better by having a more intricate class structure.
                % Have a think about this. Do you lose functionality by
                % moving it all to classes?
                frequencyList = [frequencyList, round(varargin{i}.Frequency)];
            end
            commonFrequency = gcd(sym(frequencyList));
        end
        
        % Find the longest slice of the data which of consistent frequency.
        function findLongestConsistentSlice(obj)
            % Not yet implemented.
        end
        
        % Find the common timesteps for two datasets and store them, as
        % well as the associated frame numbers. 
        function [commonTimes, objIndices, anotherobjIndices] = ...
                    findCommonTimesteps(obj, anotherobj)
            if ~obj.isTimeSeries || ~anotherobj.isTimeSeries
                error(['One or more input objects to findCommonTimesteps '...
                       'is not a time series.'])
            else
                [~, timeLocationForObj] = max(strcmp('time', obj.Labels));
                [~, timeLocationForAnotherObj] = ...
                    max(strcmp('time', anotherobj.Labels));
                commonTimes = [];
                objIndices = [];
                anotherobjIndices = [];
                for i=1:size(obj.Values,1)
                    for j=1:size(anotherobj.Values,1)
                        if abs(obj.Values(i,timeLocationForObj) ...
                               - anotherobj.Values(j, ...
                                                   timeLocationForAnotherObj)...
                              ) < 0.001
                            commonTimes = ...
                                    [commonTimes, ...
                                     obj.Values(i,timeLocationForObj)];
                            objIndices = [objIndices, i];
                            anotherobjIndices = [anotherobjIndices, j];
                        end
                    end
                end
            end
        end
        
        % Align two data objects so that they start at the same time (throw
        % away the leftover data). 
        function [obj, anotherobj] = alignStartingPoint(obj, anotherobj)
            % This can be made much more efficient by assuming you have an
            % increasing linear time series, but I've just kept it general.
            % Won't be running this more than once per go, anyway, and once
            % it's done it's done. 
            display('Chopping off frames to align data...')
            if ~obj.isTimeSeries || ~anotherobj.isTimeSeries
                error(['One or more input objects to alignStartingPoint is '...
                       'not a time series.'])
            else
                [commonTimes,objIndices,anotherobjIndices] = ...
                        findCommonTimesteps(obj,anotherobj);
                [~, index] = min(commonTimes);
                obj.Values = obj.Values(objIndices(index):end,:);
                obj.Timesteps = obj.Timesteps(objIndices(index):end,:);
                obj.Frames = size(obj.Timesteps,1);
                anotherobj.Values = ...
                        anotherobj.Values(anotherobjIndices(index):end,:);
                anotherobj.Timesteps = ...
                        anotherobj.Timesteps(anotherobjIndices(index):end,:);
                anotherobj.Frames = size(anotherobj.Timesteps,1);
            end
        end
        
        % Align two data objects so that they end at the same time (throw
        % away the leftover data).
        function [obj, anotherobj] = alignEndingPoint(obj, anotherobj)
            % Same as above but for ending points. 
            display('Chopping off frames to align data...')
            if ~obj.isTimeSeries || ~anotherobj.isTimeSeries
                error(['One or more input objects to alignStartingPoint '...
                       'is not a time series.'])
            else
                [commonTimes,objIndices,anotherobjIndices] = ...
                        findCommonTimesteps(obj,anotherobj);
                [~, index] = max(commonTimes);
                obj.Values = obj.Values(1:objIndices(index),:);
                obj.Timesteps = obj.Timesteps(1:objIndices(index),:);
                obj.Frames = size(obj.Timesteps,1);
                anotherobj.Values = ...
                        anotherobj.Values(1:anotherobjIndices(index),:);
                anotherobj.Timesteps = ...
                        anotherobj.Timesteps(1:anotherobjIndices(index),:);
                anotherobj.Frames = size(anotherobj.Timesteps,1);
            end
        end
        
        % Align two data objects so that they start and end at the same
        % time, throwing away the leftover data, and returning the end points. 
        function [obj, anotherobj, startTime, endTime] = ...
                    alignData(obj, anotherobj)
            if ~obj.isTimeSeries || ~anotherobj.isTimeSeries
                error(['One or more input objects to alignStartingPoint '...
                       'is not a time series.'])
            end
            if obj.Timesteps(1) == anotherobj.Timesteps(1)
                startTime = obj.Timesteps(1);
            else
                [obj, anotherobj] = alignStartingPoint(obj, anotherobj);
                if abs(obj.Timesteps(1) - anotherobj.Timesteps(1)) > 0.001
                    error(['Data objects do not share the same start time. '...
                           'A suitable start time could not be found to '...
                           'within the hard-coded error tolerance.'])
                end
                startTime = max([obj.Timesteps(1), anotherobj.Timesteps(1)]);
            end
            if obj.Timesteps(end) == anotherobj.Timesteps(end)
                endTime = obj.Timesteps(end);
            else
                [obj, anotherobj] = alignEndingPoint(obj, anotherobj);
                if abs(obj.Timesteps(end) - anotherobj.Timesteps(end)) > 0.001
                    error(['Data objects do not share the same end time. '
                           'A suitable end time could not be found to '
                           'within the hard-coded error tolerance.'])
                end
                endTime = min([obj.Timesteps(end),anotherobj.Timesteps(end)]);
            end
        end
        
        % Typically OpenSim data formats will have an 'nColumns' and
        % 'nRows' entry in the header. Identify if this is the case and
        % update these values following changes to a data file. 
        function obj = updateHeader(obj)
            checkingForMultipleNRows = 0;
            checkingForMultipleNColumns = 0;
            for i=1:size(obj.Header)
                if cell2mat(strfind(obj.Header(i),'nRows'))
                    obj.Header(i) = ...
                            cellstr(['nRows=', int2str(size(obj.Values,1))]);
                    checkingForMultipleNRows = checkingForMultipleNRows + 1;
                elseif cell2mat(strfind(obj.Header(i),'nColumns'))
                    obj.Header(i) = ...
                            cellstr(['nColumns=', int2str(size(obj.Values,2))]);
                    checkingForMultipleNColumns = ...
                            checkingForMultipleNColumns + 1;
                end
            end
            if checkingForMultipleNRows > 1 || checkingForMultipleNColumns > 1
                error('Found multiple row/column sizes in header!');
            end
        end
        
        % Write data object to a tab delimited file. 
        function writeToFile(obj, filename, withHeader, withLabels)
            fileID = fopen(filename,'w');
            if obj.hasHeader && (withHeader == 1)
                for i=1:size(obj.Header,1)
                    fprintf(fileID,'%s\n', char(obj.Header(i)));
                end
            end
            if obj.isLabelled && (withLabels == 1)
                for i=1:size(obj.Labels,2)
                    fprintf(fileID,'%s\t', char(obj.Labels(i)));
                end
                fprintf(fileID,'\n');
            end
            for i=1:size(obj.Values,1)
                for j=1:size(obj.Values,2)
                    fprintf(fileID,'%12.14f\t', obj.Values(i,j));
                end
                fprintf(fileID,'\n');
            end
            fclose(fileID);
        end
      
        % Get, as a vector, the data corresponding to a specific label.
        % Returns 0 if the label could not be matched. 
        function vector = getDataCorrespondingToLabel(obj,label)
            vector = 0;
            for i=1:size(obj.Labels,2)
                if strcmp(label, char(obj.Labels{i}))
                    vector = obj.Values(1:end,i);
                end
            end     
        end
        
        % Get, as an int, the index corresponding to a specific label.
        % Returns 0 if the label could not be matched. 
        function index = getIndexCorrespondingToLabel(obj, label)
            index = 0;
            for i=1:size(obj.Labels,2)
                if strcmp(label, char(obj.Labels{i}))
                    index = i;
                end
            end
        end
        
        function index = getIndexCorrespondingToTimestep(obj, timestep)
            index = 0;
            for i=1:size(obj.Timesteps,2)
                if obj.Timesteps(i) == timestep
                    index = i;
                end
            end
        end
        
        function obj = scaleColumn(obj,index,multiplier)
            if strcmp(obj.Labels(index), 'time') 
                error('You probably dont want to be scaling time col.');
            end
            obj.Values(1:end,index) = multiplier*obj.Values(1:end,index);
        end
      
    end
    
    methods(Static)
        % Given a frequency and a desired subsampling frequency which are 
        % incompatible (i.e. mod(freq,desired) ~= 0), and are both natural 
        % numbers, return the nearest two possible integer desired frequencies. 
        function [upFreq, lowFreq] = ...
                    recommendSubsamplingFrequency(currentFrequency, ...
                                                  desiredFrequency)
            if ~isa(currentFrequency,'double') ...
                        || ~isa(desiredFrequency,'double') ...
                        || rem(currentFrequency,1) ~= 0 ...
                        || rem(desiredFrequency,1) ~= 0
                error(['Can''t recommend subsampling frequency for '...
                       'non-integer arguments.'])
            elseif currentFrequency < 1 || desiredFrequency < 1
                error(['Frequencies provided to '...
                       'recommendSubSamplingFrequency must be strictly '...
                       'greater than 0.'])
            elseif desiredFrequency > currentFrequency
                error(['Can''t recommend subsampling frequency because '...
                       'desired frequency is higher than actual frequency.'])
            end
            for i=1:currentFrequency-desiredFrequency
                if mod(currentFrequency,desiredFrequency+i) == 0
                    upFreq = desiredFrequency + i;
                    break
                end
            end
            for i=1:desiredFrequency-1
                if mod(currentFrequency,desiredFrequency-i) == 0
                    lowFreq = desiredFrequency - i;
                    break
                end
            end
        end 
        
        % Given a cell containing 'time vx vy vz...' etc which is 1x1
        % separate it in to 1 x n by detecting the spaces. 
        function headers = detectSpaces(cell)
            cellToString = char(cell);
            headers = strsplit(cellToString);
            % Occasionally headers can have its last entry as ''. This is 
            % undesirable so it is removed if it exists. Likewise for the 
            % first entry.
            if strcmp(headers(end),'')
                headers(end) = [];
            end
            if strcmp(headers(1),'')
                headers(1) = [];
            end
        end
            
            
    end
    
end

