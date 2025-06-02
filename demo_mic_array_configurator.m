% demo_mic_array_configurator.m
% =============================
% This script demonstrates the creation, visualisation, saving, and reloading
% of 3D microphone array configurations using the `mic_array_configurator` class.
%
% The script performs two main tasks:
%   1. Creates a predefined geometric array (e.g. Tetrahedron), plots it, and saves the layout to a `.csv`
%   2. Loads an existing `.csv` configuration and re-plots it
%
% Dependencies:
% -------------
%   - mic_array_configurator.m   (class definition file)
%
% Parameters:
% -----------
%   mic count     — Number of microphones (e.g. 4 for a tetrahedral array)
%   config name   — Named configuration ('Tetrahedron', 'Pyramid', etc.)
%   spacing       — Characteristic edge length (in metres)
%   plot folder   — Folder where plots are exported (optional)
%   .csv path     — File path to save/load microphone positions
%
% Workflow:
% ---------
% 1. Create a 4-mic tetrahedral array (0.1 m edge length)
% 2. Plot and save the geometry to a figure (PNG/PDF)
% 3. Save the configuration to a CSV file
% 4. Load the same configuration back from CSV
% 5. Re-plot it using the stored positions
%
% Output:
% -------
%   - Plots saved to `results/figures/`
%   - Microphone positions saved to `configs/`
%
% Example:
% --------
%   >> run demo_mic_array_configurator
%
% Author: Ravi Umadi  
% Date: 2 June 2025  
% License: CC BY-NC 4.0 (non-commercial use with attribution)
cfg = mic_array_configurator(4, 'Tetrahedron', 0.1);
cfg.plot(true, 'results/figures/');
cfg.saveToCSV('configs/');       % Save .csv file

% Load from a CSV and replot
cfg2 = mic_array_configurator();
cfg2 = cfg2.loadFromCSV('configs/4mics_Tetrahedron.csv');
cfg2.plot();                      % Plot loaded config