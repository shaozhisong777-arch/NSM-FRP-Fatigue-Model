function figs = export_results(out, figs)
    % Plot and export the model results in one file.
    % out is returned by fatigue_calculate; figs is optional.
    % makePlots controls plotting; exportResults controls file writing.
    p = out.parameters;
    if nargin < 2
        figs = [];
    end
    if p.makePlots && isempty(figs)
        figs = make_plots(out);
    end
    if ~p.exportResults
        return
    end
    folder = p.outputDir;
    if ~exist(folder, 'dir')
        mkdir(folder);
    end
    % Save the complete structure in MAT and readable tables in CSV.
    save(fullfile(folder, 'results_NSM_shear.mat'), 'out', '-v7');
    write_csv(fullfile(folder, 'history.csv'), out.historyColumns, out.history);
    write_csv(fullfile(folder, 'initial_capacity.csv'), out.initialCapacity.columns, out.initialCapacity.curve);
    write_csv(fullfile(folder, 'NSM_crossings.csv'), ...
              {'x_mm', 'y_mm', 'Llower_mm', 'Lupper_mm', 'shape', 'alpha_rad'}, p.bars);
    for i = 1:numel(out.snapshots)
        snapshot = out.snapshots(i);
        N = snapshot.N;
        write_csv(fullfile(folder, sprintf('NSM_fields_N%d.csv', N)), ...
                  snapshot.field.columns, snapshot.field.NSMfields);
        write_csv(fullfile(folder, sprintf('stirrups_N%d.csv', N)), ...
                  {'x_mm', 'y_mm', 'shape', 'strain', 'stress_MPa', 'MinerDamage'}, snapshot.field.steel);
        crack = snapshot.field.crack;
        crackTable = zeros(numel(crack.y), 5);
        for node = 1:numel(crack.y)
            crackTable(node, 1) = crack.y(node);
            crackTable(node, 2) = crack.opening(node);
            crackTable(node, 3) = crack.sliding(node);
            crackTable(node, 4) = crack.verticalJump(node);
            crackTable(node, 5) = crack.horizontalJump(node);
        end
        write_csv(fullfile(folder, sprintf('crack_N%d.csv', N)), ...
                  {'y_mm', 'normalOpening_mm', 'tangentialSliding_mm', 'verticalJump_mm', 'horizontalJump_mm'}, ...
                  crackTable);
        % Save every bar failure flag, including bars with no current field.
        failureTable = zeros(p.nBars, 2);
        for bar = 1:p.nBars
            failureTable(bar, 1) = bar;
            failureTable(bar, 2) = double(snapshot.memory.failedFRP(bar));
        end
        write_csv(fullfile(folder, sprintf('NSM_failure_N%d.csv', N)), ...
                  {'bar', 'failed'}, failureTable);
    end
    for i = 1:numel(figs)
        print(figs(i), fullfile(folder, sprintf('figure_%02d.png', i)), '-dpng', '-r150');
    end
    file = fopen(fullfile(folder, 'status_and_sources.txt'), 'w');
    if file < 0
        error('cc19:export', 'Cannot write status file.');
    end
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, 'version=%s\nstatus=%s\n', p.codeVersion, out.status);
    fprintf(file, 'lastBalancedCycle=%g\nfailureCycle=%g\nfailureBracket=[%g,%g]\n', ...
            out.lastCycle, out.failureCycle, out.failureBracket);
    fprintf(file, 'historyRows=%d\nsnapshots=%d\n', size(out.history, 1), numel(out.snapshots));
    fprintf(file, 'calibration=%s\n%s\n', p.calibrationStatus, p.forceDefinition);
    fprintf(file, 'Qmax_N=%g\nQmin_N=%g\n', p.Qmax, p.Qmin);
    fprintf(file, 'rod/strip fatigue k=%g\nactivationFraction=%g\n', p.bondFatigueK, p.activationFraction);
    if isempty(out.history)
        fprintf(file, 'No balanced initial history. Inspect status, lastInfo and initial_capacity.csv.\n');
    else
        fprintf(file, 'maxGlobalForceResidual_N=%g\n', max(out.history(:, 10)));
        fprintf(file, 'maxLocalForceResidual_N=%g\n', max(out.history(:, 11)));
    end
    fprintf(file, 'Reaching Nmax is a runout, not a measured fatigue life. q is crack jump, not midspan deflection.\n');
    names = fieldnames(p.sourceNotes);
    for i = 1:numel(names)
        fprintf(file, '%s: %s\n', names{i}, p.sourceNotes.(names{i}));
    end
    for i = 1:p.nBars
        fprintf(file, 'bar_%d_failed=%d, reason=%s\n', i, out.memory.failedFRP(i), out.memory.barFailure{i});
    end
