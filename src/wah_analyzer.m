classdef wah_analyzer
% WAH_ANALYZER Analyze and visualize TDOA localization simulation results
%
%   The wah_analyzer class loads simulation results from CSV files
%   containing TDOA-based source localization estimates, and provides
%   a full suite of plotting, statistical analysis, and export utilities
%   tailored for comparing microphone configurations.
%
%   Usage:
%       wa = wah_analyzer(cm_thresh, deg_thresh, results_path, csv_files);
%       wa = wa.runFullAnalysis();
%       wa.plotCombinedScatter();
%       wa.plotSummaryFigures();
%       wa.plotErrorBoxplots();
%       wa.plotZSlicePositionErrors();
%       wa.plotZSliceAngularErrors();
%       wa.runStatisticalAnalysis();
%       wa.exportFigure(gcf, 'filename', true);
%
%   Constructor Inputs:
%       cm_thresh      – Threshold for position error (in cm)
%       deg_thresh     – Threshold for angular error (in degrees)
%       results_path   – Path where results and figures will be saved
%       csv_files      – Cell array of CSV filenames (optional; if empty,
%                        user is prompted via UI)
%
%   Properties:
%       cm_thresh      – Centimeter threshold for inlier detection
%       deg_thresh     – Degree threshold for angular error inliers
%       results_path   – Path to base results folder
%       fig_path       – Subfolder for figure exports
%       stat_path      – Subfolder for statistics
%       csv_files      – List of CSV files used in the analysis
%       config_names   – Parsed names of each microphone configuration
%       T_in           – Table of inlier data
%       T_out          – Table of outlier data
%
%   Public Methods:
%       setThresholds(cm, deg)              – Change error thresholds
%       setPaths(results_path)              – Update output folder paths
%       runFullAnalysis()                   – Load and label inliers/outliers
%       plotCombinedScatter()               – 3D scatterplots of position/angular error
%       plotSummaryFigures()                – Histograms of error metrics
%       plotErrorBoxplots()                 – Boxplots by configuration
%       plotZSlicePositionErrors()          – Contour plots across Z slices (pos. error)
%       plotZSliceAngularErrors()           – Contour plots across Z slices (ang. error)
%       runStatisticalAnalysis()            – ANOVA + post-hoc stats
%       exportFigure(figHandle, name, pdf)  – Save .fig and optionally .pdf
%
%   Author: Ravi Umadi  
%   Version: 1.0  
%   Date: June 2025
    properties
        cm_thresh double
        deg_thresh double
        results_path string
        fig_path string
        stat_path string
        csv_files cell
        config_names cell
        T_in table
        T_out table
    end

    methods
        function obj = wah_analyzer(cm_thresh, deg_thresh, results_path, csv_files)
            if nargin < 3
                error('At least cm_thresh, deg_thresh, and results_path must be specified');
            end
            obj.cm_thresh = cm_thresh;
            obj.deg_thresh = deg_thresh;
            obj.results_path = results_path;
            obj.fig_path = fullfile(results_path, 'figures');
            obj.stat_path = fullfile(results_path, 'stats');
            if ~exist(obj.fig_path, 'dir'), mkdir(obj.fig_path); end
            if ~exist(obj.stat_path, 'dir'), mkdir(obj.stat_path); end

            if nargin < 4 || isempty(csv_files)
                [files, path] = uigetfile('*.csv', 'Select simulation CSV files', 'MultiSelect', 'on');
                if isequal(files, 0), error('No files selected.'); end
                if ischar(files), files = {files}; end
                obj.csv_files = fullfile(path, files);
            else
                if ischar(csv_files), csv_files = {csv_files}; end
                obj.csv_files = csv_files;
            end

            obj.config_names = obj.getConfigNames();
        end

        function obj = setThresholds(obj, cm, deg)
            obj.cm_thresh = cm;
            obj.deg_thresh = deg;
        end

        function obj = setPaths(obj, results_path)
            obj.results_path = results_path;
            obj.fig_path = fullfile(results_path, 'figures');
            obj.stat_path = fullfile(results_path, 'stats');
            if ~exist(obj.fig_path, 'dir'), mkdir(obj.fig_path); end
            if ~exist(obj.stat_path, 'dir'), mkdir(obj.stat_path); end
        end

        function names = getConfigNames(obj)
            names = cellfun(@(f) erase(erase(f, '.csv'), {'results/', '_'}), obj.csv_files, 'UniformOutput', false);
        end

        function obj = runFullAnalysis(obj)
            all_xyz_error_in = [];
            all_ang_error_in = [];
            all_config_in = {};
            all_xyz_error_out = [];
            all_ang_error_out = [];
            all_config_out = {};

            for f = 1:length(obj.csv_files)
                try
                    data = readtable(obj.csv_files{f});
                catch
                    warning('Could not read file: %s. Skipping.', obj.csv_files{f});
                    continue;
                end

                config_name = obj.config_names{f};
                data.xyz_error = sqrt((data.tdoaX - data.sourceX).^2 + (data.tdoaY - data.sourceY).^2 + (data.tdoaZ - data.sourceZ).^2);
                data.angle_error = sqrt((data.tdoaAz - data.sourceAz).^2 + (data.tdoaEl - data.sourceEl).^2);

                is_inlier = (data.xyz_error*100 <= obj.cm_thresh) & (data.angle_error <= obj.deg_thresh);
                inlier_data = data(is_inlier, :);
                outlier_data = data(~is_inlier, :);

                all_xyz_error_in = [all_xyz_error_in; inlier_data.xyz_error * 100];
                all_ang_error_in = [all_ang_error_in; inlier_data.angle_error];
                all_config_in = [all_config_in; repmat({config_name}, height(inlier_data), 1)];

                all_xyz_error_out = [all_xyz_error_out; outlier_data.xyz_error * 100];
                all_ang_error_out = [all_ang_error_out; outlier_data.angle_error];
                all_config_out = [all_config_out; repmat({config_name}, height(outlier_data), 1)];
            end

            obj.T_in = table(all_xyz_error_in, all_ang_error_in, all_config_in, 'VariableNames', {'PositionError_cm', 'AngularError_deg', 'Config'});
            obj.T_out = table(all_xyz_error_out, all_ang_error_out, all_config_out, 'VariableNames', {'PositionError_cm', 'AngularError_deg', 'Config'});
        end

        function plotCombinedScatter(obj)
            n = length(obj.csv_files);
            nRows = ceil(sqrt(n)); nCols = ceil(n / nRows);
            fig_xyz = figure('Name', 'Combined XYZ Error Scatterplots');
            fig_ang = figure('Name', 'Combined Angular Error Scatterplots');

            for f = 1:n
                try
                    data = readtable(obj.csv_files{f});
                catch; continue; end
                config_name = obj.config_names{f};
                data.xyz_error = sqrt((data.tdoaX - data.sourceX).^2 + (data.tdoaY - data.sourceY).^2 + (data.tdoaZ - data.sourceZ).^2);
                data.angle_error = sqrt((data.tdoaAz - data.sourceAz).^2 + (data.tdoaEl - data.sourceEl).^2);
                is_inlier = (data.xyz_error*100 <= obj.cm_thresh) & (data.angle_error <= obj.deg_thresh);
                inlier_data = data(is_inlier, :);

                figure(fig_xyz);
                subplot(nRows, nCols, f);
                scatter3(inlier_data.sourceX, inlier_data.sourceY, inlier_data.sourceZ, 60, inlier_data.xyz_error*100, 'filled', 'MarkerFaceAlpha', 0.4);
                colormap(jet); view(3); axis equal;
                title([config_name ' - Position Error (cm)']);
                xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
                obj.formatLatex(gca);

                figure(fig_ang);
                subplot(nRows, nCols, f);
                scatter3(inlier_data.sourceX, inlier_data.sourceY, inlier_data.sourceZ, 60, inlier_data.angle_error, 'filled', 'MarkerFaceAlpha', 0.4);
                colormap(turbo); view(3); axis equal;
                title([config_name ' - Angular Error (deg)']);
                xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
                obj.formatLatex(gca);
            end
        end

        function exportFigure(obj, figHandle, name, doPDF)
            savefig(figHandle, fullfile(obj.fig_path, name + ".fig"));
            if doPDF
                exportgraphics(figHandle, fullfile(obj.fig_path, name + ".pdf"), 'Resolution', 300);
            end
        end
    end

    methods
        function plotSummaryFigures(obj)
            T_inlier = obj.T_in;
            T_outlier = obj.T_out;
            fig_summary = figure('Name', 'Localisation Error Summary', 'Position', [200 200 1200 600]);

            for f = 1:length(obj.config_names)
                subplot(2, 4, f);
                hold on;
                edges = linspace(0, obj.cm_thresh*2, 21);
                histogram(T_inlier.PositionError_cm(strcmp(T_inlier.Config, obj.config_names{f})), edges, 'DisplayStyle', 'stairs', 'LineWidth', 1.5);
                histogram(T_outlier.PositionError_cm(strcmp(T_outlier.Config, obj.config_names{f})), edges, 'FaceColor', 'r', 'FaceAlpha', 0.3);
                title([obj.config_names{f} ' - Position Error']);
                xlabel('Error (cm)'); ylabel('Count');
                xlim([0 obj.cm_thresh*2]);
                obj.formatLatex(gca);
            end

            for f = 1:length(obj.config_names)
                subplot(2, 4, 4 + f);
                hold on;
                edges = linspace(0, obj.deg_thresh*2, 21);
                histogram(T_inlier.AngularError_deg(strcmp(T_inlier.Config, obj.config_names{f})), edges, 'DisplayStyle', 'stairs', 'LineWidth', 1.5);
                histogram(T_outlier.AngularError_deg(strcmp(T_outlier.Config, obj.config_names{f})), edges, 'FaceColor', 'r', 'FaceAlpha', 0.3);
                title([obj.config_names{f} ' - Angular Error']);
                xlabel('Error (deg)', 'Interpreter', 'latex'); ylabel('Count', 'Interpreter', 'latex');
                xlim([0 obj.deg_thresh*2]);
                obj.formatLatex(gca);
            end
        end

        function plotErrorBoxplots(obj)
            T_inlier = obj.T_in;
            T_outlier = obj.T_out;
            colorIn = [0 0.4470 0.7410];
            colorOut = [0.8500 0.3250 0.0980];
            figure('Name','Localisation Errors (Inliers and Outliers)', 'Position', [100 100 1200 600]);

            subplot(2,2,1);
            boxplot(T_inlier.PositionError_cm, T_inlier.Config, 'Colors', colorIn, 'Symbol', 'o');
            title('Position Error by Mic Configuration (Inliers)');
            ylabel('Error (cm)', 'Interpreter', 'latex');
            obj.shadeBoxes(colorIn);
            obj.addSampleSizes(T_inlier.Config);
            obj.formatLatex(gca);

            subplot(2,2,2);
            boxplot(T_inlier.AngularError_deg, T_inlier.Config, 'Colors', colorIn, 'Symbol', 'o');
            title('Angular Error by Mic Configuration (Inliers)');
            ylabel('Error (deg)', 'Interpreter', 'latex');
            obj.shadeBoxes(colorIn);
            obj.addSampleSizes(T_inlier.Config);
            obj.formatLatex(gca);

            subplot(2,2,3);
            boxplot(T_outlier.PositionError_cm, T_outlier.Config, 'Colors', colorOut, 'Symbol', 'o');
            title('Position Error by Mic Configuration (Outliers)');
            ylabel('Error (cm)', 'Interpreter', 'latex');
            obj.shadeBoxes(colorOut);
            obj.addSampleSizes(T_outlier.Config);
            obj.formatLatex(gca);

            subplot(2,2,4);
            boxplot(T_outlier.AngularError_deg, T_outlier.Config, 'Colors', colorOut, 'Symbol', 'o');
            title('Angular Error by Mic Configuration (Outliers)');
            ylabel('Error (deg)', 'Interpreter', 'latex');
            obj.shadeBoxes(colorOut);
            obj.addSampleSizes(T_outlier.Config);
            obj.formatLatex(gca);
        end

        function runStatisticalAnalysis(obj)
            T_inlier = obj.T_in;
            T_outlier = obj.T_out;
            T_inlier.Group = repmat("Inlier", height(T_inlier), 1);
            T_outlier.Group = repmat("Outlier", height(T_outlier), 1);
            T_all = [T_inlier; T_outlier];
            configs = unique(T_all.Config);
            groups = unique(T_all.Group);

            summaryStats = table('Size', [length(configs)*length(groups), 8], ...
                'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                'VariableNames', {'Config', 'Group', 'PosMean', 'PosMedian', 'PosStd', 'AngMean', 'AngMedian', 'AngStd'});

            row = 1;
            for i = 1:length(configs)
                for j = 1:length(groups)
                    subset = T_all(strcmp(T_all.Config, configs{i}) & strcmp(T_all.Group, groups{j}), :);
                    posErr = subset.PositionError_cm;
                    angErr = subset.AngularError_deg;
                    summaryStats.Config(row) = configs(i);
                    summaryStats.Group(row) = groups(j);
                    summaryStats.PosMean(row) = mean(posErr, 'omitnan');
                    summaryStats.PosMedian(row) = median(posErr, 'omitnan');
                    summaryStats.PosStd(row) = std(posErr, 'omitnan');
                    summaryStats.AngMean(row) = mean(angErr, 'omitnan');
                    summaryStats.AngMedian(row) = median(angErr, 'omitnan');
                    summaryStats.AngStd(row) = std(angErr, 'omitnan');
                    row = row + 1;
                end
            end

            disp('=== Summary Statistics by Configuration and Group ===');
            disp(summaryStats);

            [pPos,~,statsPos] = anovan(T_all.PositionError_cm, {T_all.Config, T_all.Group}, 'model', 'interaction', 'display', 'off');
            fprintf('ANOVA p-values for Position Error:');
            fprintf('Config: %.4f, Group: %.4f, Interaction: %.4f', pPos);

            [pAng,~,statsAng] = anovan(T_all.AngularError_deg, {T_all.Config, T_all.Group}, 'model', 'interaction', 'display', 'off');
            fprintf('ANOVA p-values for Angular Error:');
            fprintf('Config: %.4f, Group: %.4f, Interaction: %.4f', pAng);

            if any(pPos < 0.05)
                fprintf('Post-hoc comparison for Position Error:');
                multcompare(statsPos, 'Dimension', 1, 'Display', 'off');
                multcompare(statsPos, 'Dimension', 2, 'Display', 'off');
            end
            if any(pAng < 0.05)
                fprintf('Post-hoc comparison for Angular Error:');
                multcompare(statsAng, 'Dimension', 1, 'Display', 'off');
                multcompare(statsAng, 'Dimension', 2, 'Display', 'off');
            end
        end
    end
        methods
        function plotZSlicePositionErrors(obj, grid_res, cm_clip)
            if nargin < 2, grid_res = 0.1; end
            if nargin < 3, cm_clip = 50; end
            z_slices = [-5:-1 1:5];
            total_rows = length(obj.config_names) * 2;
            total_cols = length(z_slices) / 2;

            figure('Name', 'Position Error Contour Maps by Config and Z slice', 'Position', [100 100 1800 900]);
            t = tiledlayout(total_rows, total_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

            for f = 1:length(obj.csv_files)
                try
                    data = readtable(obj.csv_files{f});
                catch
                    continue;
                end
                config_name = obj.config_names{f};
                data.xyz_error = sqrt((data.tdoaX - data.sourceX).^2 + (data.tdoaY - data.sourceY).^2 + (data.tdoaZ - data.sourceZ).^2);

                for i = 1:length(z_slices)
                    z_val = z_slices(i);
                    row = (f - 1)*2 + (z_val > 0) + 1;
                    col = abs(z_val);
                    tile_idx = (row - 1)*total_cols + col;
                    ax = nexttile(tile_idx);

                    slice_data = data(abs(data.sourceZ - z_val) < 0.1, :);
                    if height(slice_data) < 3
                        axis(ax, 'off'); continue;
                    end

                    xq = min(slice_data.sourceX)-0.5 : grid_res : max(slice_data.sourceX)+0.5;
                    yq = min(slice_data.sourceY)-0.5 : grid_res : max(slice_data.sourceY)+0.5;
                    [Xq, Yq] = meshgrid(xq, yq);
                    Zq = griddata(slice_data.sourceX, slice_data.sourceY, slice_data.xyz_error*100, Xq, Yq, 'natural');
                    Zq(Zq > cm_clip) = cm_clip;

                    contourf(ax, Xq, Yq, Zq, 20, 'LineColor', 'none');
                    colormap(ax, jet); caxis(ax, [0 cm_clip]); axis(ax, 'equal'); axis(ax, 'tight'); grid(ax, 'on');
                    subtitle(ax, sprintf('Z = %d m', z_val), 'FontWeight', 'bold');
                    if row == total_rows, xlabel(ax, 'X (m)'); else, ax.XTickLabel = []; end
                    if col == 1
                        ylabel(ax, 'Y (m)');
                        yl = ylim(ax); xlim_vals = xlim(ax);
                        text(ax, xlim_vals(1) - 6, mean(yl), config_name, 'Rotation', 90, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 16, 'Interpreter', 'latex');
                    else
                        ylabel(ax, '');
                    end
                    obj.formatLatex(ax);
                end
            end
            cb = colorbar();
            cb.Position = [0.95 0.1 0.02 0.8];
            ylabel(cb, 'Position Error (cm)', 'FontSize', 14, 'Interpreter', 'latex');
            cb.TickLabelInterpreter = 'latex';
        end

        function plotZSliceAngularErrors(obj, grid_res, deg_clip)
            if nargin < 2, grid_res = 0.1; end
            if nargin < 3, deg_clip = 10; end
            z_slices = [-5:-1 1:5];
            total_rows = length(obj.config_names) * 2;
            total_cols = length(z_slices) / 2;

            figure('Name', 'Angular Error Contour Maps by Config and Z slice', 'Position', [100 100 1800 900]);
            t = tiledlayout(total_rows, total_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

            for f = 1:length(obj.csv_files)
                try
                    data = readtable(obj.csv_files{f});
                catch
                    continue;
                end
                config_name = obj.config_names{f};
                data.angle_error = sqrt((data.tdoaAz - data.sourceAz).^2 + (data.tdoaEl - data.sourceEl).^2);

                for i = 1:length(z_slices)
                    z_val = z_slices(i);
                    row = (f - 1)*2 + (z_val > 0) + 1;
                    col = abs(z_val);
                    tile_idx = (row - 1)*total_cols + col;
                    ax = nexttile(tile_idx);

                    slice_data = data(abs(data.sourceZ - z_val) < 0.1, :);
                    if height(slice_data) < 3
                        axis(ax, 'off'); continue;
                    end

                    xq = min(slice_data.sourceX)-0.5 : grid_res : max(slice_data.sourceX)+0.5;
                    yq = min(slice_data.sourceY)-0.5 : grid_res : max(slice_data.sourceY)+0.5;
                    [Xq, Yq] = meshgrid(xq, yq);
                    Zq = griddata(slice_data.sourceX, slice_data.sourceY, slice_data.angle_error, Xq, Yq, 'natural');
                    Zq(Zq > deg_clip) = deg_clip;

                    contourf(ax, Xq, Yq, Zq, 20, 'LineColor', 'none');
                    colormap(ax, turbo); caxis(ax, [0 deg_clip]); axis(ax, 'equal'); axis(ax, 'tight'); grid(ax, 'on');
                    subtitle(ax, sprintf('Z = %d m', z_val), 'FontWeight', 'bold');
                    if row == total_rows, xlabel(ax, 'X (m)'); else, ax.XTickLabel = []; end
                    if col == 1
                        ylabel(ax, 'Y (m)');
                        yl = ylim(ax); xlim_vals = xlim(ax);
                        text(ax, xlim_vals(1) - 6, mean(yl), config_name, 'Rotation', 90, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 16, 'Interpreter', 'latex');
                    else
                        ylabel(ax, '');
                    end
                    obj.formatLatex(ax);
                end
            end
            cb = colorbar();
            cb.Position = [0.95 0.1 0.02 0.8];
            ylabel(cb, 'Angular Error (degrees)', 'FontSize', 14, 'Interpreter', 'latex');
            cb.TickLabelInterpreter = 'latex';
        end

    end

    methods (Access = private)
        function formatLatex(~, ax)
            set(ax, 'TickLabelInterpreter', 'latex', 'FontSize', 16, 'FontWeight', 'bold');
            grid(ax, 'on'); grid(ax, 'minor');
            labels = {'XLabel', 'YLabel', 'ZLabel', 'Title', 'Subtitle'};
            for i = 1:length(labels)
                lbl = get(ax, labels{i});
                if ~isempty(get(lbl, 'String'))
                    set(lbl, 'Interpreter', 'latex', 'FontSize', 16, 'FontWeight', 'bold');
                end
            end
        end

        function shadeBoxes(~, color)
            ax = gca;
            boxes = findobj(ax, 'Tag', 'Box');
            for i = 1:length(boxes)
                patch(get(boxes(i), 'XData'), get(boxes(i), 'YData'), color, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
            end
        end

        function addSampleSizes(~, groups)
            ax = gca;
            positions = unique(get(ax, 'XTick'));
            configs = unique(groups, 'stable');
            for i = 1:length(configs)
                n = sum(strcmp(groups, configs{i}));
                yl = ylim;
                y_pos = yl(2) * 0.95;
                text(positions(i), y_pos, sprintf('n=%d', n), 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 16, 'Interpreter', 'latex');
            end
        end
    end
end
