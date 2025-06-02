function startup()
% startup.m
% Adds source directory to MATLAB path and checks requirements.

disp("🔧 Initialising Array WAH project...");

% Add source directory
src_path = fullfile(fileparts(mfilename('fullpath')), 'src');
if ~isfolder(src_path)
    error('Could not find "src/" directory. Please check the project structure.');
end
addpath(genpath(src_path));
disp(['Added to path: ', src_path]);

% Check required toolboxes
required_toolboxes = {'Statistics and Machine Learning Toolbox', 'Signal Processing Toolbox'};
v = ver;
installed = {v.Name};

missing = setdiff(required_toolboxes, installed);
if ~isempty(missing)
    fprintf('!!  Missing required toolbox(es):\n');
    for k = 1:length(missing)
        fprintf('  - %s\n', missing{k});
    end
    error('!! Please install the missing toolbox(es) before running the demos.');
end

disp("🎯 Initialisation complete. You can now run the demo scripts.");
end