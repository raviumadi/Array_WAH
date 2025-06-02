% simulate_batcall_localisation.m
% ===============================
% This script runs a grid-based localisation simulation of bat echolocation calls
% using various microphone array configurations. It generates mic arrays, visualises
% them, runs the simulation via the `BatCallLocaliser` class, and exports results.
%
% Dependencies:
%   - mic_array_configurator.m   (for generating and managing mic arrays)
%   - BatCallLocaliser.m         (for running the signal simulation and localisation)
%
% Parameters:
% ----------
% Simulation:
%   fs          — Sampling rate [Hz]
%   d           — Duration of the call signal [s]
%   f0          — Start frequency of chirp [Hz]
%   f1          — End frequency of chirp [Hz]
%   tail        — Percentage of tail signal after chirp end
%   snr_db      — Signal-to-noise ratio in decibels
%   micSpacing  — Characteristic spacing or edge length between microphones [m]
%
% Grid:
%   x_vals, y_vals, z_vals — 3D spatial grid to simulate source positions [m]
%
% Microphone Configurations:
%   config_names — List of array geometries to simulate
%   nMics        — Corresponding number of mics for each geometry
%
% Workflow:
% ---------
% For each microphone configuration:
%   1. Instantiate a `mic_array_configurator` with the given geometry.
%   2. Visualise and save the array layout (optional).
%   3. Export mic positions as a `.csv` (optional).
%   4. Pass the mic positions to `BatCallLocaliser`.
%   5. Run a spatial grid sweep to localise simulated calls.
%   6. Save localisation results to `results/` as `.csv`.
%
% Output:
% -------
%   - Microphone array plots saved to `results/figures/`
%   - Microphone positions saved to `configs/`
%   - Localisation error summaries saved to `results/*.csv`
%
% Example:
% --------
%   Run this script directly to simulate all listed geometries.
%
% Author: Ravi Umadi
% Date: 2 June 2025
% License: CC BY-NC 4.0 (non-commercial use with attribution)

% Define shared simulation parameters
params = struct();
params.fs = 384e3;             % Sampling rate
params.d = 5/1000;             % Duration of call in seconds
params.f0 = 25000;             % Start frequency
params.f1 = 80000;             % End frequency
params.tail = 50;              % Tail % of signal
params.micSpacing = 0.5;       % Mic spacing or edge length in meters
params.snr_db = 60;            % SNR in dB

x_vals = -5:0.5:5;
y_vals = -5:0.5:5;
z_vals = -5:0.5:5;

% List of config names, and corresponding number of mics
config_names = {'Tetrahedron', 'Square (Planar)', 'Pyramid', 'Octahedron'};
nMics = [4, 4, 4, 6];

% Loop over configurations
for i = 1:length(config_names)
    config_name = config_names{i};
    fprintf("\n🔧 Running simulation for config: %s\n", config_name);

    % Generate microphone positions using the new class
    cfg = mic_array_configurator(nMics(i), config_name, params.micSpacing);
    cfg.plot(true, 'results/figures/');          % Optional: save visualisation
    cfg.saveToCSV('configs/');           % Optional: save config positions

    % Assign mic positions to params
    params.mic_positions = cfg.mic_positions;

    % Create localiser instance
    localiser = BatCallLocaliser(params);

    % Output filename
    outFile = fullfile('results', sprintf('%s.csv', strrep(config_name, ' ', '_')));

    % Run the simulation
    localiser.runGridSweep(x_vals, y_vals, z_vals, ...
        'srp', 0, ...
        'plotOn', 0, ...
        'csv_file', outFile);

    fprintf("✅ Saved results to %s\n", outFile);
end

disp("🎯 All configurations completed.");