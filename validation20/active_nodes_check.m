validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir, 'code20'));
addpath(projectDir);
p = parameters('strip');
p.nBars = 2; p.nCells = 4;
threshold = p.activationFraction * p.deltaM;
peak.fields = cell(2,1); low.fields = cell(2,1);
memory.failedFRP = false(2,1);
memory.activated = cell(2,2);
for bar = 1:2
    for side = 1:2
        a.slip = [0; p.cyclicSlipTolerance; 2*p.cyclicSlipTolerance; .1; .2];
        a.maxSlip = [threshold; threshold; threshold; threshold*1.01; 0];
        b.slip = [0; 0; 0; .02; .3];
        peak.fields{bar}.sides{side} = a;
        low.fields{bar}.sides{side} = b;
        memory.activated{bar,side} = [false;true;true;false;true];
    end
end
count = 0;
for scenario = 1:8
    q = p; hi = peak; lo = low; m = memory;
    if scenario == 2
        q.Qmin = q.Qmax;
    elseif scenario == 3
        m.failedFRP(1) = true;
    elseif scenario == 4
        hi.fields{1} = [];
    elseif scenario == 5
        lo.fields{2} = [];
    elseif scenario == 6
        q.nBars = 0;
    elseif scenario == 7
        m.failedFRP(:) = true;
    elseif scenario == 8
        for bar = 1:2
            for side = 1:2
                hi.fields{bar}.sides{side}.slip(:) = 0;
                lo.fields{bar}.sides{side}.slip(:) = 0;
            end
        end
    end
    [a,b] = cc19_active(q,hi,lo,m);
    [c,d] = active_nodes(q,hi,lo,m);
    assert(isequaln(a,c) && isequaln(b,d));
    if scenario == 1
        assert(isequal(c{1,1}, [false;false;true;true;false]));
    end
    count = count + 1;
end
fprintf('ALL%d_ACTIVE_NODE_CHECKS_PASSED: exact masks and slip ranges, thresholds, history and skip cases.\n',count);
