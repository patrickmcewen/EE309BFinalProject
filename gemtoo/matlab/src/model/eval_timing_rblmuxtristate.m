function t_mux = eval_timing_rblmuxtristate(my_gcedram_in)
%% EVAL_TIMING_RBLMUXTRISTATE evaluates the timing of the RBL mux implemented with tristate buffers
%   Note: RBL muxing with tristate buffers applies only to small-size
%   memories as in large-size memories the load shared by the outputs of the
%   tristate buffers becomes too large.


%% rename input parameters
n_word      = my_gcedram_in.n_word;
n_rows      = my_gcedram_in.n_rows;
n_partitioning_bl=my_gcedram_in.n_partitioning_bl;
n_folding_bl=my_gcedram_in.n_folding_bl;
n_folding_wl=my_gcedram_in.n_folding_wl;

gc_width    = my_gcedram_in.gc_width;
gc_height   = my_gcedram_in.gc_height;

r_mux_buffer=my_gcedram_in.r_mux_buffer;
c_mux_buffer=my_gcedram_in.c_mux_buffer;

c_wire_hor_per_m    = my_gcedram_in.c_wire_hor_per_m;
r_wire_hor_per_m    = my_gcedram_in.r_wire_hor_per_m;
r_wire_ver_per_m    = my_gcedram_in.r_wire_ver_per_m;
c_wire_ver_per_m    = my_gcedram_in.c_wire_ver_per_m;

t_inv_fo1 = my_gcedram_in.t_inv_fo1;


%% main

% length of the wire driven by tristate buffer (mux) after the sense-amp
% - vertical length (length_mux_wire_ver) is determined by partitioning with horizontal cut or folding with vertical cut
% - horizontal length (length_mux_wire_hor) is determined by folding with horizontal cut

% partitioning with horizontal cut
length_mux_wire_ver = 0;
if ( (n_partitioning_bl + n_folding_wl) > 0 )
    length_mux_wire_ver = (gc_height*n_rows)*(2^(n_partitioning_bl+n_folding_wl) - 2);
end
% folding with horizontal cut
length_mux_wire_hor = (gc_width*n_word)*(2^n_folding_bl - 1);
% total wiring lenghts are increased if they form a grid
if ( ( (n_partitioning_bl + n_folding_wl) > 0 ) && ( n_folding_bl > 0 ) )
    length_mux_wire_ver = length_mux_wire_ver * 2^n_folding_bl;
    length_mux_wire_hor = length_mux_wire_hor * 2^(n_partitioning_bl+n_folding_wl-1);
end
% total (lumped) resistance and capacitance of the wire
r_mux_wire = r_wire_hor_per_m*length_mux_wire_hor + r_wire_ver_per_m*length_mux_wire_ver;
c_mux_wire = c_wire_hor_per_m*length_mux_wire_hor + c_wire_ver_per_m*length_mux_wire_ver;
% tau of the tristate buffer driving the calculated wire (for simplicity, lumped RC is used)
tau_mux = r_mux_buffer * (c_mux_buffer + c_mux_wire) + r_mux_wire * c_mux_wire;
% delay of the mux (only inserted if folding or partitioning with horizontal cut)
if ( (n_partitioning_bl + n_folding_wl == 0) && (n_folding_bl == 0)) % no RBL muxing
    t_mux = 0;
else % RBL mux is implemented
    t_mux = t_inv_fo1 + (-tau_mux * log(1-0.5));
end

