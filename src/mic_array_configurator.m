classdef mic_array_configurator
% mic_array_configurator Class
% ============================
% This class generates, manages, visualises, and exports microphone array configurations
% for experimental setups and spatial audio analysis.
%
% Supported geometries for 4, 6, or 8 microphones include:
%   • Tetrahedron
%   • Square (Planar)
%   • Pyramid
%   • Octahedron
%   • Planar Hexagon
%   • Dual Tetrahedron
%   • Cube Corners
%   • Stacked Squares
%   • Spherical Shell
%
% Key Features
% ------------
% • Generate predefined mic configurations with a chosen geometry and edge length.
% • Manually load mic configurations from a CSV file (Nx3).
% • Automatically checks the validity of custom input files.
% • 3D visualisation of microphone positions with coloured markers, labels, and connecting lines.
% • Export figures to PNG and positions to CSV, with automatic folder creation.
%
% Constructor Syntax
% ------------------
%   cfg = mic_array_configurator(n_mics, config_name, edge_length)
%
% Parameters:
%   n_mics       — Number of microphones (4, 6, or 8)
%   config_name  — Name of configuration geometry (see above)
%   edge_length  — Characteristic length scale in metres
%
% Example:
%   cfg = mic_array_configurator(4, 'Tetrahedron', 0.1);
%   cfg.plot(true, 'results/figures/');
%   cfg.saveToCSV('results/configs/');
%
% Load From CSV
% -------------
%   cfg = mic_array_configurator();
%   cfg = cfg.loadFromCSV('path/to/mic_positions.csv');
%   cfg.plot();
%
% Methods
% -------
% • plot(save_flag, folder): Show and optionally export 3D figure of mic positions.
% • saveToCSV(folder): Save the current microphone positions to a .csv file.
% • loadFromCSV(filename): Load microphone positions from a file and infer config name.
%
% Notes
% -----
% • CSV input/output expects Nx3 format with columns: X, Y, Z.
% • Filenames are automatically generated from mic count and config name.
%
% Author: Ravi Umadi
% Created: 02.06.2025
% License: Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
    properties
        config_name string
        mic_positions double
        n_mics (1,1) double
        edge_length (1,1) double
    end

    methods
        function obj = mic_array_configurator(n_mics, config_name, edge_length)
            if nargin == 0
                return
            end
            obj.config_name = config_name;
            obj.edge_length = edge_length;
            obj.n_mics = n_mics;
            obj.mic_positions = obj.generateConfig(n_mics, config_name, edge_length);
        end

        function plot(obj, save_flag, folder)
            if nargin < 2, save_flag = false; end
            if nargin < 3, folder = pwd; end

            % Ensure parent directory exists
            [parent_folder, ~, ~] = fileparts(folder);
            if ~isempty(parent_folder) && ~exist(parent_folder, 'dir')
                mkdir(parent_folder);
            end

            % Ensure folder exists
            if ~exist(folder, 'dir')
                [success, msg] = mkdir(folder);
                if ~success
                    error('Failed to create folder: %s\nReason: %s', folder, msg);
                end
            end

            colors = lines(obj.n_mics);
            mp = obj.mic_positions;

            figure; hold on; grid on; axis equal;
            for j = 1:obj.n_mics
                scatter3(mp(j,1), mp(j,2), mp(j,3), 150, colors(j,:), 'filled');
                text(mp(j,1), mp(j,2), mp(j,3), sprintf('%d', j), 'FontSize', 14, ...
                    'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', 'Interpreter', 'latex');
            end

            for m1 = 1:obj.n_mics
                for m2 = m1+1:obj.n_mics
                    plot3([mp(m1,1), mp(m2,1)], [mp(m1,2), mp(m2,2)], [mp(m1,3), mp(m2,3)], 'k--');
                end
            end

            xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)', 'Interpreter', 'latex');
            title(sprintf('%d Microphones - %s Configuration', obj.n_mics, obj.config_name), 'FontSize', 14);
            obj.formatLatex(gca); view(3);

            if save_flag
                safe_name = strrep(obj.config_name, ' ', '_');
                exportgraphics(gcf, fullfile(folder, sprintf('%dmics_%s.png', obj.n_mics, safe_name)), 'Resolution', 300);
            end
        end

        function saveToCSV(obj, folder)
            if nargin < 2, folder = pwd; end

            % Ensure parent directory exists
            [parent_folder, ~, ~] = fileparts(folder);
            if ~isempty(parent_folder) && ~exist(parent_folder, 'dir')
                mkdir(parent_folder);
            end

            % Ensure folder exists
            if ~exist(folder, 'dir')
                [success, msg] = mkdir(folder);
                if ~success
                    error('Failed to create folder: %s\nReason: %s', folder, msg);
                end
            end

            safe_name = strrep(obj.config_name, ' ', '_');
            filename = fullfile(folder, sprintf('%dmics_%s.csv', obj.n_mics, safe_name));
            writematrix(obj.mic_positions, filename);
        end

        function obj = loadFromCSV(obj, filename)
            if ~isfile(filename), error('File not found: %s', filename); end
            data = readmatrix(filename);
            if size(data,2) ~= 3 || size(data,1) < 3
                error('Invalid mic configuration format. Expected Nx3 array.');
            end
            obj.mic_positions = data;
            obj.n_mics = size(data,1);
            [~, name, ~] = fileparts(filename);
            obj.config_name = strrep(name, '_', ' ');
        end
    end

    methods (Access = private)
        function pos = generateConfig(obj, n, name, L)
            pos = nan(n, 3);
            switch n
                case 4
                    if strcmpi(name, 'Tetrahedron')
                        pos = (L/sqrt(2)) * [1,1,1; -1,-1,1; -1,1,-1; 1,-1,-1];
                    elseif strcmpi(name, 'Square (Planar)')
                        pos = (L/2) * [-1 -1 0; -1 1 0; 1 -1 0; 1 1 0];
                    elseif strcmpi(name, 'Pyramid')
                        pos = L * [-0.5 -0.5 0; -0.5 0.5 0; 0.5 -0.5 0; 0 0 0.8];
                    else
                        error('Unknown 4-mic configuration: %s', name);
                    end
                case 6
                    if strcmpi(name, 'Octahedron')
                        pos = (L/2) * [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
                    elseif strcmpi(name, 'Planar Hexagon')
                        theta = linspace(0, 2*pi, 7); theta(end) = [];
                        pos = (L/2) * [cos(theta)', sin(theta)', zeros(6,1)];
                    elseif strcmpi(name, 'Dual Tetrahedron')
                        pos = L * [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
                    else
                        error('Unknown 6-mic configuration: %s', name);
                    end
                case 8
                    if strcmpi(name, 'Cube Corners')
                        [X,Y,Z] = ndgrid([-1,1]);
                        pos = (L/2) * [X(:), Y(:), Z(:)];
                    elseif strcmpi(name, 'Stacked Squares')
                        sq = (L/2) * [-1 -1 0; -1 1 0; 1 -1 0; 1 1 0];
                        pos = [sq; sq + [0 0 L/2]];
                    elseif strcmpi(name, 'Spherical Shell')
                        [theta, phi] = meshgrid(linspace(0, pi, 3), linspace(0, 2*pi, 4));
                        theta = theta(:); phi = phi(:);
                        x = sin(theta).*cos(phi); y = sin(theta).*sin(phi); z = cos(theta);
                        pos = (L/2) * [x(1:8), y(1:8), z(1:8)];
                    else
                        error('Unknown 8-mic configuration: %s', name);
                    end
                otherwise
                    error('Only 4, 6, or 8 microphones supported');
            end
        end

        function formatLatex(~, ax)
            set(ax, 'TickLabelInterpreter', 'latex', 'FontSize', 14, 'FontWeight', 'bold');
            grid(ax, 'on');
            grid(ax, 'minor');
            labels = {'XLabel', 'YLabel', 'ZLabel', 'Title', 'Subtitle'};
            for i = 1:length(labels)
                lbl = get(ax, labels{i});
                if ~isempty(get(lbl, 'String'))
                    set(lbl, 'Interpreter', 'latex', 'FontSize', 14, 'FontWeight', 'bold');
                end
            end
        end
    end
end