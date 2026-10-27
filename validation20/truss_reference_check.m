validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
count = 0;
for kind = {'strip','rod'}
    for angle = [60 90]
        p = parameters(kind{1}); p.alphaDeg = angle;
        p = prepare_parameters(p);
        for forces = {zeros(p.nBars,1), (1:p.nBars)'*1234.5, ...
                      (1:p.nBars)*1234.5, ones(p.nBars,1)*1e5}
            st.barForce = forces{1}; st.Vnsm = 23456;
            a = cc19_shearforce(p,st); b = shearfoce(p,st);
            assert(isequaln(a,b));
            assert(isequaln(b,cc19_paper_interpolation(p,st)));
            count = count + 1;
        end
    end
end
p.nBars = 0; st.barForce = []; st.Vnsm = 0;
a = cc19_shearforce(p,st); b = shearfoce(p,st);
assert(isequaln(a,b)); count = count + 1;
fprintf('ALL%d_TRUSS_CHECKS_PASSED: exact references, wrapper output and zero-bar case.\n',count);
