validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
count = 0;
for scenario = 1:5
    p = parameters('strip'); p.nCells = 8; p.scanPoints = 15;
    if scenario == 2
        p = parameters('rod'); p.nCells = 8; p.scanPoints = 15; p.alphaDeg = 90;
    elseif scenario == 3
        p.nsmEnabled = false;
    elseif scenario == 4
        p.maxQ = .1;
    elseif scenario == 5
        p.localMaxIterations = 1;
    end
    p = cc19_validate(p);
    memory.bondMax = cell(p.nBars,2);
    memory.age = cell(p.nBars,2);
    memory.activated = cell(p.nBars,2);
    memory.failedFRP = false(p.nBars,1);
    memory.barFailure = repmat({''},p.nBars,1);
    memory.steelDamage = zeros(p.nSteel,1); memory.concreteDamage = 0;
    for bar = 1:p.nBars
        for side = 1:2
            memory.bondMax{bar,side} = zeros(p.nCells+1,1);
            memory.age{bar,side} = zeros(p.nCells+1,1);
            memory.activated{bar,side} = false(p.nCells+1,1);
        end
    end
    old = cc19_critical(p,memory);
    new = capacity_scan(p,memory);
    assert(isequaln(old,new));
    fprintf('scenario=%d: exact match, status=%s\n',scenario,new.status);
    count = count + 1;
end
fprintf('ALL%d_CAPACITY_CHECKS_PASSED: exact curve, peak, location and status.\n',count);
