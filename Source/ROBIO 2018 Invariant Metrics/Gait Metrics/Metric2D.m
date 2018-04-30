classdef Metric2D < handle
    
    properties (SetAccess = private)
        name
        sample_size 
        means  
        sdevs 
        row_diffs
        col_diffs
        n_rows
        n_cols
        row_sig_diffs
        col_sig_diffs
        p_value = 0.05
        row_labels
        col_labels
        row_descriptor = 'row'
        col_descriptor = 'column'
    end
        
    properties (SetAccess = private, GetAccess = private)
        base_row = 1
        base_col = 1
        comb_row_means
        comb_col_means
        comb_row_sdevs
        comb_col_sdevs
    end
    
    methods 
        
        function obj = Metric2D(name, means, sdevs, sample_size, ...
                col_diffs, row_diffs, row_descriptor, col_descriptor, row_labels, col_labels, baseline)
            if nargin > 0
                obj.name = name;
                if nargin >= 6
                    obj.means = means;
                    obj.sdevs = sdevs;
                    obj.sample_size = sample_size;
                    obj.row_diffs = row_diffs;
                    obj.n_rows = size(row_diffs, 1);
                    obj.col_diffs = col_diffs;
                    obj.n_cols = size(col_diffs, 1);
                    obj.identifySignificantDifferences();
                    obj.calcCombinedMeansAndSdevs();
                    if nargin >= 8
                        obj.row_descriptor = row_descriptor;
                        obj.col_descriptor = col_descriptor;
                        obj.row_labels = row_labels;
                        obj.col_labels = col_labels;
                        if nargin == 11
                            obj.base_row = baseline(1);
                            obj.base_col = baseline(2);
                        end
                    else
                        obj.assignDefaultLabels();
                    end
                else
                    error('Non-empty metrics require 6+ arguments.');
                end
            end
        end
        
        % Assigns default labelling to the rows and columns e.g. row1, 
        % col1, etc.
        function assignDefaultLabels(obj)
            for i=1:obj.n_rows
                obj.row_labels{i} = ['row' num2str(i)];
            end
            for i=1:obj.n_cols
                obj.col_labels{i} = ['col' num2str(i)];
            end
        end
        
        % Calculate the significant difference matrices. These identify 
        % which combinations of rows/columns exhibit significant differences.
        % For example row_sig_diffs(1,2) = 1 => there is a significant 
        % difference between row 1 and row 2. The default is 0, meaning 
        % no significant differences. The matrix is left as upper
        % triangular.
        function identifySignificantDifferences(obj)
            
            obj.row_sig_diffs = zeros(obj.n_rows);
            obj.col_sig_diffs = zeros(obj.n_cols);
            
            for i=1:size(obj.col_diffs,1)
                if obj.col_diffs(i,6) < obj.p_value
                    obj.col_sig_diffs(...
                        obj.col_diffs(i, 1), obj.col_diffs(i, 2)) = 1;
                end
            end
            
            for i=1:size(obj.row_diffs,1)
                if obj.row_diffs(i,6) < obj.p_value 
                    obj.row_sig_diffs(...
                        obj.row_diffs(i, 1), obj.row_diffs(i, 2)) = 1;
                end
            end         
        end
        
        % This calculates the combined means and combined sdevs which are
        % later used in Cohen's d calculations. 
        function calcCombinedMeansAndSdevs(obj)
            % Preallocate variables. 
            obj.comb_row_means = zeros(1, obj.n_rows);
            obj.comb_row_sdevs = zeros(1, obj.n_rows);
            obj.comb_col_means = zeros(1, obj.n_cols);
            obj.comb_col_sdevs = zeros(1, obj.n_cols);
            
            % Calculate combined row and column means.
            obj.comb_row_means(1:end) = mean(obj.means(1:end, :));
            obj.comb_col_means(1:end) = mean(obj.means(:, 1:end));
            
            % Calculate combined row sdevs. 
            for i=1:obj.n_rows
                int_row_vars(1:obj.n_cols) = ...
                    metric.intermediateVariance(obj.sample_size, ...
                    obj.sdevs(i, 1:end).^2, obj.means(i, 1:end), ...
                    obj.comb_row_means(i));
                obj.comb_row_sdevs(i) = sqrt(sum(int_row_vars)/ ...
                    (obj.n_cols*obj.sample_size - 1));
            end
            
            % Calculate combined column sdevs.
            for i=1:obj.n_cols
                int_col_vars(1:obj.n_rows) = ...
                    metric.intermediateVariance(obj.sample_size, ...
                    obj.sdevs(1:end, i).^2, obj.means(1:end, i), ...
                    obj.comb_col_means(i));
                obj.comb_col_sdevs(i) = sqrt(sum(int_col_vars)/ ...
                    (obj.n_rows*obj.sample_size - 1));
            end
            
        end
        
        % Calculate signed or absolute relative differences.
        function diff = calculateRelativeDifferences(obj, mode)
            diff = zeros(size(obj.means));
            baseline = obj.means(obj.base_row, obj.base_col);
            if strcmp(mode, 'unsigned')
                diff(:, :) = 100*(abs(obj.means(:, :) - baseline)/baseline);
            elseif strcmp(mode, 'signed')
                diff(:, :) = 100*(obj.means(:, :) - baseline)/baseline;
            else
                error('Unrecognised mode.');
            end
        end
        
        % Makes sense to use unsigned here to capture the magnitude of the
        % effect and avoid any cancellation. 
        function overall = calculateOverall(obj)
            diff = obj.calculateRelativeDifferences('unsigned');
            diff = reshape(diff,1,[]);
            overall = mean(diff);
        end
        
        % For a metric, calculates the average relative to assistance 
        % scenario (i.e. for each of 'NE', 'ET', 'EA', average 'BW':'SW')
        % or context (vice versa). 'direction' should be 'assistance' or 
        % 'context' depending on the mode. 
        function avg_1d = calculate1DAvg(obj, direction)
            diff = obj.calculateRelativeDifferences('unsigned');
            if strcmp(direction, obj.col_descriptor)
                avg_1d = 1:obj.n_cols;
                for i=1:obj.n_cols
                    avg_1d(i) = mean(diff(1:end,i));
                end
            elseif strcmp(direction, obj.row_descriptor)
                avg_1d = 1:obj.n_rows;
                for i=1:obj.n_rows
                    avg_1d(i) = mean(diff(i,1:end));
                end
            end
        end
        
        % Calculates the value of Cohen's d averaged across either 
        % assistance, context, or in both directions. Note that this 
        % computes the magnitude of Cohen's d.
        function result = calcCohensD(obj, direction)
            
            % Parse command line arguments to see whether to average across
            % a direction or do the overall average.
            
            if nargin == 1
                direction = 0;
            elseif nargin ~= 2
                error('Require 1 or 2 arguments to calc anova cohens d.');
            else
                if ~(strcmp(direction, obj.row_descriptor) || ...
                        strcmp(direction, obj.col_descriptor))
                    error(['If given direction should match either ' ...
                        'the column or row descriptor.']);
                end
            end
            
            % Calculate Cohen's D for each significant differences, either
            % in one or both directions.
            if ~strcmp(direction, obj.col_descriptor)
                if obj.row_sig_diffs == 0
                    row_contribution = 0;
                else
                    
                    [r_ind1, r_ind2] = ind2sub(...
                        size(obj.row_sig_diffs), find(obj.row_sig_diffs));
                    
                    row_contribution = obj.compCohensD(...
                        obj.row_descriptor, r_ind1, r_ind2);
                end
            end
            if ~(strcmp(direction, obj.row_descriptor))
                if obj.col_sig_diffs == 0
                    col_contribution = 0;
                else
                    [c_ind1, c_ind2] = ind2sub(...
                        size(obj.col_sig_diffs), find(obj.col_sig_diffs));
                    
                    col_contribution = obj.compCohensD(...
                        obj.row_descriptor, c_ind1, c_ind2);
                end
            end
            
            % Take absolute value of contributions.
            row_contribution = abs(row_contribution);
            col_contribution = abs(col_contribution);
            
            % Choose what to return based on the provided direction.
            if direction == 0
                result = mean([row_contribution col_contribution]);
            elseif strcmp(direction, obj.row_descriptor)
                result = mean(row_contribution);
            else % we already checked direction is either 'A', 'C', or set to 0
                result = mean(col_contribution);
            end
        end
        
        % Calculates Cohen's d between the groups of data specified by 
        % label1 and label2.
        function result = compCohensD(obj, direction, labels1, labels2)
            
            % Handle the direction. 
            if strcmp(direction, obj.row_descriptor)
                q = obj.n_cols;
                dir_means = obj.combined_row_means;
                dir_sdevs = obj.combined_row_sdevs;
            elseif strcmp(direction, obj.col_descriptor)
                q = obj.n_rows;
                dir_means = obj.combined_col_means;
                dir_sdevs = obj.combined_col_sdevs;
            else
                error('Direction for compCohensD not valid.');
            end
            
            % The number of samples is the sample size of the metric * the 
            % number of scenarios along the dimension that the labels are 
            % NOT from.
            n = obj.sample_size*q;
            
            % Use the combined means and sdevs to calculate Cohen's d.
            mean1 = dir_means(labels1);
            mean2 = dir_means(labels2);
            sdev1 = dir_sdevs(labels1);
            sdev2 = dir_sdevs(labels2);
            
            result = metric.cohensD(n,mean1,sdev1,n,mean2,sdev2);
        end
              
        function cohens_d = calculateCohensD_tTests(obj)
            % t tests comparing means to baselines
            % 14 effect size results for each metric. Start off with a 
            % 5 x 3 matrix for convenience. 
            cohens_d = zeros(obj.n_rows, obj.n_cols);
            % over assistance levels and contexts...
            for i=1:obj.n_cols
                cohens_d(1:end, i) = cohensD(obj.sample_size, ...
                    obj.means(1, 1), obj.sdevs(1, 1), obj.sample_size, ...
                    obj.means(1:end, i), obj.sdevs(1:end, i));
            end
        end
        
        % Mode should be 'absolute', 'signed' or 'unsigned'.
        function plot3DBar(obj, mode)
            
            % Compute relative differences from the baseline. 
            if strcmp(mode, 'absolute')
                diff = obj.means;
            else
                diff = obj.calculateRelativeDifferences(mode);
            end
            
            % Set dimensions.
            b = figure;
            b.Units = 'centimeters';
            set(b, 'Position', [2 2 25 15]);
            ax = axes('Parent', b);
            
            % Create a bar plot.
            b = bar3(diff);
            
            % Create the color bar.
            colormap('parula');
            colorbar('peer',ax,'Position',[0.890396659707724 ...
                0.198050314465409 0.031513569937367 0.666729559748428]);
            
            % Change the colours of the bars accordingly. 
            for k=1:length(b)
                b(k).CData = b(k).ZData;
                b(k).FaceColor = 'interp';
            end
            
            % Add the significant difference lines. 
            hold on;
            obj.plotSignificantDifferences(diff);
            hold off
            
            obj.context_order{2} = 'UW';
            
            % Handle labels etc.
            xlabel('Walking context', 'FontWeight', 'bold');
            zlabel('% difference from baseline', 'FontWeight', 'bold');
            ylabel('Assistance Level', 'FontWeight', 'bold');
            set(ax, 'FontSize', 20, 'FontWeight', 'bold', 'XTick', ...
                1:obj.n_cols, 'XTickLabel', obj.context_order, 'YTick', ...
                1:obj.n_rows, 'YTickLabel', obj.assistance_order);
            words = strsplit(obj.name(1:end-2), '_');
            if length(words) > 1
                for i=1:length(words)
                    if strcmp(words{i}(end), '1')
                        words{i} = [words{i}(1:end-1) '.'];
                    else
                        words{i} = [words{i} '.'];
                    end
                end
            end
            new_name = strjoin(words);
            title([upper(new_name(1)) new_name(2:end)])
            
            ylim([0 5]);
                    
        end
        
        function plotSignificantDifferences(obj, vals)
            j = 0.1;
            for i=1:size(obj.col_diffs,1)
                if obj.col_diffs(i,6) < obj.p_value
                    mx = max(max(vals)) + j*max(max(vals));
                    j = j + 0.2;
                    x = [obj.col_diffs(i,1); obj.col_diffs(i,2)];
                    y = zeros(2);
                    z = ones(1,2)*mx;
                    plot3(x,y,z,'-k.','linewidth',1);
                end
            end
            
            j = 0.1;
            for i=1:size(obj.row_diffs,1)
                if obj.row_diffs(i, 6) < obj.p_value
                    mx = max(max(vals)) + j*max(max(vals));
                    j = j + 0.2;
                    x = ones(1,2)*5.4;
                    y = [obj.row_diffs(i,1); obj.row_diffs(i,2)];
                    z = ones(1,2)*mx;
                    plot3(x,y,z,'-k.','linewidth',1);
                end
            end  
        end
        
    end
    
    methods (Static)
        
        % Function for calculating the intermediate terms when calculating
        % combined variance of groups. Supports scalar or vector arguments
        % for variance, mean and overall mean. Sample size must be a 
        % scalar. 
        function result = intermediateVariance(...
                samples, variance, mean, overall_mean)
            result = ((samples - 1) * variance) ...
                + (samples * mean.^2) ...
                - (2 * samples * mean .* overall_mean) ...
                + (samples * overall_mean.^2);
        end
        
        % This function calculates Cohen's d for two sets of groups of data 
        % given the sample size, mean and sdev of each group. This code
        % is vectorised to accept vector means and standard deviations. The
        % sample sizes must be scalar. 
        function result = cohensD(n1, m1, s1, n2, m2, s2)
            result = abs((m1 - m2)./calcPooledSDev(n1, s1, n2, s2));
        end
        
        % Calculates the pooled standard deviation between two sets of
        % groups of data given the sample size and standard deviation of
        % each group. Code is vectorised to accept vector standard
        % deviations.
        function result = calcPooledSDev(n1, s1, n2, s2)
            result = sqrt((n1 - 1)*s1.^2 + (n2 - 1)*s2.^2)./(n1 + n2 - 2);
        end
        
    end
end
        