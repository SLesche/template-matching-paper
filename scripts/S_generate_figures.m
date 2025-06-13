clear all;
load("saved_data/kathrinexp23_data.mat");
load("saved_data/kathrinexp23_times.mat");

addpath("../functions/")
time_vec_long = time_vec;
% Plot the figure for transformation
subject_number = 1; 
bin = 5;
example_ga = squeeze(mean(erp_data{1, 2, 5}(:, :, :, bin), 1));
example_erp = squeeze(erp_data{1, 2, 5}(subject_number, :, :, bin));
b = 1/1.1;
transformed_erp = interpolate_transformed_template(time_vec, example_erp, 1, b);
linear_transformed_erp = interpolate_shifted_template(time_vec, example_erp, 53.3);

plot(time_vec, example_erp, 'Color', "#0072BD")
hold on
plot(time_vec, linear_transformed_erp, 'Color', "#D95319")
% Add vertical dashed lines for peak latencies
[peak_val_original, peak_idx_original] = max(example_erp);
[peak_val_transformed, peak_idx_transformed] = max(transformed_erp);

peak_time_original = time_vec(peak_idx_original);
peak_time_transformed = time_vec(peak_idx_transformed);

xline(peak_time_original, 'Color', "#0072BD", 'LineStyle','--')
xline(peak_time_transformed, 'Color', "#D95319", 'LineStyle','--')

% Add legend with labels "original" and "transformed"
legend('original', 'transformed', 'Location', 'best')

% Add text annotations for peak values with slight offset
text_offset = 50;  % Offset in milliseconds
amp_offset = 0;

% Original ERP peak annotation
text(peak_time_original - text_offset, peak_val_original - amp_offset, sprintf('Peak at %.0fms', peak_time_original), ...
    'Color', "#0072BD", 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'right')

% Transformed ERP peak annotation
text(peak_time_transformed + text_offset, peak_val_transformed - amp_offset, sprintf('Peak at %.0f*%.1f = %.0fms', peak_time_original, 1/b, peak_time_transformed), ...
    'Color', "#D95319", 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left')

%axis([-200 800 -5 9]) % Achsen entsprechend des Signals anpassen 
%xlim([min(ga_x), max(ga_x)]);
set(gca, 'YDir','reverse') % Hier wird einmal die Achse gedreht -> Negativierung oben 

ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca,'TickDir','in'); 
ax.XRuler.TickLabelGapOffset = -20;    
Ylm=ylim;                          
Xlm=xlim;  
Xlb=0.90*Xlm(2);
Ylb=0.90*Ylm(1);
xlabel('ms','Position',[Xlb 1.5]); 
ylabel('µV','Position',[-100 Ylb]); 

hold off

hamming_weights = get_hamming_weights(time_vec, b, [250 700]);
tukey_weights = get_tukey_weights(time_vec, b, [250 700]);
norm_weights = get_normalized_weights(time_vec, example_ga, [250 700]);

% Plotting
plot(time_vec, example_ga, 'Color', "#0072BD", 'LineWidth', 1.5)  % Grand Average
hold on
plot(time_vec, hamming_weights, 'LineStyle', '--', 'Color', '#D95319', 'LineWidth', 1.2)  % Hamming Weights
plot(time_vec, tukey_weights, 'LineStyle', '--', 'Color', '#EDB120', 'LineWidth', 1.2)   % Tukey Weights
plot(time_vec, normalize_signal(norm_weights), 'LineStyle', '--', 'Color', '#7E2F8E', 'LineWidth', 1.2)  % Normalized Weights

% Add vertical line at specific x-values
xline(250, 'k--', 'LineWidth', 1.2)
xline(700, 'k--', 'LineWidth', 1.2)

% Legend
legend({'Grand Average', 'Hamming Weights', 'Tukey Weights', 'Normalized Weights'}, 'Location', 'southeast','FontSize', 8)

% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