end

function figs = make_plots(out)
    % Plot global histories, then separate profiles for each bar and side.
    p = out.parameters;
    figs = [];
    history = out.history;
    if ~isempty(history)
        figs(end + 1) = figure('Name', '01 History', 'Position', [100 100 1000 800]);
        subplot(3, 1, 1);
        hold on;
        for column = 6:9
            plot(history(:, 1), history(:, column) / 1000, 'LineWidth', 1.3);
        end
        plot(history(:, 1), p.Qmax / 2000 + zeros(size(history, 1), 1), 'k--');
        grid on;
        ylabel('Shear (kN)');
        legend('Total', 'Concrete', 'Stirrups', 'NSM', 'Target', 'Location', 'northeast');
        title(strrep(out.status, '_', ' '));
        subplot(3, 1, 2);
        hold on;
        for column = 2:5
            plot(history(:, 1), history(:, column), 'LineWidth', 1.3);
        end
        grid on;
        ylabel('Crack jump (mm)');
        legend('q max', 'q min', 'Opening w', 'Sliding v', 'Location', 'northeast');
        subplot(3, 1, 3);
        semilogy(history(:, 1), max(history(:, 10:11), 1e-14), 'LineWidth', 1.2);
        hold on;
        semilogy(history(:, 1), p.forceTolerance + zeros(size(history, 1), 1), 'k--');
        grid on;
        xlabel('Cycles N');
        ylabel('Force residual (N)');
        legend('Beam', 'Anchor', 'Tolerance', 'Location', 'northeast');
    end
    curve = out.initialCapacity.curve;
    if ~isempty(curve)
        figs(end + 1) = figure('Name', '02 Initial capacity scan');
        hold on;
        for column = 2:5
            plot(curve(:, 1), curve(:, column) / 1000, 'LineWidth', 1.3);
        end
        plot(curve(:, 1), p.Qmax / 2000 + zeros(size(curve, 1), 1), 'k--');
        grid on;
        xlabel('Crack jump q (mm)');
        ylabel('Shear (kN)');
        legend('Total', 'Concrete', 'Stirrups', 'NSM', 'Target', 'Location', 'northeast');
        title('Initial sampled path - not a global capacity proof');
    end
    figs(end + 1) = figure('Name', '03 Geometry');
    hold on;
    plot([0 p.shearSpan p.shearSpan 0 0], [0 0 p.depth p.depth 0], 'k-');
    plot([p.crackOriginX p.crackTopX], [0 p.crackHeight], 'r-', 'LineWidth', 2);
    for i = 1:p.nBars
        bar = p.bars(i, :);
        direction = [-cos(bar(6)), sin(bar(6))];
        bottom = bar(1:2) - bar(3) * direction;
        top = bar(1:2) + bar(4) * direction;
        plot([bottom(1) top(1)], [bottom(2) top(2)], 'b-', 'LineWidth', 1.5);
        plot(bar(1), bar(2), 'bo', 'MarkerFaceColor', 'b');
    end
    for i = 1:p.nSteel
        plot([p.steel(i, 1) p.steel(i, 1)], [0 p.depth], 'k:');
    end
    axis equal;
    grid on;
    xlabel('x (mm)');
    ylabel('y from beam bottom (mm)');
    title(sprintf('%d crossed NSM lines per face; %d faces; %d stirrups', p.nBars, p.nsmFaces, p.nSteel));
    if isempty(out.snapshots)
        return
    end
    if p.nBars > 0
        % Reuse one local plotting function for the five anchor fields.
        figs(end + 1) = plot_anchor_fields(out, 'slip', 'Slip (mm)');
        figs(end + 1) = plot_anchor_fields(out, 'tau', 'Bond stress (MPa)');
        figs(end + 1) = plot_anchor_fields(out, 'strain', 'FRP strain');
        figs(end + 1) = plot_anchor_fields(out, 'tauM', 'Peak bond strength (MPa)');
        figs(end + 1) = plot_anchor_fields(out, 'age', 'Local cycles');
    end
    figs(end + 1) = figure('Name', 'Crack profiles');
    for i = 1:numel(out.snapshots)
        snapshot = out.snapshots(i);
        crack = snapshot.field.crack;
        label = sprintf('N=%g', snapshot.N);
        subplot(1, 2, 1);
        hold on;
        plot(crack.opening, crack.y, 'DisplayName', label, 'LineWidth', 1.2);
        subplot(1, 2, 2);
        hold on;
        plot(crack.sliding, crack.y, 'DisplayName', label, 'LineWidth', 1.2);
    end
    subplot(1, 2, 1);
    grid on;
    xlabel('Opening w (mm)');
    ylabel('y (mm)');
    legend('show');
    subplot(1, 2, 2);
    grid on;
    xlabel('Sliding v (mm)');
    ylabel('y (mm)');
    legend('show');
    if p.nSteel > 0
        figs(end + 1) = figure('Name', 'Stirrup stress');
        hold on;
        for i = 1:numel(out.snapshots)
            snapshot = out.snapshots(i);
            plot(p.steel(:, 1), snapshot.peak.steelStress, '-o', ...
                 'DisplayName', sprintf('N=%g', snapshot.N), 'LineWidth', 1.2);
        end
        grid on;
        xlabel('Stirrup position x (mm)');
        ylabel('Stress (MPa)');
        legend('show');
    end
