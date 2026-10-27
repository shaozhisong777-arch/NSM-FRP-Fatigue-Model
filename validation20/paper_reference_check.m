validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
p = parameters('strip');
p.Nmax = 1; p.nCells = 16; p.scanPoints = 41;
p.makePlots = false; p.exportResults = false;
p.verbose = false; p.computeCapacity = false;
out = fatigue_calculate(p);
assert(~isempty(out.snapshots));
for item = 1:numel(out.snapshots)
    snapshot = out.snapshots(item);
    a = paper_reference(out.parameters,snapshot.peak);
    assert(isequaln(a,snapshot.reference));
end
fprintf('PAPER_REFERENCE_SNAPSHOT_ENTRY_CHECK_PASSED\n');
