reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
rows=[];
for cells=[12 24 48 96 192 384]
 p=parameters('strip');p.alphaDeg=90;p.nCells=cells;p=prepare_parameters(p);
 m.bondMax=cell(p.nBars,2);m.age=cell(p.nBars,2);m.activated=cell(p.nBars,2);
 m.failedFRP=false(p.nBars,1);m.barFailure=repmat({''},p.nBars,1);m.steelDamage=zeros(p.nSteel,1);m.concreteDamage=0;
 for b=1:p.nBars;for s=1:2;m.bondMax{b,s}=zeros(cells+1,1);m.age{b,s}=zeros(cells+1,1);m.activated{b,s}=false(cells+1,1);end;end
 [hi,info]=state(p,m,p.Qmax/2,0,false);assert(info.ok);
 [lo,info]=state(p,hi.memory,p.Qmin/2,hi.q,true);assert(info.ok);
 [active,range]=active_nodes(p,hi,lo,hi.memory);
 count=0;activeLength=0;
 for b=1:p.nBars;for s=1:2
  mask=active{b,s};count=count+sum(mask);
  [x,w]=anchor_mesh(p,p.bars(b,2+s));activeLength=activeLength+sum(w.*mask);
 end;end
 row=[cells hi.q count activeLength];rows=[rows;row];
 fprintf('ACTIVE_RESOLUTION n=%d q=%.12g nodes=%g integratedMaskLength=%.12g\n',row);fflush(stdout);
end
save(fullfile(resultDir,'active_resolution.mat'),'rows','-v7');
