overall = zeros(1,10);
avg_by_context = zeros(10,5);
avg_by_assistance = zeros(10,3);
for i=1:10
    diff = metrics{i}.calculateRelativeDifferences();
    ThreeDBarWithErrorBars(diff, zeros(3,5), '% diff from baseline');
    title(metrics{i}.name)
    overall(1,i) = metrics{i}.calculateOverall();
    avg_by_context(i,1:5) = metrics{i}.calculate1DAvg('context');
    avg_by_assistance(i,1:3) = metrics{i}.calculate1DAvg('assistance');
end

% % For each metric, plot a 1D bar graph for avg over assistance.
% for i=1:10
%     figure
%     bar(1:5, avg_by_context(i,1:end))
% end
% 
% % For each metric, plot a 1D bar graph for avg over context. 
% for i=1:10
%     figure
%     bar(1:3, avg_by_assistance(i,1:end))
% end

% Plot 3D graphs for (metric, context).
x_axis.label = 'Walking context';
x_axis.ticks = {'BW','IW','DW','FW','SW'};
ThreeDBarForAvgs(...
    avg_by_context, zeros(10,5), '% diff from baseline', x_axis);
title('Variance averaged over assistance level')

% Plot 3D graphs for (metric, assistance).
x_axis.label = 'Assistance level';
x_axis.ticks = {'NE', 'ET', 'EA'};
ThreeDBarForAvgs(...
    avg_by_assistance, zeros(10,3), '% diff from baseline', x_axis);
title('Variance averaged over context')

% Set colours for the 2D avg plot. 
colours = {[0,0,153/255],[0,0,1],[102/255,102/255,1], [55/255, 153/255, 1], [153/255,201/255,1]};

% Sort the 1D averages from highest to lowest for 2D plotting. 
context_arrangement = [1:10,1:5];
assistance_arrangement = [1:10,1:3];
for i = 1:10
    [avg_by_context(i,1:5), context_arrangement(i,1:5)] = ...
        sort(avg_by_context(i,1:5),'descend');
    [avg_by_assistance(i,1:3), assistance_arrangement(i,1:3)] = ...
        sort(avg_by_assistance(i,1:3),'descend');
end

% Unsorted labels for use in the legend for use in the legend. 
unsorted_context = {'BW','IW','DW','FW','SW'};
unsorted_assistance = {'NE','ET','EA'};

% Plot the 2D average for context. 
c_fig = figure;
c_fig_ax = axes('Parent', c_fig);
hold on;
for i=1:10
    for j=1:5
        context_bar = bar(i, avg_by_context(i,j));
        set(context_bar, 'FaceColor', colours{context_arrangement(i,j)});
        sorted_context{j} = unsorted_context{context_arrangement(10,j)};
    end 
end
set(c_fig_ax, 'XTick', [1 2 3 4 5 6 7 8 9 10], 'XTickLabel', ...
    {'sw','sf','hr','hp','cpa','cpm','cv','cmm','cpa','mm'});
ylabel('% diff from baseline');
xlabel('Metric');
title('Variance averaged over assistance level');
legend(sorted_context)

% Plot the 2D average for assistance. 
a_fig = figure;
a_fig_ax = axes('Parent', a_fig);
hold on;
for i=1:10
    for j=1:3
        assistance_bar = bar(i, avg_by_assistance(i,j));
        set(...
            assistance_bar, 'FaceColor', colours{assistance_arrangement(i,j)});
        sorted_assistance{j} = unsorted_assistance{assistance_arrangement(10,j)};
    end
end
set(a_fig_ax, 'XTick', [1 2 3 4 5 6 7 8 9 10], 'XTickLabel', ...
    {'sw','sf','hr','hp','cpa','cpm','cv','cmm','cpa','mm'});
ylabel('% diff from baseline');
xlabel('Metric');
title('Variance averaged over context');
legend(sorted_assistance)

% Plot the overall average figure. 
ov = figure;
ov_ax = axes('Parent', ov);
ov = bar(overall);
set(ov_ax, 'XTick', [1 2 3 4 5 6 7 8 9 10], 'XTickLabel', ...
    {'sw','sf','hr','hp','cpa','cpm','cv','cmm','cpa','mm'});
ylabel('% diff from baseline');
xlabel('Metric');
title('Overall average');

