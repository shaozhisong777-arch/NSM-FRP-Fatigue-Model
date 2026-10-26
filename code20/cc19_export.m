function figs = cc19_export(out, figs)
    % 结果输出文件：绘图和写文件都集中在这里，不增加新的.m文件。
    % 输入out为cc19_run的结果；figs可省略。makePlots和exportResults分别控制图与文件。
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
    % MAT保留完整结构；CSV方便不熟悉MATLAB结构体时直接查看。
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
        write_csv(fullfile(folder, sprintf('crack_N%d.csv', N)), ...
                  {'y_mm', 'normalOpening_mm', 'tangentialSliding_mm', 'verticalJump_mm', 'horizontalJump_mm'}, ...
                  [crack.y, crack.opening, crack.sliding, crack.verticalJump, crack.horizontalJump]);
        % 已失效筋后续可能没有局部场，因此另外保留全部筋的失效标志。
        write_csv(fullfile(folder, sprintf('NSM_failure_N%d.csv', N)), ...
                  {'bar', 'failed'}, [(1:p.nBars)', double(snapshot.memory.failedFRP)]);
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
    % 先画全梁结果，再画沿每根筋、每个锚固侧的局部场；不把不同筋连成一条曲线。
    p = out.parameters;
    figs = [];
    history = out.history;
    if ~isempty(history)
        figs(end + 1) = figure('Name', '01 History', 'Position', [100 100 1000 800]);
        subplot(3, 1, 1);
        plot(history(:, 1), history(:, 6:9) / 1000, 'LineWidth', 1.3);
        hold on;
        plot(history(:, 1), p.Qmax / 2000 + zeros(size(history, 1), 1), 'k--');
        grid on;
        ylabel('Shear (kN)');
        legend('Total', 'Concrete', 'Stirrups', 'NSM', 'Target', 'Location', 'northeast');
        title(strrep(out.status, '_', ' '));
        subplot(3, 1, 2);
        plot(history(:, 1), history(:, [2 3 4 5]), 'LineWidth', 1.3);
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
        plot(curve(:, 1), curve(:, 2:5) / 1000, 'LineWidth', 1.3);
        hold on;
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
        % 同一个简单绘图函数重复调用五次，避免复制五份几乎相同的代码。
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
    % 每根NSM分成两个锚固侧，各画一个子图。横轴从裂缝处x=0指向自由端。
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
                    continue % 以前已失效的筋没有当前局部场，失效信息见NSM_failure_N*.csv。
                end
                profile = anchor.sides{side};
                if strcmp(field, 'age')
                    value = snapshot.memory.age{bar, side};
                else
                    value = profile.(field);
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
    if ~isempty(data)
        format = [repmat('%.12g,', 1, size(data, 2) - 1), '%.12g\n'];
        fprintf(file, format, data');
    end
end
