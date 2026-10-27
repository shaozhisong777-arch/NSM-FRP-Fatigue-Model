validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir, 'code20'));
addpath(projectDir);
% code20/cc19_hard.m is byte-identical to the uploaded reference.
count=0;
for kind={'strip','rod'}
 p=parameters(kind{1});p.nCells=16;p=cc19_validate(p);
 for fallback=[false true]
  if fallback;p.localMaxIterations=1;end
  for d=[0 .02 .2 .6 1.5 3]
   for unloading=[false true]
    h1=ones(p.nCells+1,1)*.3;h2=ones(p.nCells+1,1)*.1;
    t1=ones(p.nCells+1,1)*p.tauM0;t2=t1*.7;
    a=cc19_hard(p,d,180,260,h1,h2,t1,t2,unloading);
    b=anchorage(p,d,180,260,h1,h2,t1,t2,unloading);
    assert(isequaln(a,b));count=count+1;
   end
  end
 end
end
fprintf('ALL%d_ANCHOR_CHECKS_PASSED: exact fields, unequal lengths, loading/unloading and forced Newton fallback.\n',count);