end

function fig = plot_anchor_fields(out, field, axisLabel)
    % Use one subplot per bar and anchor side; x runs from crack to free end.
    p = out.parameters;
    fig = figure('Name', axisLabel, 'Position', [100 100 1000 700]);
    for bar = 1:p.nBars
        for side = 1:2
            subplot(p.nBars, 2, 2 * (bar - 1) + side);
            hold on;
            for i = 1:numel(out.snapshots)
                snapshot = out.snapshots(i);
                anchor = snapshot.peak.fields{bar};
                if isempty(anchor)
                    continue % Missing fields are skipped; failure flags are exported separately.
                end
                profile = anchor.sides{side};
                if strcmp(field, 'age')
                    value = snapshot.memory.age{bar, side};
                elseif strcmp(field, 'slip')
                    value = profile.slip;
                elseif strcmp(field, 'tau')
                    value = profile.tau;
                elseif strcmp(field, 'strain')
                    value = profile.strain;
                elseif strcmp(field, 'tauM')
                    value = profile.tauM;
                else
                    error('cc19:export', 'Unknown anchor field.');
                end
                plot(profile.x, value, 'LineWidth', 1.2, 'DisplayName', sprintf('N=%g', snapshot.N));
            end
            grid on;
            xlabel('Distance from crack (mm)');
            ylabel(axisLabel);
            title(sprintf('NSM %d / side %d', bar, side));
            legend('show', 'Location', 'northeast');
        end
    end
end

function write_csv(path, headers, data)
    file = fopen(path, 'w');
    if file < 0
        error('cc19:export', 'Cannot open %s.', path);
    end
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, '%s', headers{1});
    for i = 2:numel(headers)
        fprintf(file, ',%s', headers{i});
    end
    fprintf(file, '\n');
    % Write each value explicitly instead of formatting a transposed matrix.
    for row = 1:size(data, 1)
        for column = 1:size(data, 2)
            if column > 1
                fprintf(file, ',');
            end
            fprintf(file, '%.12g', data(row, column));
        end
        fprintf(file, '\n');
    end
end