function out = read_and_calculate(kind, overrides)
    % Read parameters, apply overrides, run the calculation, and export results.
    % Example: out = read_and_calculate('strip');
    % Example: out = read_and_calculate('strip', struct('Nmax', 100, 'makePlots', false));
    if nargin < 1
        kind = 'strip';
    end
    if nargin < 2
        overrides = struct();
    end
    if ~isstruct(overrides) || ~isscalar(overrides)
        error('cc19:input', 'Overrides must be a scalar struct.');
    end
    p = parameters(kind);
    names = fieldnames(overrides);
    for i = 1:numel(names)
        if ~isfield(p, names{i})
            error('cc19:input', 'Unknown option: %s', names{i});
        end
        p.(names{i}) = overrides.(names{i});
    end
    out = cc19_run(p);
    % Plotting and file export are handled by cc19_export.
    if p.makePlots || p.exportResults
        cc19_export(out);
    end
end
