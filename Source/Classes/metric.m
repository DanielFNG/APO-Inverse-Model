classdef metric < handle
    
    properties %(SetAccess = private)
        name
        sample_size = 70;  % 7 subjects * 2 feet * 5 gait cycles
        means = 'Not yet known.'
        sdevs = 'Not yet known.'
        sig_diffs_A = 'Not yet known.'
        sig_diffs_C = 'Not yet known.'
        combined_means = 'Not yet calculated.'
        combined_sdevs = 'Not yet calculated.'
    end
        
    properties (SetAccess = private, GetAccess = private)
        assistance_order = {'NE', 'ET', 'EA'}
        context_order = {'BW','IW','DW','FW','SW'}
    end
    
    methods 
        
        function obj = metric(name)
            if nargin > 0
                obj.name = name;
            end
        end
        
        function inputManually(obj)
            for i=1:size(obj.assistance_order,2)
                for j=1:size(obj.context_order,2)
                    obj.means(i,j) = input(...
                        ['Input value for metric: ', obj.name, ' for ', ...
                        obj.assistance_order{i}, ' and ', ...
                        obj.context_order{j}, ':\n']);
                    obj.sdevs(i,j) = input(...
                        ['Input sdev for metric: ', obj.name, ' for ', ...
                        obj.assistance_order{i}, ' and ', ...
                        obj.context_order{j}, ':\n']);
                end
            end
        end
        
        function inputSignificantDifferences(obj)
            % This method provides a way to manually input the significant
            % differences for each metric. What results is 2 2D cell array
            % accessed using obj.sig_diffs_A or _C. 
            % The first dimension is how many differences there are in the
            % respective direction.
            % The second dimension also has 2 elements, the first of which
            % is the 'from' and the second the 'to', for example a
            % significant difference from NE to ET, for example. In
            % practice which is from and which is to won't matter since we
            % will only consider absolute Cohen's d for simplicity.
            obj.sig_diffs_A = {};
            obj.sig_diffs_C = {};
            display(['Please input all significant differences along'... 
                'the assistance direction. Input ''end'' to finish. You'...
                'will be prompted using ''From:'' and ''To:''. Give'...
                'the correct acronym in each case.']);
            n_x = 0;
            while true 
                x_f = input('From:\n', 's');
                if strcmp(x_f, 'end')
                    if n_x == 0
                        obj.sig_diffs_A{1,1} = 'n/a';
                    end
                    break
                end
                n_x = n_x + 1;
                x_t = input('To:\n', 's');
                obj.sig_diffs_A{n_x,1} = x_f;
                obj.sig_diffs_A{n_x,2} = x_t;
            end
            display('Now do the same but along context.');
            n_y = 0;
            while true
                y_f = input('From:\n', 's');
                if strcmp(y_f, 'end')
                    if n_y == 0
                        obj.sig_diffs_C{1,1} = 'n/a';
                    end
                    break
                end
                n_y = n_y + 1;
                y_t = input('To:\n', 's');
                obj.sig_diffs_C{n_y,1} = y_f;
                obj.sig_diffs_C{n_y,2} = y_t;
            end
        end
        
        % This calculates obj.combined_means, which is a map from a label
        % (corresponding to either an assistance level or walking context)
        % on to the combined mean for that label.
        %
        % For example, obj.combined_means('NE') is the mean value of
        % (NE,BW), (NE,IW), (NE,DW), ... etc. And likewise for the context
        % labels. 
        function calcCombinedMeansAndSdevs(obj)
            n_assist = size(obj.assistance_order,2);
            n_context = size(obj.context_order,2);
            comb_means = [];
            comb_sdevs = [];
            for i=1:n_assist
                keys{i} = obj.assistance_order{1,i};
                comb_means = [comb_means mean(obj.means(i,1:end))];
                comb_sdevs = [comb_sdevs obj.calcCombSdevs(...
                    comb_means(end), {'assistance', i})];
            end
            for i=1:n_context
                keys{i+n_assist} = obj.context_order{1,i};
                comb_means = [comb_means mean(obj.means(1:end,i))];
                comb_sdevs = [comb_sdevs obj.calcCombSdevs(...
                    comb_means(end), {'context', i})];
            end
            obj.combined_means = containers.Map(keys,comb_means);
            obj.combined_sdevs = containers.Map(keys,comb_sdevs);
        end
        
        function result = calcCombSdevs(obj, overall_mean, indices)
            if strcmp(indices{1}, 'assistance')
                assistance_level = indices{2};
                d = size(obj.context_order,2);
                temp = 0;
                for i=1:d
                    temp = temp + metric.intermediateVariance(...
                        obj.sample_size, ...
                        obj.sdevs(assistance_level,i)^2, ... % v = sdev^2
                        obj.means(assistance_level,i), overall_mean);
                end
            else
                context = indices{2};
                d = size(obj.assistance_order,2);
                temp = 0;
                for i=1:d
                    temp = temp + metric.intermediateVariance(...
                        obj.sample_size, obj.sdevs(i,context)^2, ...
                        obj.means(i,context), overall_mean);
                end
            end
            result = sqrt(temp/(d*obj.sample_size - 1));  % sdev = sqrt(V)
        end
        
        function diff = calculateRelativeDifferences(obj)
            diff = zeros(size(obj.means));
            baseline = obj.means(1,1); 
            for i=1:3
                for j=1:5
                    diff(i,j) = 100*(abs(obj.means(i,j) - baseline)/baseline);
                end
            end
        end
        
        function overall = calculateOverall(obj)
            diff = obj.calculateRelativeDifferences();
            diff = reshape(diff,1,[]);
            overall = mean(diff);
        end
        
        % For a metric, calculates the average relative to assistance 
        % scenario (i.e. for each of 'NE', 'ET', 'EA', average 'BW':'SW')
        % or context (vice versa). 'direction' should be 'assistance' or 
        % 'context' depending on the mode. 
        function avg_1d = calculate1DAvg(obj, direction)
            diff = obj.calculateRelativeDifferences();
            if strcmp(direction, 'context')
                avg_1d = 1:5;
                for i=1:5
                    avg_1d(i) = mean(diff(1:end,i));
                end
            elseif strcmp(direction, 'assistance')
                avg_1d = 1:3;
                for i=1:3
                    avg_1d(i) = mean(diff(i,1:end));
                end
            end
        end
        
        % Calculates the absolute value of Cohen's d averaged across 
        % either assistance, context, or in both directions. 
        function result = calcAbsCohensD(obj, direction)
            % Check that the significant difference info has been input.
            if isempty(obj.sig_diffs_A)
                error(['The Cohen''s d calculation'...
                    ' requires knowledge of significant differences.'...
                    ' See inputSignificantDifferences method.']);
            end
            
            % Parse command line arguments to see whether to average across
            % a direction or do the overall average. 
            if nargin == 1
                direction = 0;
            elseif nargin ~= 2
                error('Require 1 or 2 arguments to calc anova cohens d.');
            else
                if ~(strcmp(direction, 'A') || strcmp(direction, 'C'))
                    error('If given direction should be ''A'' or ''C''.');
                end
            end
            
            % Calculate Cohen's D for each significant differences, either
            % in one or both directions. 
            if ~(strcmp(direction, 'C'))
                contribution_A = [];
                if ~strcmp(obj.sig_diffs_A{1}, 'n/a')
                    for i=1:size(obj.sig_diffs_A,1)
                        contribution_A = ...
                            [contribution_A abs(obj.compCohensD(...
                            obj.sig_diffs_A{i,1}, obj.sig_diffs_A{i,2}))];
                    end
                end
            end
            if ~(strcmp(direction, 'A'))
                contribution_C = [];
                if ~strcmp(obj.sig_diffs_C{1}, 'n/a')
                    for i=1:size(obj.sig_diffs_C,1)
                        contribution_C = ...
                            [contribution_C abs(obj.compCohensD(...
                            obj.sig_diffs_C{i,1}, obj.sig_diffs_C{i,2}))];
                    end
                end
            end
            
            % Choose what to return based on the provided direction.
            if direction == 0
                result = mean([contribution_A contribution_C]);
            elseif strcmp(direction, 'A')
                result = mean(contribution_A);
            else % we already checked direction is either 'A', 'C', or set to 0
                result = mean(contribution_C);
            end
        end
        
        % Calculates Cohen's d between the groups of data specified by 
        % label1 and label2.
        function result = compCohensD(obj, label1, label2)
            if any(strcmp(label1, obj.assistance_order))
                q = size(obj.context_order,2);
            else
                q = size(obj.assistance_order,2);
            end
            n = obj.sample_size*q;
            mean1 = obj.combined_means(label1);
            mean2 = obj.combined_means(label2);
            sdev1 = obj.combined_sdevs(label1);
            sdev2 = obj.combined_sdevs(label2);
            result = metric.cohensD(n,mean1,sdev1,n,mean2,sdev2);
        end
              
        function cohens_d = calculateCohensD_tTests(obj)
            % t tests comparing means to baselines
            % 14 effect size results for each metric. Start off with a 
            % 5 x 3 matrix for convenience. 
            cohens_d = zeros(3,5);
            % over assistance levels and contexts...
            for i=1:5
                for j=1:3
                    % Don't compare the baseline to itself.
                    if ~ (i == 1 && j == 1)
                        % Calculate pooled standard deviation.
                        ss = 70;
                        pool = sqrt(((ss-1)*obj.sdevs(1,1)^2 + (ss-1)*obj.sdevs(j,i)^2)/(2*ss-2));
                        cohens_d(j,i) = (obj.means(1,1) - obj.means(j,i))/pool;
                    end
                end
            end
            
            
        end
        
    end
    
    methods (Static)
        
        function index = mapLabel(string)
            if strcmp(string, 'NE') || strcmp(string, 'BW')
                index = 1;
            elseif strcmp(string, 'ET') || strcmp(string, 'IW')
                index = 2;
            elseif strcmp(string, 'EA') || strcmp(string, 'DW')
                index = 3;
            elseif strcmp(string, 'FW')
                index = 4;
            elseif strcmp(string, 'SW')
                index = 5;
            else
                error('String not recognised.')
            end
        end
        
        % Function for calculating the intermediate terms when calculating
        % combined variance of groups. 
        function result = intermediateVariance(...
                samples, variance, mean, overall_mean)
            result = ((samples - 1) * variance) ...
                + (samples * mean^2) ...
                - (2 * samples * mean * overall_mean) ...
                + (samples * overall_mean^2);
        end
        
        % This function calculates Cohen's d for two groups of data, 
        % given the sample size, mean and variance of each group. 
        function result = cohensD(n1, m1, s1, n2, m2, s2)
            pooled_sdev = sqrt(((n1-1)*s1^2 + (n2-1)*s2^2)/(n1+n2-2));
            result = abs((m1 - m2)/pooled_sdev);
        end
        
    end
end
        