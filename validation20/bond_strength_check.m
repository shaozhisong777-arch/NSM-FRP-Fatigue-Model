validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir, 'code20'));
addpath(projectDir);
count = 0;
for kind = {'strip','rod'}
    p = parameters(kind{1});
    histories = {[0 .5 1 10 100 1e6 1e12], ...
                 [0;1;10;1e12], reshape(0:5,2,3), [], zeros(0,1)};
    for item = 1:numel(histories)
        a = cc19_strength(p,histories{item});
        b = bond_strength(p,histories{item});
        assert(isequaln(a,b));
        count = count + 1;
    end
end
p = parameters('strip');
for history = {[-1 0], [NaN 0], [Inf 0], 1+1i, 'x', {1}, true}
    oldId = ''; newId = '';
    try
        cc19_strength(p,history{1});
    catch err
        oldId = err.identifier;
    end
    try
        bond_strength(p,history{1});
    catch err
        newId = err.identifier;
    end
    assert(~isempty(oldId) && strcmp(oldId,newId));
    count = count + 1;
end
fprintf('ALL%d_BOND_STRENGTH_CHECKS_PASSED: exact values, shapes and invalid-input identifiers.\n',count);
