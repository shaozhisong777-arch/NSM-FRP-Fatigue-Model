validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
count = 0;
for scenario = 1:9
    p = parameters('strip');
    if scenario == 2
        p = parameters('rod'); p.alphaDeg = 90;
    elseif scenario == 3
        p.nsmEnabled = false;
    elseif scenario == 4
        p.stirrupArea = 0;
    elseif scenario == 5
        p.stirrupX = [100;200;300];
    elseif scenario == 6
        p.stirrupX = [100 200 300];
    elseif scenario == 7
        p.nsmSegments = [150 20 150 350;300 20 300 350];
    elseif scenario == 8
        p.snapshotCycles = [10;2;2;0]; p.Nmax = 5;
    elseif scenario == 9
        p.nsmFirstX = p.shearSpan + 100;
    end
    a = cc19_validate(p); b = prepare_parameters(p);
    assert(isequaln(a,b));
    count = count + 1;
end
fields = {'width','tauR','nCells','coverCapacityPerBar','nsmEnabled','Qmin', ...
          'deltaU','thetaDeg','alphaDeg','stirrupX','snapshotCycles','outputDir'};
values = {-1,-1,2,0,2,1e12,0,90,91,[-1 2],[-1 0],''};
for item = 1:numel(fields)
    p = parameters('strip'); p.(fields{item}) = values{item};
    oldId = ''; newId = ''; oldMessage = ''; newMessage = '';
    try
        cc19_validate(p);
    catch err
        oldId = err.identifier; oldMessage = err.message;
    end
    try
        prepare_parameters(p);
    catch err
        newId = err.identifier; newMessage = err.message;
    end
    assert(~isempty(oldId) && strcmp(oldId,newId) && strcmp(oldMessage,newMessage));
    count = count + 1;
end
fprintf('ALL%d_PARAMETER_CHECKS_PASSED: exact derived fields and invalid-input errors.\n',count);
