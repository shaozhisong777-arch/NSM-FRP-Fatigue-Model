validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir, 'code20'));
addpath(projectDir);
p = parameters('strip');
s = [0 realmin/2 p.deltaM/2 p.deltaM p.deltaM+eps(p.deltaM) ...
     (p.deltaM+p.deltaU)/2 p.deltaU p.deltaU+eps(p.deltaU) 2*p.deltaU];
count = 0;
for shape = 1:3
    if shape == 1
        slips = s;
    elseif shape == 2
        slips = s';
    else
        slips = reshape(s, 3, 3);
    end
    peaks = {p.tauM0, 0, -1, p.tauR/2, ...
             reshape(linspace(-1, p.tauM0, numel(s)), size(slips))};
    for item = 1:numel(peaks)
        [oldTau, oldK, oldZone] = cc19_propagate(p, slips, peaks{item});
        [newTau, newK, newZone] = bond(p, slips, peaks{item});
        assert(isequaln(oldTau, newTau));
        assert(isequaln(oldK, newK));
        assert(isequaln(oldZone, newZone));
        count = count + 1;
    end
end
for slips = {[], zeros(0,1)}
    [a,b,c] = cc19_propagate(p,slips{1},1);
    [d,e,f] = bond(p,slips{1},1);
    assert(isequaln(a,d) && isequaln(b,e) && isequaln(c,f));
    count = count + 1;
end
badCases = {{[-1 0],1},{[NaN 0],1},{[Inf 0],1},{[0 1],ones(2,1)}};
for item = 1:numel(badCases)
    inputs = badCases{item};
    oldId = ''; newId = '';
    try
        cc19_propagate(p,inputs{1},inputs{2});
    catch err
        oldId = err.identifier;
    end
    try
        bond(p,inputs{1},inputs{2});
    catch err
        newId = err.identifier;
    end
    assert(~isempty(oldId) && strcmp(oldId,newId));
    count = count + 1;
end
fprintf('ALL%d_BOND_CHECKS_PASSED: exact stress, stiffness, zone, shapes and error identifiers.\n',count);
