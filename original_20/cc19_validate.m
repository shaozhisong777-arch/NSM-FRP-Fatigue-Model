function p = cc19_validate(p)
% 参数校验和几何模块：求斜裂缝与NSM/箍筋的真实交点及两侧锚固长度。
pos = {'width','depth','flangeWidth','flangeDepth','fc','Ec','ds','span','shearSpan', ...
 'crackHeight','crackShapeExponent','Ef','Af','perimeter','ffu','nsmSpacing', ...
 'Es','stirrupSpacing','steelTransferLength','fy','tauM0','deltaM','deltaU', ...
 'VcPeak','concreteRiseQ','concreteSofteningW','Qmax','maxQ','forceTolerance', ...
 'slipTolerance','localTolerance','maxOpeningStep','steelSNrefStress', ...
 'steelSNexponent','concreteSNrefStress','concreteSNexponent'};
for k=1:numel(pos)
 v=p.(pos{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<=0
  error('cc19:input','%s must be finite and positive.',pos{k});
 end
end
nonneg={'crackOriginX','slidingRatio','tauR','bondFatigueK','stirrupArea', ...
 'Qmin','concreteResidualRatio','nsmFirstX','stirrupFirstX','cyclicSlipTolerance'};
for k=1:numel(nonneg)
 v=p.(nonneg{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<0
  error('cc19:input','%s must be finite and nonnegative.',nonneg{k});
 end
end
ints={'Nmax','cycleStep','nCells','scanPoints','localMaxIterations','nsmFaces'};
for k=1:numel(ints)
 v=p.(ints{k});
 if ~isnumeric(v)||~isscalar(v)||~isfinite(v)||v<1||v~=fix(v)
  error('cc19:input','%s must be a positive integer.',ints{k});
 end
end
lim={'coverCapacityPerBar','steelSNrefCycles','concreteSNrefCycles', ...
 'shearStrutLimit','flexuralMomentLimit'};
for k=1:numel(lim)
 v=p.(lim{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||isnan(v)||v<=0
  error('cc19:input','%s must be positive or Inf.',lim{k});
 end
end
flags={'nsmEnabled','makePlots','exportResults','verbose','computeCapacity'};
for k=1:numel(flags)
 v=p.(flags{k}); if ~isscalar(v)||~(isnumeric(v)||islogical(v))||~any(v==[0 1])
  error('cc19:input','%s must be logical.',flags{k}); end
end
if p.nCells<4||p.scanPoints<15||p.Qmin>p.Qmax||p.shearSpan>p.span/2 ...
 ||p.ds>=p.depth||p.crackHeight>p.depth||p.flangeDepth>=p.depth ...
 ||p.deltaU<=p.deltaM||p.tauR>p.tauM0||p.concreteResidualRatio>1 ...
 ||p.activationFraction<=0||p.activationFraction>1||~isfinite(p.activationFraction) ...
 ||~isscalar(p.thetaDeg)||~isfinite(p.thetaDeg)||p.thetaDeg<=0||p.thetaDeg>=90 ...
 ||~isscalar(p.alphaDeg)||~isfinite(p.alphaDeg)||p.alphaDeg<=0||p.alphaDeg>90
 error('cc19:input','Inconsistent geometry, angles, load range or bond parameters.');
end
if p.nsmYBottom<0||p.nsmYTop>p.depth||p.nsmYTop<=p.nsmYBottom
 error('cc19:input','Require 0 <= nsmYBottom < nsmYTop <= depth.'); end
p.theta=p.thetaDeg*pi/180; p.alpha=p.alphaDeg*pi/180;
p.kinematicDenominator=cos(p.theta)+p.slidingRatio*sin(p.theta);
p.nsmProjection=(sin(p.theta+p.alpha)-p.slidingRatio*cos(p.theta+p.alpha))/p.kinematicDenominator;
if p.nsmProjection<=0, error('cc19:input','The assumed crack motion does not tension the NSM bars.'); end
p.crackTopX=p.crackOriginX+p.crackHeight/tan(p.theta);
if p.crackTopX>p.shearSpan+1e-8
 error('cc19:input','The critical crack leaves the modelled shear span.'); end
if isempty(p.nsmSegments)
 xb=p.nsmFirstX:p.nsmSpacing:p.shearSpan;
 dy=p.nsmYTop-p.nsmYBottom;
 segments=[xb(:),p.nsmYBottom*ones(numel(xb),1), ...
  xb(:)-dy/tan(p.alpha),p.nsmYTop*ones(numel(xb),1)];
else
 segments=p.nsmSegments;
 if ~isnumeric(segments)||~isreal(segments)||size(segments,2)~=4||any(~isfinite(segments(:)))
  error('cc19:input','nsmSegments must be a finite n-by-4 matrix.'); end
end
% bars columns: xCross,yCross,L_lower,L_upper,shape,actualAlphaRadians
bars=zeros(0,6); crack0=[p.crackOriginX;0]; crackD=[p.crackTopX-p.crackOriginX;p.crackHeight];
if p.nsmEnabled
 for i=1:size(segments,1)
  a=segments(i,1:2)'; b=segments(i,3:4)'; d=b-a;
  if norm(d)<=0||d(2)<=0||d(1)>1e-8
   error('cc19:input','Each NSM segment must run from the bottom/right to the top/left.'); end
  if any(a<[0;0])||any(a>[p.shearSpan;p.depth])||b(2)<0||b(2)>p.depth
   error('cc19:input','NSM segment endpoints must be within beam boundaries.'); end
  % Clip an automatically generated bar at x=0; custom bars must lie in the span.
  if b(1)<0 && isempty(p.nsmSegments)
   b=a+(0-a(1))/d(1)*d; d=b-a;
  elseif b(1)<0||b(1)>p.shearSpan
   error('cc19:input','Custom NSM segment leaves the shear span.');
  end
  A=[d,-crackD]; if abs(det(A))<1e-10, continue; end
  t=A\(crack0-a);
  if t(1)>1e-8&&t(1)<1-1e-8&&t(2)>0&&t(2)<1
   xy=a+t(1)*d; al=atan2(d(2),-d(1));
   proj=(sin(p.theta+al)-p.slidingRatio*cos(p.theta+al))/p.kinematicDenominator;
   if proj<=0, error('cc19:input','A custom bar is not opened in tension.'); end
   bars(end+1,:)=[xy',t(1)*norm(d),(1-t(1))*norm(d), ...
    (1-xy(2)/p.crackHeight)^p.crackShapeExponent,al];
  end
 end
end
p.bars=bars; p.nBars=size(bars,1); p.generatedSegments=segments;
if isempty(p.stirrupX), sx=p.stirrupFirstX:p.stirrupSpacing:p.shearSpan; else, sx=p.stirrupX; end
if ~isnumeric(sx)||~isreal(sx)||any(~isfinite(sx(:)))||any(sx(:)<0)||any(sx(:)>p.shearSpan)
 error('cc19:input','Invalid stirrup coordinates.'); end
sy=(sx(:)-p.crackOriginX)*tan(p.theta); use=sy>0 & sy<p.crackHeight;
if p.stirrupArea==0, use(:)=false; end
% sx may be row or column; normalize without relying on implicit expansion.
p.steel=[reshape(sx(use),[],1),sy(use),(1-sy(use)/p.crackHeight).^p.crackShapeExponent];
p.nSteel=size(p.steel,1);
if ~isnumeric(p.snapshotCycles)||~isreal(p.snapshotCycles)||any(~isfinite(p.snapshotCycles(:))) ...
 ||any(p.snapshotCycles(:)<0)||any(p.snapshotCycles(:)~=fix(p.snapshotCycles(:)))
 error('cc19:input','snapshotCycles must be nonnegative integers.'); end
p.snapshotCycles=unique([0 1 reshape(p.snapshotCycles,1,[]) p.Nmax]);
p.snapshotCycles=p.snapshotCycles(p.snapshotCycles<=p.Nmax);
if ~(ischar(p.outputDir)||(isstring(p.outputDir)&&isscalar(p.outputDir)))||isempty(char(p.outputDir))
 error('cc19:input','outputDir must be a path.'); end
p.outputDir=char(p.outputDir);
p.forceDefinition='Q is total actuator load; V=Q/2; T is one physical NSM bar axial force.';
end
