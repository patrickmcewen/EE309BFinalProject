function t_mux = eval_timing_rblmuxtree(my_gcedram_in)
%% EVAL_TIMING_RBLMUXTREE evaluates the timing of the RBL mux implemented as tree of NANDs

%% rename input parameters
n_word      = my_gcedram_in.n_word;
n_rows      = my_gcedram_in.n_rows;
n_partitioning_bl=my_gcedram_in.n_partitioning_bl;
n_folding_bl=my_gcedram_in.n_folding_bl;
n_folding_wl=my_gcedram_in.n_folding_wl;

gc_width    = my_gcedram_in.gc_width;
gc_height   = my_gcedram_in.gc_height;

r_wbl_buffer=my_gcedram_in.r_wbl_buffer;
c_wbl_buffer=my_gcedram_in.c_wbl_buffer;
r_rwl_buffer=my_gcedram_in.r_rwl_buffer;
c_rwl_buffer=my_gcedram_in.c_rwl_buffer;

c_wire_hor_per_m    = my_gcedram_in.c_wire_hor_per_m;
r_wire_hor_per_m    = my_gcedram_in.r_wire_hor_per_m;
r_wire_ver_per_m    = my_gcedram_in.r_wire_ver_per_m;
c_wire_ver_per_m    = my_gcedram_in.c_wire_ver_per_m;

t_inv_fo1 = my_gcedram_in.t_inv_fo1;
t_and_fo1 = my_gcedram_in.t_and_fo1;

%% get unit delays

% 2-to-1 mux delay
t_nand_fo1 = t_and_fo1 - t_inv_fo1 ;
t_mux_2to1 = 2*t_nand_fo1;

% horizontal RC buffer delay
% for simplicity, using the same buffer as for the RWL
r_buffer_hor = r_rwl_buffer; 
c_buffer_hor = c_rwl_buffer;
d_array_width = gc_width*n_word;
r_array_width = r_wire_hor_per_m*d_array_width;
c_array_width = c_wire_hor_per_m*d_array_width;
tau_array_width = r_buffer_hor*(c_buffer_hor + c_array_width) + r_array_width*c_array_width;
t_rcbuff_hor = -tau_array_width * log(1-0.5);

% vertical RC buffer delay
% for simplicity, using the same buffer as for the RBL
r_buffer_ver = r_wbl_buffer;
c_buffer_ver = c_wbl_buffer;
d_array_height = gc_height*n_rows;
r_array_height = r_wire_ver_per_m*d_array_height;
c_array_height = c_wire_ver_per_m*d_array_height;
tau_array_height = r_buffer_ver*(c_buffer_ver + c_array_height) + r_array_height*c_array_height;
t_rcbuff_ver = -tau_array_height * log(1-0.5);

%% total delay
t_mux_hor = n_folding_bl * t_mux_2to1 + 2^(n_folding_bl-1) * t_rcbuff_hor;
t_mux_ver = n_partitioning_bl * t_mux_2to1 + ( 2^(n_partitioning_bl + n_folding_wl - 1) - 1) * t_rcbuff_ver;
if ( n_folding_bl==0 && n_partitioning_bl==0 ) % no RBL muxing
    t_mux = 0;
else % RBL mux is implemented
    t_mux = t_mux_hor + t_mux_ver;    
end




