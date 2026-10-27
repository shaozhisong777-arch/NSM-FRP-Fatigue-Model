validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
p = parameters('strip');
s = [0, p.shearSpan/2, p.shearSpan, p.span/2, ...
     p.span-p.shearSpan, p.span-p.shearSpan/2, p.span];
count = 0;
for x = {s, s', reshape([s 0],2,4), [], p.span/2}
    for Q = [0, p.Qmax, -100]
        [a,b] = cc19_load(p,x{1},Q);
        [c,d] = beam_load(p,x{1},Q);
        assert(isequaln(a,c) && isequaln(b,d));
        count = count + 1;
    end
    [a,b] = cc19_load(p,x{1});
    [c,d] = beam_load(p,x{1});
    assert(isequaln(a,c) && isequaln(b,d));
    count = count + 1;
end
for x = {[-1 0], [0 p.span+1]}
    oldId = ''; newId = '';
    try
        cc19_load(p,x{1});
    catch err
        oldId = err.identifier;
    end
    try
        beam_load(p,x{1});
    catch err
        newId = err.identifier;
    end
    assert(~isempty(oldId) && strcmp(oldId,newId));
    count = count + 1;
end
[M,V] = beam_load(p,s,p.Qmax);
assert(M(1)==0 && M(end)==0);
assert(M(4)==p.Qmax*p.shearSpan/2);
assert(isequal(V, [p.Qmax/2 p.Qmax/2 0 0 0 -p.Qmax/2 -p.Qmax/2]));
fprintf('ALL%d_LOAD_CHECKS_PASSED: exact moment, shear, shapes, default load and errors.\n',count);
