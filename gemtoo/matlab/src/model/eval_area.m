function my_gcedram_out = eval_area(my_gcedram_in,my_gcedram_out)
%% EVAL_AREA evaluates the area of the GC-eDRAM

%% rename input parameters
gc_width    = my_gcedram_in.gc_width;
gc_height   = my_gcedram_in.gc_height;
n_word      = my_gcedram_in.n_word;
n_rows      = my_gcedram_in.n_rows;
d_wbl_buffer = my_gcedram_in.d_wbl_buffer;
d_wwl_buffer = my_gcedram_in.d_wwl_buffer;
d_rwl_buffer = my_gcedram_in.d_rwl_buffer;
d_globadr_buffer = my_gcedram_in.d_globadr_buffer;
d_globadr_boost_buffer = my_gcedram_in.d_globadr_boost_buffer;
d_and = my_gcedram_in.d_and;
d_dec_intconbuff = my_gcedram_in.d_dec_intconbuff;
d_ls = my_gcedram_in.d_ls;
d_sa = my_gcedram_in.d_sa;
d_ff = my_gcedram_in.d_ff;
d_mux_buffer = my_gcedram_in.d_mux_buffer;
n_partitioning_bl=my_gcedram_in.n_partitioning_bl;
n_partitioning_wl=my_gcedram_in.n_partitioning_wl;
n_folding_bl=my_gcedram_in.n_folding_bl;
n_folding_wl=my_gcedram_in.n_folding_wl;
dec_intconbuff_2=my_gcedram_in.dec_intconbuff_2;
dec_intconbuff_3=my_gcedram_in.dec_intconbuff_3;
globadr_buff=my_gcedram_in.globadr_buff;
peripheral_under_array=my_gcedram_in.peripheral_under_array;

%% memory dimensions
% width and height of the GC array
gcarray_width     = gc_width  * n_word;
gcarray_height    = gc_height * n_rows;
% decoder width
bits_adr = log2(n_rows); % nuber of bits for address
dec_depth = ceil(log2(bits_adr)); % logic depth of the decoder
d_dec = dec_depth*d_and; % decoder width: width of only the AND gates
% adding also the width of RC buffering
if (dec_depth==3)
    d_dec = d_dec + (dec_intconbuff_2+dec_intconbuff_3)*d_dec_intconbuff;
elseif (dec_depth==2)
    d_dec = d_dec + (dec_intconbuff_2)*d_dec_intconbuff;
elseif (dec_depth==1)
    % do nothing
else % dec_depth==0 or dec_depth>3
    error ('wrong dec_depth')
end

% memory dimensions
d_width  = gcarray_width + (d_ff + d_dec + d_ls + d_wwl_buffer) + (d_ff + d_dec + d_rwl_buffer);
d_height = gcarray_height + (d_ff + d_wbl_buffer) + (d_sa); % d_mux_buffer included later
% consider if any partitioning or folding is applied
if ( (n_partitioning_bl + n_partitioning_wl + n_folding_bl + n_folding_wl) > 0)
    % if global address is used, remove the decoders and the level shifter
    if ( (n_partitioning_wl + n_folding_bl) > 0)
        d_width = d_width - (2*d_dec + d_ls) ;
        % if global addres repetitors are used, add them to the width
        if (globadr_buff==0)
            % do nothing
        elseif (globadr_buff==1)
            d_width = d_width + d_wwl_buffer + d_rwl_buffer;
        else
            error('wrong globadr_buff')
        end
    end
    % if rbl muxing is used, include d_mux_buffer
    if ( (n_partitioning_bl + n_folding_bl) > 0 )
        d_height = d_height + d_mux_buffer;
    end
    % then you consider the multiplying factors due to partitioning/folding
    d_width     = 2^(n_partitioning_wl+n_folding_bl)*d_width;
    d_height    = 2^(n_partitioning_bl+n_folding_wl)*d_height;
    % if global address is used, add the decoders and the level shifter back and add the global address buffers
    if ( (n_partitioning_wl + n_folding_bl) > 0)
        d_width = d_width + (2*d_dec + d_ls) + (d_globadr_buffer + d_globadr_boost_buffer);
    end    
end


%% area efficiency
area_bitcells   = 2^(n_partitioning_bl+n_partitioning_wl+n_folding_bl+n_folding_wl)*(gcarray_width*gcarray_height);
area_tot        = d_width*d_height;

%% area breakdown: width and height contributions per category
% Number of sub-array tiles in each dimension after all transformations
N_col = 2^(n_partitioning_wl + n_folding_bl); % column-direction tiling factor
N_row = 2^(n_partitioning_bl + n_folding_wl); % row-direction tiling factor

% Width contributions
d_width_subarray = gcarray_width * N_col;   % total GC-array width (all column tiles)
if ( (n_partitioning_wl + n_folding_bl) > 0 )
    % Partitioned/folded: decoder, LS, and global address buffers are global (added once)
    d_width_global = (2*d_dec + d_ls) + (d_globadr_buffer + d_globadr_boost_buffer);
else
    % Monolithic: decoder, LS, and FFs are all part of the single-level control
    d_width_global = 2*d_ff + 2*d_dec + d_ls;
end
d_width_local = d_width - d_width_subarray - d_width_global; % per-sub-array buffers (and FFs if partitioned)

% Height contributions
d_height_subarray = gcarray_height * N_row; % total GC-array height (all row tiles)
d_height_local    = d_height - d_height_subarray; % WBL buffer, FF, SA, mux buffer (per row tile)

if peripheral_under_array
    array_area      = d_width_subarray * d_height_subarray;
    peripheral_area = area_tot - array_area;
    area_tot        = max(array_area, peripheral_area);
end
area_efficiency = area_bitcells/area_tot * 100;


%% memory density
bitcell_number = 2^(n_partitioning_bl+n_partitioning_wl+n_folding_bl+n_folding_wl)*(n_word*n_rows);
memory_density = bitcell_number/area_tot;


%% writing to output class
my_gcedram_out.total_area       = area_tot;
my_gcedram_out.d_width          = d_width;
my_gcedram_out.d_height         = d_height;
my_gcedram_out.area_efficiency  = area_efficiency;
my_gcedram_out.memory_density   = memory_density;
% area breakdown
my_gcedram_out.d_width_subarray  = d_width_subarray;
my_gcedram_out.d_width_local     = d_width_local;
my_gcedram_out.d_width_global    = d_width_global;
my_gcedram_out.d_height_subarray = d_height_subarray;
my_gcedram_out.d_height_local    = d_height_local;


