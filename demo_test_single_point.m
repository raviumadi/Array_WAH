%% demo_test_single_point.m
% ------------------------------------------
% Demonstrates the use of `BatCallLocaliser.test()`
% on a single simulated source position
% You may also access the outputs 'result' and 'out' for all parameters.
% ------------------------------------------

clear; clc;

% --- Define Simulation Parameters ---
params = struct();
params.fs = 384e3;             % Sampling rate
params.d = 5e-3;               % Duration of call (5 ms)
params.f0 = 25000;             % Start frequency
params.f1 = 80000;             % End frequency
params.tail = 50;              % Tapering in percent
params.micSpacing = 0.5;       % Edge length of array in metres
params.snr_db = 60;            % Signal-to-noise ratio

% --- Microphone Configuration ---
cfg = mic_array_configurator(4, 'Tetrahedron', params.micSpacing);
params.mic_positions = cfg.mic_positions;

% --- Create Localiser ---
localiser = BatCallLocaliser(params);

% --- Define Source Location ---
source_position = [1.2, -0.8, 2.5];  % (in metres)

% --- Generate Call Signal and Propagate to Mics ---
result = localiser.simulate(source_position);

% --- Run Localisation Test ---
out = localiser.test(result, 0, 1);

% --- Compute True Azimuth & Elevation ---
ref_mic = params.mic_positions(1,:);
rel_vector = source_position - ref_mic;
az_true = atan2d(rel_vector(2), rel_vector(1));
el_true = asind(rel_vector(3) / norm(rel_vector));

% --- Angular Error ---
az_est = out.tdoa.azimuth;
el_est = out.tdoa.elevation;
ang_error = sqrt((az_true - az_est)^2 + (el_true - el_est)^2);

% --- Print Results ---
fprintf('\nGround Truth Source:     [%.2f, %.2f, %.2f] m\n', out.true_source);
fprintf('TDOA Estimate:           [%.2f, %.2f, %.2f] m\n', out.tdoa.position);
fprintf('Position Error:          %.2f cm\n', out.tdoa.error * 100);
fprintf('True Azimuth:            %.2f°,  True Elevation:       %.2f°\n', az_true, el_true);
fprintf('Estimated Azimuth:       %.2f°,  Estimated Elevation:  %.2f°\n', az_est, el_est);
fprintf('Angular Error:           %.2f°\n\n', ang_error);