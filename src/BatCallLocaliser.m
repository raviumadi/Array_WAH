classdef BatCallLocaliser
    properties
        param
        mic_positions
    end

    methods
        function obj = BatCallLocaliser(param)
            obj.param = param;
            if isfield(param, 'mic_positions')
                obj.mic_positions = param.mic_positions;
            else
                spacing = param.micSpacing;
                obj.mic_positions = spacing * [
                    0, 0, 0;
                    1, 0, 0;
                    0.5, sqrt(3)/2, 0;
                    0.5, sqrt(3)/6, sqrt(6)/3
                    ];
            end
        end

        function result = simulate(obj, source_xyz)
            fs = obj.param.fs;
            d = obj.param.d;
            f0 = obj.param.f0;
            f1 = obj.param.f1;
            tail = obj.param.tail;
            snr_db = obj.param.snr_db;
            c = 343;
            call = obj.generateVirtualBatCall(f0, f1, d, fs, tail);
            call_noisy = awgn(call, snr_db, 'measured');

            mic_pos = obj.mic_positions;
            num_mics = size(mic_pos, 1);
            delays = zeros(num_mics, 1);
            distances = zeros(num_mics, 1);
            for i = 1:num_mics
                distances(i) = norm(source_xyz - mic_pos(i,:));
                delays(i) = distances(i) / c;
            end
            delays = delays - delays(1);

            Nfft = 2^nextpow2(length(call_noisy));
            f = fs * (0:Nfft/2) / Nfft;
            alpha = 0.0002 * (f / 1000).^2;

            max_delay = max(delays);
            total_samples = length(call) + ceil(max_delay * fs);
            mic_signals = zeros(num_mics, total_samples);

            for i = 1:num_mics
                d_i = distances(i);
                delay_samples = delays(i) * fs;
                X = fft(call_noisy, Nfft);
                X = X(:).';
                attenuation_db = alpha * d_i;
                attenuation_linear = 10.^(-attenuation_db / 20);
                attenuation_linear = attenuation_linear(:).';
                X_pos = X(1:Nfft/2+1);
                X_pos_att = X_pos .* attenuation_linear;
                X_att = [X_pos_att, conj(X_pos_att(end-1:-1:2))];
                x_att = real(ifft(X_att));
                x_att = x_att(1:length(call_noisy));

                geom_scale = 1 / d_i;
                geom_scale = geom_scale / (1 / distances(1));
                mic_signals(i,:) = geom_scale * obj.fractionalDelay(x_att, delay_samples, total_samples);
            end

            v = source_xyz - mic_pos(1,:);
            az = atan2d(v(2), v(1));
            el = asind(v(3)/norm(v));

            result = struct();
            result.signals = mic_signals';
            result.source_position = source_xyz;
            result.mic_positions = mic_pos;
            result.delays = delays;
            result.distances = distances;
            result.fs = fs;
            result.azimuth_deg = az;
            result.elevation_deg = el;
            result.param = obj.param;
        end

        function output = test(obj, result, srp, plotOn)
            true_src = result.source_position;
            signals = result.signals;
            mic_pos = result.mic_positions;
            fs = result.fs;
            c = 343;

            tdoa = obj.estimateTDOA(signals, fs);
            try
                est1 = obj.localiseTDOA(tdoa, mic_pos, c);
                err1 = norm(est1 - true_src);
                [az1, el1] = obj.computeAzEl(est1, mic_pos(1,:));
            catch
                est1 = NaN(1,3);
                err1 = NaN;
                az1 = NaN;
                el1 = NaN;
            end

            output = struct();
            output.true_source = true_src;
            output.tdoa = struct('position', est1, 'error', err1, 'azimuth', az1, 'elevation', el1);
            % Plot results
            if plotOn
                figure; hold on; grid on; axis equal
                scatter3(mic_pos(:,1), mic_pos(:,2), mic_pos(:,3), 100, 'ko', 'filled')
                plot3(true_src(1), true_src(2), true_src(3), 'gp', 'MarkerSize', 14, 'DisplayName', 'True Source');
                plot3(est1(1), est1(2), est1(3), 'rx', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'TDOA');
                if srp
                    plot3(est2(1), est2(2), est2(3), 'b+', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'SRP-PHAT');
                end
                hLeg = legend();  % Get current legend handle
                hLeg.Interpreter = 'latex';
                hLeg.FontSize = 14;
                hLeg.FontWeight = 'bold';
                xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)', 'Interpreter', 'latex', 'FontSize', 14, 'FontWeight', 'bold')
                title('Microphone Array and Estimated Source Positions')
                formatLatex(gca)
            end
        end

        function results = runGridSweep(obj, x_vals, y_vals, z_vals, varargin)
            p = inputParser;
            addParameter(p, 'srp', false);
            addParameter(p, 'plotOn', false);
            addParameter(p, 'csv_file', 'localisation_results.csv');
            parse(p, varargin{:});
            srp = p.Results.srp;
            csv_file = p.Results.csv_file;

            results = [];
            for x = x_vals
                for y = y_vals
                    for z = z_vals
                        try
                            result = obj.simulate([x, y, z]);
                            output = obj.test(result, srp, false);
                            results(end+1,:) = [output.true_source(1), output.true_source(2), output.true_source(3), result.azimuth_deg, result.elevation_deg, output.tdoa.position(1), output.tdoa.position(2), output.tdoa.position(3), output.tdoa.error * 100, output.tdoa.azimuth, output.tdoa.elevation];
                        catch err
                            warning("Failed for [%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f]: %s", output.true_source(1), output.true_source(2), output.true_source(3), result.azimuth_deg, result.elevation_deg, output.tdoa.position(1), output.tdoa.position(2), output.tdoa.position(3), err.message, output.tdoa.azimuth, output.tdoa.elevation);
                            results(end+1,:) = [output.true_source(1), output.true_source(2), output.true_source(3), result.azimuth_deg, result.elevation_deg, output.tdoa.position(1), output.tdoa.position(2), output.tdoa.position(3), z, NaN, NaN, NaN];
                        end
                    end
                end
            end

            T = array2table(results, 'VariableNames', {'sourceX', 'sourceY', 'sourceZ', 'sourceAz', 'sourceEl', 'tdoaX', 'tdoaY', 'tdoaZ', 'tdoa_error_cm', 'tdoaAz', 'tdoaEl'});
            writetable(T, csv_file);
            fprintf('Saved to %s\n', csv_file);
        end
    end

    methods (Static)
        function y = fractionalDelay(x, delay_samples, out_len)
            n = 0:length(x)-1;
            xi = n - delay_samples;
            y = interp1(n, x, xi, 'linear', 0);
            y = [y, zeros(1, max(0, out_len - length(y)))];
            y = y(1:out_len);
        end

        function tdoa = estimateTDOA(signals, fs)
            num_mics = size(signals, 2);
            tdoa = zeros(num_mics-1, 1);
            ref = signals(:,1);
            for i = 2:num_mics
                [c, lags] = xcorr(signals(:,i), ref, 'coeff');
                [~, idx] = max(abs(c));
                tdoa(i-1) = lags(idx) / fs;
            end
        end

        function pos = localiseTDOA(tdoa, mic_pos, c)
            ref_pos = mic_pos(1,:);
            rel_pos = mic_pos(2:end,:) - ref_pos;
            fun = @(x) vecnorm(rel_pos - x, 2, 2) - vecnorm(-x, 2, 2) - c * tdoa;
            x0 = mean(rel_pos, 1);
            opts = optimoptions('lsqnonlin', 'Display', 'off');
            pos = lsqnonlin(fun, x0, [], [], opts);
            pos = pos + ref_pos;
        end

        function [az, el] = computeAzEl(src, ref)
            v = src - ref;
            r = norm(v);
            if r == 0
                az = NaN;
                el = NaN;
            else
                az = atan2d(v(2), v(1));
                el = asind(v(3)/r);
            end
        end

        function call = generateVirtualBatCall(f0, f1, d, fs, tail)

            fmax = mean([f0,f1])-f0/3;

            % Create the linear chirp signal
            % t defines the time vector for the duration of the call
            t = 0:1/fs:d-1/fs;
            % Generate a linear chirp with frequencies sweeping from f0 to f1
            vel = chirp(t, f0, d, f1, 'quadratic');
            % Reverse the chirp to create a descending frequency sweep
            vel = fliplr(vel);

            % Generate the filter for spectral emphasis at fmax
            % Define the frequency bands and magnitudes for the yulewalk filter
            fb = [0 2*[f0 fmax f1] fs]./fs; % Normalized frequency bands
            m = [0 0 1 0 0];                % Magnitude response at specified bands
            % Generate the yulewalk filter coefficients
            [yb, ya] = yulewalk(4, fb, m);
            % Create an impulse response of the filter
            [h, ~] = impz(yb, ya, fs/1000);
            fmaxir = h;

            % Apply a Hanning window to the sweep signal to smooth transitions
            window = hanning(length(vel));
            vel = vel.*window';

            % Add silence before and after the call to simulate natural pauses
            call = [zeros(round((d*fs)*tail/100), 1); vel'; zeros(round((d*fs)*tail/100), 1)];
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
