% demo_wah_analyzer.m
% ====================
% This script demonstrates the complete analysis pipeline using the `wah_analyzer` class
% to evaluate microphone array localisation performance across different configurations.
% It loads simulation results, filters by position and angular error thresholds,
% visualises results, and performs statistical comparisons.
%
% Dependencies:
% -------------
%   - wah_analyzer.m   (the main analysis class)
%   - Result CSVs produced by `BatCallLocaliser`
%
% Parameters:
% -----------
%   cm_thresh     — Position error threshold (in cm) to classify inliers
%   deg_thresh    — Angular error threshold (in degrees) to classify inliers
%   results_path  — Folder where result CSVs and output figures will be saved
%   csv_files     — List of input CSV filenames (from localisation simulations)
%
% Analysis Workflow:
% ------------------
% 1. Instantiate the `wah_analyzer` object with thresholds and file paths
% 2. Load and analyse all localisation result files
% 3. Plot 3D scatterplots of position and angular errors
% 4. Export selected figures manually (optional PDF export)
% 5. Plot grouped histograms (e.g. error distributions across arrays)
% 6. Plot boxplots separating inliers and outliers
% 7. Generate Z-slice contour maps of error distribution
% 8. Perform one-way ANOVA and posthoc tests across configs
% 9. Access inlier and outlier data tables directly
%
% Output:
% -------
%   - Figures saved in `/results/figures/` (PDF and PNG formats)
%   - Tables of inliers and outliers accessible via `wa.T_in` and `wa.T_out`
%   - Statistical summary tables printed to console and optionally exported
%
% Example:
% --------
%   Run this script after generating localisation results from multiple configs:
%     >> run demo_wah_analyzer
%
% Author: Ravi Umadi  
% Date: 2 June 2025  
% License: MIT (or CC BY-NC 4.0, depending on distribution context)

% Thresholds
cm_thresh = 10;       % cm
deg_thresh = 2;       % degrees

% Results folder (where CSVs and figures are saved)
results_path = 'results';

% CSV files (optional: will prompt if left empty)
csv_files = {
    'results/Tetrahedron.csv', ...
    'results/Square_(Planar).csv', ...
    'results/Pyramid.csv', ...
    'results/Octahedron.csv'
};

% === 1. Create analyzer object ===
wa = wah_analyzer(cm_thresh, deg_thresh, results_path, csv_files);

% === 2. Run initial analysis (loads data and computes errors) ===
wa = wa.runFullAnalysis();

% === 3. Plot combined 3D scatterplots of position/angular error ===
wa.plotCombinedScatter();

% Manually export one of the generated figures (example)
f = figure(1);  % Or use gcf if that figure is active
wa.exportFigure(f, "combined_scatter_xyz", true);  % Set to false to skip PDF

% === 4. Plot summary histograms (to be implemented) ===
wa.plotSummaryFigures();  % Will plot grouped histograms for all configs

% === 5. Plot error boxplots (to be implemented) ===
wa.plotErrorBoxplots();  % Will separate inliers vs outliers in boxplots

% === 6. Plot z-slice contour maps (to be implemented) ===
wa.plotZSlicePositionErrors();  % For position errors per Z-slice
wa.plotZSliceAngularErrors();   % For angular errors per Z-slice

% === 7. Perform and display ANOVA + posthoc comparisons ===
wa.runStatisticalAnalysis();  % Requires all data parsed (T_all table)

% === 8. Access inlier/outlier tables for custom use ===
disp("Sample of inlier table:");
disp(wa.T_in(1:5, :));

disp("Sample of outlier table:");
disp(wa.T_out(1:5, :));