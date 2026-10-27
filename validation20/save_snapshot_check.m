validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
count = 0;
for scenario = 1:5
    p.nBars = 2;
    p.steel = [1 2 3; 4 5 6];
    p.crackHeight = 200; p.crackShapeExponent = 1.5;
    p.kinematicDenominator = 1; p.slidingRatio = .2; p.theta = pi/4;
    st.fields = cell(2,1);
    for bar = 1:2
        for side = 1:2
            n = 2 + bar + side;
            a.x = (1:n)'; a.slip = a.x*.01; a.maxSlip = a.slip+.1;
            a.tau = a.x*.2; a.tauM = a.x*.3;
            a.force = a.x*10; a.strain = a.x*.001; a.zone = ones(n,1)*side;
            st.fields{bar}.sides{side} = a;
            memory.age{bar,side} = a.x*100;
        end
    end
    memory.failedFRP = [false;true]; memory.steelDamage = [.1;.2];
    st.steelStrain = [.001;.002]; st.steelStress = [100;200]; st.q = .3;
    if scenario == 2
        st.fields{1} = [];
    elseif scenario == 3
        st.fields(:) = {[]};
    elseif scenario == 4
        p.nBars = 0;
    elseif scenario == 5
        p.steel = zeros(0,3); st.steelStrain = zeros(0,1);
        st.steelStress = zeros(0,1); memory.steelDamage = zeros(0,1);
    end
    st.memory = memory;
    % The archived snapshot uses the equivalent original crack function.
    old = cc19_sample(p,st,memory);
    new = save_snapshot(p,st,memory);
    implicit = save_snapshot(p,st);
    assert(isequaln(old,new) && isequaln(new,implicit));
    count = count + 2;
end
fprintf('ALL%d_SNAPSHOT_CHECKS_PASSED: exact fields, row order, skipped bars, no bars/stirrups and optional memory.\n',count);