% Customize appearance
%set(gca, 'LineWidth', 1)  % Set axis line width
%set(gca, 'FontSize', 12)     % Set font size for labels and ticks

hold off


% Create a new figure
figure;

% Subplot 1: Grand Average
subplot(2, 1, 1); % Create first subplot in a 2-row, 1-column grid
plot(time_vec, example_ga, 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
xline(250, 'k--', 'LineWidth', 1.2)
xline(700, 'k--', 'LineWidth', 1.2)
xlabel('ms');
ylabel('µV');
title('Grand Average');
set(gca, 'YDir', 'reverse', 'TickDir', 'in', 'LineWidth', 1.2);

% Subplot 2: Weighting Functions
subplot(2, 1, 2); % Create second subplot in the same grid
plot(time_vec, hamming_weights, '--', 'Color', '#D95319', 'LineWidth', 1.2)
hold on
plot(time_vec, tukey_weights, '--', 'Color', '#EDB120', 'LineWidth', 1.2)
plot(time_vec, normalize_signal(norm_weights), '--', 'Color', '#7E2F8E', 'LineWidth', 1.2)
xlabel('ms');
ylabel('Weight');
title('Weighting Functions');
legend({'Hamming', 'Tukey', 'Normalized'}, 'Location', 'southeast');
set(gca, 'YDir', 'normal', 'TickDir', 'in', 'LineWidth', 1.2);

filename = './presentations/images/weighting_functions_overview.png'; % Specify the desired file name
saveas(gcf, filename); % Save the current figure
% Adjust overall spacing
%sgtitle('Grand Average and Weighting Functions'); % Add main title for the figure


% Plotting grand averages
example_ga = squeeze(mean(erp_data{1, 2, 5}(:, :, :, bin), 1));

task_id = 1;
% plotting flanker
plot(time_vec, squeeze(mean(erp_data{task_id, 1, 5}(:, :, :, 5), 1)), 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
plot(time_vec, squeeze(mean(erp_data{task_id, 1, 5}(:, :, :, 6), 1)), 'Color', "#0072BD", 'LineWidth', 1.5, 'LineStyle','--')

plot(time_vec, squeeze(mean(erp_data{task_id, 2, 5}(:, :, :, 5), 1)), 'Color', "#D95319", 'LineWidth', 1.5)
plot(time_vec, squeeze(mean(erp_data{task_id, 2, 5}(:, :, :, 6), 1)), 'Color', "#D95319", 'LineWidth', 1.5, 'LineStyle','--')
legend({'Young - Congruent', 'Young - Incongruent', 'Old - Congruent', 'Old - Incongruent'}, 'Location', 'southeast');

% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off

condition = 5;
group = 2;
% plotting flanker
plot(time_vec, squeeze(mean(erp_data{task_id, group, 5}(:, :, :, condition), 1)), 'Color', "#D95319", 'LineWidth', 1.5)
hold on

latency = approx_peak_latency(time_vec, squeeze(mean(erp_data{task_id, group, 5}(:, :, :, condition), 1)), [250 700], 'positive');

xline(latency, 'Color', "magenta", 'LineWidth', 1.5, 'LineStyle', '--')
% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;
legend({'Old - Congruent', 'Peak Latency'}, 'Location', 'southeast');

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off

subject_number = 2;
bin = 1;

example_erp = squeeze(erp_data{1, 1, 5}(subject_number, :, :, bin));
% plotting flanker
plot(time_vec, example_erp, 'Color', "#0072BD", 'LineWidth', 1.5)
hold on

latency = approx_area_latency(time_vec, example_erp, [250 600], 'positive');

xline(latency, 'Color', "magenta", 'LineWidth', 1.5, 'LineStyle', '--')
% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')
% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;
legend({'Subject 2 - Congruent', 'Area Latency'}, 'Location', 'southeast');

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off

task_id = 2;
% plotting nback
plot(time_vec, squeeze(mean(erp_data{task_id, 1, 5}(:, :, :, 5), 1)), 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
plot(time_vec, squeeze(mean(erp_data{task_id, 1, 5}(:, :, :, 6), 1)), 'Color', "#0072BD", 'LineWidth', 1.5, 'LineStyle','--')

plot(time_vec, squeeze(mean(erp_data{task_id, 2, 5}(:, :, :, 5), 1)), 'Color', "#D95319", 'LineWidth', 1.5)
plot(time_vec, squeeze(mean(erp_data{task_id, 2, 5}(:, :, :, 6), 1)), 'Color', "#D95319", 'LineWidth', 1.5, 'LineStyle','--')
legend({'Young - 0-back', 'Young - 1-back', 'Old - 0-back', 'Old - 1-back'}, 'Location', 'southeast');

% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.5]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off

task_id = 3;
% plotting nback
plot(time_vec, squeeze(mean(erp_data{task_id, 1, 5}(:, :, :, 5), 1)), 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
plot(time_vec, squeeze(mean(erp_data{task_id, 1, 5}(:, :, :, 6), 1)), 'Color', "#0072BD", 'LineWidth', 1.5, 'LineStyle','--')

plot(time_vec, squeeze(mean(erp_data{task_id, 2, 5}(:, :, :, 5), 1)), 'Color', "#D95319", 'LineWidth', 1.5)
plot(time_vec, squeeze(mean(erp_data{task_id, 2, 5}(:, :, :, 6), 1)), 'Color', "#D95319", 'LineWidth', 1.5, 'LineStyle','--')
legend({'Young - Switch', 'Young - Repeat', 'Old - Switch', 'Old - Repeat'}, 'Location', 'southeast');

% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.5]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off


% Grand average of flanker task ( whole sample)
load("saved_data/exp23_times.mat");
load("saved_data/exp23_data.mat");

erps = zeros(length(time_vec), 142);
for i = 1:142
    erps(:, i) = squeeze(mean(sliced_trials{1,4, 1}{i}, 3));
end

ga = mean(erps, 2);


% Plot GA and latency choices
plot(time_vec, ga, 'Color', "#0072BD", 'LineWidth', 1.5)
% Legend
%legend({'Grand Average'}, 'Location', 'southeast')

% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);


peak_lat = approx_peak_latency(time_vec, ga, [250 700], 'positive');
area_lat = approx_area_latency(time_vec, ga, [250 700], 'positive', 0.5, true);

% Get some fit statistic examples
window = [250 700];
time_vec = time_vec_long;
% Good fit 
subject_number = 10;
bin = 5;

example_erp = squeeze(erp_data{1, 2, 5}(subject_number, :, :, bin));

example_ga = squeeze(mean(erp_data{1, 2, 5}(:, :, :, bin), 1));

lat_ga = approx_area_latency(time_vec, example_ga, window, 'positive', 0.5, true);

params = run_multi_start(define_optim_problem(specify_objective_function(time_vec_long', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, @eval_sum_of_squares, @(x) x ,@(a, b) 1)));

fit_latency = return_matched_latency(params(2), lat_ga);
fit_statistic = get_fits(time_vec_long', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, params(1), params(2));

% plotting flanker
plot(time_vec_long, example_erp, 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
xline(fit_latency, 'Color', "magenta", 'LineWidth', 1.5, 'LineStyle', '--')
plot(time_vec_long, interpolate_transformed_template(time_vec_long, example_ga, 1/params(1), 1/params(2)), 'Color', "#D95319",'LineWidth', 1.5)
% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off
% Bad fit
subject_number = 6;
bin = 5;

example_ga = squeeze(mean(erp_data{1, 2, 5}(:, :, :, bin), 1));

example_erp = squeeze(erp_data{1, 2, 5}(subject_number, :, :, bin));

params = run_multi_start(define_optim_problem(specify_objective_function(time_vec', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, @eval_sum_of_squares, @(x) x , @exponential_penalty)));

fit_latency = return_matched_latency(params(2), lat_ga);
fit_statistic = get_fits(time_vec', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, params(1), params(2));

fit_statistic(1)
% plotting flanker
plot(time_vec, example_erp, 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
xline(fit_latency, 'Color', "magenta", 'LineWidth', 1.5, 'LineStyle', '--')
plot(time_vec, interpolate_transformed_template(time_vec, example_ga, 1/params(1), 1/params(2)), 'Color', "#D95319",'LineWidth', 1.5)
% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off

% Just noise
y1 = 1 * sin(2 * pi * 13/1000 * time_vec + 30);
y2 = 1.1 * sin(2 * pi * 16/1000 * time_vec + 10);
y3 = 0.6 * sin(2 * pi * 3/1000 * time_vec + 50);
y = y1 + y2 + y3;
plot(time_vec, y)

example_ga = squeeze(mean(erp_data{1, 2, 5}(:, :, :, bin), 1));

example_erp = y;

params = run_multi_start(define_optim_problem(specify_objective_function(time_vec', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, @eval_sum_of_squares, @(x) x , @exponential_penalty)));

fit_latency = return_matched_latency(params(2), lat_ga);
fit_statistic = get_fits(time_vec', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, params(1), params(2));

fit_statistic(1)
% plotting flanker
plot(time_vec, example_erp, 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
xline(fit_latency, 'Color', "magenta", 'LineWidth', 1.5, 'LineStyle', '--')
plot(time_vec, interpolate_transformed_template(time_vec, example_ga, 0.6, 1/params(2)), 'Color', "#D95319",'LineWidth', 1.5)
% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off


% Plot for paper (introduction)
subject_number = 4;
bin = 5;

example_ga = squeeze(mean(erp_data{1, 2, 5}(:, :, :, bin), 1));
lat_ga = approx_area_latency(time_vec, example_ga, window, 'positive', 0.5, true);

example_erp = squeeze(erp_data{1, 2, 5}(subject_number, :, :, bin));

params = run_multi_start(define_optim_problem(specify_objective_function(time_vec', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, @eval_sum_of_squares, @(x) x , @exponential_penalty)));

fit_latency = return_matched_latency(params(2), lat_ga);
fit_statistic = get_fits(time_vec', example_erp, example_ga, [window(1) window(2)], 'positive', @get_normalized_weights, params(1), params(2));

fit_statistic(1)
% plotting flanker
plot(time_vec, example_erp, 'Color', "#0072BD", 'LineWidth', 1.5)
hold on
xline(fit_latency, 'Color', "#D95319", 'LineWidth', 1.5, 'LineStyle', '--')
plot(time_vec, example_ga, 'Color', '#7E2F8E', 'LineWidth', 1.5, 'LineStyle', '-.')
xline(lat_ga, 'Color', '#7E2F8E', 'LineWidth', 1.5, 'LineStyle', "--")
plot(time_vec, interpolate_transformed_template(time_vec, example_ga, 1/params(1), 1/params(2)), 'Color', "#D95319",'LineWidth', 1.5)


% Original ERP peak annotation
text(lat_ga + 50, 4.3, sprintf('P3 at %.0fms', lat_ga), ...
    'Color', "#7E2F8E", 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left')

% Transformed ERP peak annotation
text(fit_latency - 50, 4.5, sprintf('P3 at %.0f*%.1f = %.0fms', lat_ga, params(2), fit_latency), ...
    'Color', "#D95319", 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'right')

legend({'Subject ERP', 'Transformed Template', 'Template (Grand Average)'}, 'Location', 'northeast');

% Reverse Y-axis direction
set(gca, 'YDir', 'reverse')

% Set X and Y axis properties
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
set(gca, 'TickDir', 'in')
ax.XRuler.TickLabelGapOffset = -20;

% Adjust labels position
Ylm = ylim;
Xlm = xlim;
Xlb = 0.90 * Xlm(2);
Ylb = 0.90 * Ylm(1);
xlabel('ms', 'Position', [Xlb 0.75]);
ylabel('µV', 'Position', [-100 Ylb]);

hold off