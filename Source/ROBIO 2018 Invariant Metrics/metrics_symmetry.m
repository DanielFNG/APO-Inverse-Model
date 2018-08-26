% The directory where the subject data is stored (as Matlab data).
load_dir = 'C:\Users\Daniel\Documents\Dropbox\PhD\Francois Data';

% The parameters we want to look at data for. 
subjects = 8;
contexts = 1:5;
assistances = 1:3;

save_dir = [load_dir filesep 'metrics_symmetry.mat'];

% Load the subjects and store the metric information for each subject only.
for subject = subjects
    result = loadSubject(load_dir, subject);
    metric_names = fieldnames(result.MetricsData);
    outer_observations = [];
    outer_means = [];
    outer_stds = [];
    for nmetric = 1:length(metric_names)
        inner_means = [];
        inner_stds = [];
        inner_observations = [];
        for assistance = assistances
            values = [];
            for context = contexts
                right = result.MetricsData. ...
                    (metric_names{nmetric}){1, context, assistance};
                left = result.MetricsData. ...
                    (metric_names{nmetric}){2, context, assistance};
                limit = 5;
                for instance = 1:limit
                    data = abs((left{instance} - right{instance})/(0.5*(left{instance} + right{instance})));
                    values = [values; data];
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
        Metrics = MetricStats2D('symmetry', ...
            outer_observations, nmbob, 'control', 'metric', {'P1', 'P2', 'A'}, metric_names);
    end
end

% Save the final result.
save(save_dir, 'Metrics');