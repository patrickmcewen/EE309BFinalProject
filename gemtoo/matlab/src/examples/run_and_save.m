function run_and_save(input_loader, out_dir)

%% RUN_AND_SAVE executes GEMTOO and saves the output results to a JSON file
%
% input_loader : (optional) name of the input loader function as a string
%                defaults to 'load_28fdsoi_3tn'
% out_dir      : (optional) directory in which to save the JSON output
%                defaults to the current working directory

if nargin < 1
    input_loader = 'load_28fdsoi_2tn';
end
if nargin < 2
    out_dir = '.';
end

disp(' '); disp('*** Test example of GEMTOO ***');


%% init

disp(' '); disp(['Load input parameters from: ', input_loader, '...']);
my_gcedram_in   = feval(input_loader);  % load input parameters

disp(' '); disp('Initiate output class...');
my_gcedram_out  = gcedram_out;          % initiate output class


%% main

disp(' '); disp('Executing GEMTOO...');
my_gcedram_out  = gemtoo(my_gcedram_in, my_gcedram_out); % execute GEMTOO

json_file = fullfile(out_dir, ['gemtoo_out_', input_loader, '.json']);
disp(' '); disp(['Saving output to: ', json_file, '...']);

fid = fopen(json_file, 'w');
assert(fid ~= -1, ['Failed to open output file: ', json_file]);

arch_fields_num = {'n_rows', 'n_word', 'n_partitioning_bl', 'n_partitioning_wl', ...
                   'n_folding_bl', 'n_folding_wl', 'ref_period', 'sn_degradation', 'globadr_buff'};
arch_fields_str = {'ref_rate_mode', 'rblmux_topology'};

o = my_gcedram_out;

fprintf(fid, '{\n');
fprintf(fid, '  "input_file": "%s"', input_loader);

%% architecture
fprintf(fid, ',\n  "architecture": {');
sep = '';
for i = 1:numel(arch_fields_num)
    f = arch_fields_num{i};
    fprintf(fid, '%s\n    "%s": %.10g', sep, f, my_gcedram_in.(f));
    sep = ',';
end
for i = 1:numel(arch_fields_str)
    f = arch_fields_str{i};
    fprintf(fid, '%s\n    "%s": "%s"', sep, f, my_gcedram_in.(f));
    sep = ',';
end
fprintf(fid, '\n  }');

%% timing
fprintf(fid, ',\n  "timing": {');
fprintf(fid, '\n    "fmax": %.10g', o.fmax);
fprintf(fid, ',\n    "tread": %.10g', o.tread);
fprintf(fid, ',\n    "twrite": %.10g', o.twrite);
for sig = {'twwl', 'twbl', 'trwl', 'trbl'}
    s = sig{1};
    fprintf(fid, ',\n    "%s": {', s);
    fprintf(fid, '\n      "total": %.10g',    o.(s));
    fprintf(fid, ',\n      "subarray": %.10g', o.([s '_subarray']));
    fprintf(fid, ',\n      "local": %.10g',    o.([s '_local']));
    fprintf(fid, ',\n      "global": %.10g',   o.([s '_global']));
    fprintf(fid, '\n    }');
end

misc_timing = {'t_ff', 'tdec', 't_ls', 't_wwl_globadr', 't_inv_boost_fo1', 't_wwl_buffer', ...
               't_inv_fo1', 't_wbl_buffer', 't_rwl_globadr', 't_rwl_buffer', 't_gc_rbl', 't_sa', 't_mux'};
for i = 1:numel(misc_timing)
    fprintf(fid, ',\n    "%s": %.10g', misc_timing{i}, o.(misc_timing{i}));
end
fprintf(fid, '\n  }');

%% availability and bandwidth
fprintf(fid, ',\n  "avail": %.10g', o.avail);
fprintf(fid, ',\n  "bw": %.10g',    o.bw);

%% area
fprintf(fid, ',\n  "area": {');
fprintf(fid, '\n    "total_area": %.10g,', o.total_area);
fprintf(fid, '\n    "d_width": {');
fprintf(fid, '\n      "total": %.10g',    o.d_width);
fprintf(fid, ',\n      "subarray": %.10g', o.d_width_subarray);
fprintf(fid, ',\n      "local": %.10g',    o.d_width_local);
fprintf(fid, ',\n      "global": %.10g',   o.d_width_global);
fprintf(fid, '\n    }');
fprintf(fid, ',\n    "d_height": {');
fprintf(fid, '\n      "total": %.10g',    o.d_height);
fprintf(fid, ',\n      "subarray": %.10g', o.d_height_subarray);
fprintf(fid, ',\n      "local": %.10g',    o.d_height_local);
fprintf(fid, '\n    }');
fprintf(fid, ',\n    "area_efficiency": %.10g', o.area_efficiency);
fprintf(fid, ',\n    "memory_density": %.10g',  o.memory_density);
fprintf(fid, '\n  }');

fprintf(fid, '\n}\n');
fclose(fid);
