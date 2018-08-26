% The directory where the subject data is stored (as Matlab data).
load_dir = 'C:\Users\Daniel\Documents\Dropbox\PhD\Francois Data';

% The parameters we want to look at data for. 
subjects = 8;
contexts = 1:5;
assistances = 1:3;
feet = 1;

save_dir = [load_dir filesep 'rightfoot_metrics.mat'];

% Load the subjects and store the metric information for each subject only.
for subject = subjects
    result = loadSubject(load_dir, subject);
    metric_names = fieldnames(result.MetricsData);
    for nmetric = 1:length(metric_names)
        outer_observations = [];
        outer_means = [];
        outer_stds = [];
        for context = contexts
            inner_means = [];
            inner_stds = [];
            inner_observations = [];
            for assistance = assistances
                values = [];
                for foot = feet
                    data = result.MetricsData. ...
                        (metric_names{nmetric}){foot, context, assistance};
                    if strcmp('SW', metric_names{nmetric})
                        for instance = 1:5
                            values = [values; data{instance}];
                        end
                    else
                        for instance = 1:length(data)
                            values = [values; data{instance}];
                        end
                    end
                end
                inner_means = [inner_means; mean(values)];
                inner_stds = [inner_stds; std(values)];
                inner_observations = [inner_observations; values];
            end
            outer_means = [outer_means, inner_means];
            outer_stds = [outer_stds, inner_stds];
            outer_observations = [outer_observations, inner_observations];
        end
        if ~isempty(outer_observations)
            nmbob = size(outer_observations,1)/length(assistances);
            [~,~,stats] = anova2(outer_observations, nmbob, 'off');
            col_diffs = multcompare(stats, 'Estimate', 'column', 'Display', 'off');
            row_diffs = multcompare(stats, 'Estimate', 'row', 'Display', 'off');

            % Create the metric.
            Metrics.(metric_names{nmetric}) = MetricStats2D(metric_names{nmetric}, ...
                outer_observations, nmbob, 'control', 'context');
        end
    end
end

% Save the final result.
save(save_dir, 'Metrics');