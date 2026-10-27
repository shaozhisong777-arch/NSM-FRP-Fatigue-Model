validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
count = 0;
for exponent = [1 1.5 2 3]
    for ratio = [0 .2 1]
        p = parameters('strip');
        p.crackShapeExponent = exponent;
        p.slidingRatio = ratio;
        p = cc19_validate(p);
        for q = [0 .02 .5 2]
            a = cc19_curvature_integrals(p,q);
            b = crack_deformation(p,q);
            assert(isequaln(a,b));
            count = count + 1;
        end
    end
end
fprintf('ALL%d_CRACK_CHECKS_PASSED: exact output fields for different shapes, sliding ratios and jumps.\n',count);
