% MAIN_DRIVE Run one NSM shear-fatigue case.
% Edit parameters.m for defaults, or enable an override below for this run.
clear;
close all;
clc;

% 1. Use the current set of functions in this folder.
here = fileparts(mfilename('fullpath'));
addpath(here, '-begin');

% 2. Select the reinforcement type.
kind = 'strip'; % 'strip' for strips; 'rod' for rods.

% 3. Optional changes for this run. Defaults come from parameters.m.
options = struct();
% options.Nmax = 100;       % Short run; the default is 10000 cycles.
% options.Qmax = 165000;    % Total applied load in N; shear V = Qmax/2.
% options.alphaDeg = 90;   % Vertical NSM bars; default angle is 60 degrees.
% options.makePlots = false;
% options.exportResults = false;

% 4. Read parameters, calculate, then plot and export as requested.
out = read_and_calculate(kind, options);

% Inspect out in the workspace. Export folder: out.parameters.outputDir.
% Reaching Nmax is a runout, not proof of fatigue failure.