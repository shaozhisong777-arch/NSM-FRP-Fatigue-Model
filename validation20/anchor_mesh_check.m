validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
p = parameters('strip');
count = 0;
for elements = [1 2 16 24 48 96]
    p.nCells = elements;
    for lengthValue = [.1 100 183.7 1000]
        [a,b] = cc19_mesh(p,lengthValue);
        [c,d] = anchor_mesh(p,lengthValue);
        assert(isequaln(a,c) && isequaln(b,d));
        assert(numel(c) == elements + 1);
        assert(abs(sum(d)-lengthValue) <= 1e-12*max(1,lengthValue));
        count = count + 1;
    end
end
for lengthValue = {0, -1, Inf, NaN, [1 2]}
    oldId = ''; newId = '';
    try
        cc19_mesh(p,lengthValue{1});
    catch err
        oldId = err.identifier;
    end
    try
        anchor_mesh(p,lengthValue{1});
    catch err
        newId = err.identifier;
    end
    assert(~isempty(oldId) && strcmp(oldId,newId));
    count = count + 1;
end
fprintf('ALL%d_MESH_CHECKS_PASSED: exact nodes, weights and error identifiers.\n',count);
