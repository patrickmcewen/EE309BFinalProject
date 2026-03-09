function run_sweep(sweep_dir, out_dir)

%% RUN_SWEEP runs GEMTOO on every input file in a sweep directory
%
% sweep_dir : path to a directory of input .m files (e.g. produced by sweep_arch.py)
% out_dir   : (optional) directory in which to save JSON results
%             defaults to sweep_dir

if nargin < 2
    out_dir = sweep_dir;
end

assert(exist(sweep_dir, 'dir') == 7, ['sweep_dir not found: ', sweep_dir]);

if exist(out_dir, 'dir') ~= 7
    mkdir(out_dir);
end

%% collect input files

m_files = dir(fullfile(sweep_dir, '*.m'));
assert(~isempty(m_files), ['No .m files found in: ', sweep_dir]);

disp(' '); disp(['Found ', num2str(numel(m_files)), ' input files in: ', sweep_dir]);

%% add sweep_dir to path so feval can resolve the loader functions

addpath(sweep_dir);

%% run each configuration

for i = 1:numel(m_files)
    input_loader = m_files(i).name(1:end-2);  % strip .m extension
    disp(' ');
    disp(['[', num2str(i), '/', num2str(numel(m_files)), '] Running: ', input_loader]);
    run_and_save(input_loader, out_dir);
end

disp(' '); disp(['Sweep complete. Results saved to: ', out_dir]);
