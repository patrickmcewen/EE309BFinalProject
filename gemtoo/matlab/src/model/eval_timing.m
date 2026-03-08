function my_gcedram_out = eval_timing(my_gcedram_in,my_gcedram_out)
%% EVAL_TIMING evaluates the timing of the GC-eDRAM

%% rename input parameters
n_word      = my_gcedram_in.n_word;
n_rows      = my_gcedram_in.n_rows;
n_partitioning_wl=my_gcedram_in.n_partitioning_wl;
n_folding_bl=my_gcedram_in.n_folding_bl;
globadr_buff=my_gcedram_in.globadr_buff;
rblmux_topology=my_gcedram_in.rblmux_topology;
h_wwl=my_gcedram_in.h_wwl;
h_wbl=my_gcedram_in.h_wbl;
h_rwl=my_gcedram_in.h_rwl;
h_rbl=my_gcedram_in.h_rbl;

gc_width    = my_gcedram_in.gc_width;
gc_height   = my_gcedram_in.gc_height;
c_wwl=my_gcedram_in.c_wwl;
c_wbl=my_gcedram_in.c_wbl;
c_rwl=my_gcedram_in.c_rwl;
c_rbl=my_gcedram_in.c_rbl;
c_sn=my_gcedram_in.c_sn;
ref_rate_mode=my_gcedram_in.ref_rate_mode;
ref_period=my_gcedram_in.ref_period;
sn_degradation=my_gcedram_in.sn_degradation;
sn_degr_vect=my_gcedram_in.sn_degr_vect;
r_rbl_on_vect=my_gcedram_in.r_rbl_on_vect;
tret_vect=my_gcedram_in.tret_vect;
r_wwl_on=my_gcedram_in.r_wwl_on;

r_wwl_buffer=my_gcedram_in.r_wwl_buffer;
c_wwl_buffer=my_gcedram_in.c_wwl_buffer;
r_wbl_buffer=my_gcedram_in.r_wbl_buffer;
c_wbl_buffer=my_gcedram_in.c_wbl_buffer;
r_rwl_buffer=my_gcedram_in.r_rwl_buffer;
c_rwl_buffer=my_gcedram_in.c_rwl_buffer;
r_globadr_buffer=my_gcedram_in.r_globadr_buffer;
c_globadr_buffer=my_gcedram_in.c_globadr_buffer;
r_globadr_boost_buffer=my_gcedram_in.r_globadr_boost_buffer;
c_globadr_boost_buffer=my_gcedram_in.c_globadr_boost_buffer;

c_sa=my_gcedram_in.c_sa;
t_sa=my_gcedram_in.t_sa;

c_wire_hor_per_m    = my_gcedram_in.c_wire_hor_per_m;
r_wire_hor_per_m    = my_gcedram_in.r_wire_hor_per_m;
r_wire_ver_per_m    = my_gcedram_in.r_wire_ver_per_m;
c_wire_ver_per_m    = my_gcedram_in.c_wire_ver_per_m;

t_ff            = my_gcedram_in.t_ff;
t_inv_fo1       = my_gcedram_in.t_inv_fo1;
t_and_fo1       = my_gcedram_in.t_and_fo1;
t_inv_boost_fo1 = my_gcedram_in.t_inv_boost_fo1;
t_and_boost_fo1 = my_gcedram_in.t_and_boost_fo1;
t_ls            = my_gcedram_in.t_ls;


%% parasitics of the wires
% horizontal (WLs)
c_wire_hor = gc_width  * c_wire_hor_per_m;
r_wire_hor = gc_width  * r_wire_hor_per_m;
% vertical (BLs)
c_wire_ver = gc_height * c_wire_ver_per_m;
r_wire_ver = gc_height * r_wire_ver_per_m;


%% row decoder delay (for both read and write)
tdec = eval_timing_rowdecoder(my_gcedram_in);


%% global address buffering: time constant (tau)
% length of the wire
if (globadr_buff==0)
    d_wl_globadr = (n_word*gc_width) * (2^(n_partitioning_wl+n_folding_bl) - 1);
elseif (globadr_buff==1)
    d_wl_globadr = (n_word*gc_width);
else
    error('wrong globadr_buff')
end
% parasitics of the global-address wire
r_wl_globadr = r_wire_hor_per_m*d_wl_globadr;
c_wl_globadr = c_wire_hor_per_m*d_wl_globadr;
% tau of the driver driving the wire
if (globadr_buff==0)
    tau_wl_globadr = r_globadr_buffer * (c_globadr_buffer + c_wl_globadr) + r_wl_globadr * c_wl_globadr;
    tau_wl_globadr_boost = r_globadr_boost_buffer * (c_globadr_boost_buffer + c_wl_globadr) + r_wl_globadr * c_wl_globadr;
elseif (globadr_buff==1)
    tau_wl_globadr = (r_globadr_buffer * (c_globadr_buffer + c_wl_globadr) + r_wl_globadr * c_wl_globadr) * (2^(n_partitioning_wl+n_folding_bl) - 1);
    tau_wl_globadr_boost = (r_globadr_boost_buffer * (c_globadr_boost_buffer + c_wl_globadr) + r_wl_globadr * c_wl_globadr) * (2^(n_partitioning_wl+n_folding_bl) - 1);
else
    error('wrong globadr_buff')
end


%% write delays

% ---------- WWL delay ----------
% local-WWL buffer
c_wwl_cell = c_wire_hor + c_wwl; % wwl cap = wire cap + wwl cap
tau_wwl_buffer  = r_wwl_buffer * (c_wwl_buffer + n_word*c_wwl_cell) ;
tau_wwl_cells   = r_wire_hor * (n_word+1)*n_word/2 * c_wwl_cell ;
tau_wwl         = tau_wwl_buffer + tau_wwl_cells ;
t_wwl_buffer    = (-tau_wwl * log(1-h_wwl)); % delay of local-WWL buffer
% global-WWL buffer
if ( n_partitioning_wl+n_folding_bl > 0 )
    t_wwl_globadr = t_inv_boost_fo1 + (-tau_wl_globadr_boost * log(1-0.5)) + t_and_boost_fo1;
else
    t_wwl_globadr = 0;
end
% WWL delay
twwl = t_ff + tdec + t_ls + t_wwl_globadr + t_inv_boost_fo1 + t_wwl_buffer ;

% ---------- WBL delay ----------
% WBL buffer
c_wbl_cell = c_wire_ver + c_wbl;
tau_wbl_buffer  = r_wbl_buffer*( c_wbl_buffer + n_rows*c_wbl_cell + c_sn ) ;
tau_wbl_cells   = r_wire_ver*( (n_rows+1)*n_rows/2*c_wbl_cell + n_rows*c_sn ) ;
tau_wbl_sn      = r_wwl_on*c_sn;
tau_wbl         = tau_wbl_buffer + tau_wbl_cells + tau_wbl_sn ;
t_wbl_buffer    = (-tau_wbl * log(1-h_wbl));
% WBL delay
twbl = t_ff + t_inv_fo1 + t_wbl_buffer ;


%% read delays

% ---------- RWL delay ----------
% local-RWL buffer
c_rwl_cell = c_wire_hor + c_rwl;
tau_rwl_buffer  = r_rwl_buffer * (c_rwl_buffer + n_word*c_rwl_cell) ;
tau_rwl_cells   = r_wire_hor * (n_word+1)*n_word/2 * c_rwl_cell ;
tau_rwl         = tau_rwl_buffer + tau_rwl_cells ;
t_rwl_buffer = (-tau_rwl * log(1-h_rwl)) ;
% global-RWL buffer
if ( n_partitioning_wl+n_folding_bl ~= 0 )
    t_rwl_globadr = t_inv_fo1 + (-tau_wl_globadr * log(1-0.5)) + t_and_fo1;
else
    t_rwl_globadr = 0;
end
% RWL delay
trwl = t_ff + tdec + t_rwl_globadr + t_inv_fo1 + t_rwl_buffer;

% ---------- RBL delay ----------
% delay of GC driving the RBL
c_rbl_cell = c_wire_ver + c_rbl;
% find index of RBL ON-resistance
if ( strcmp(ref_rate_mode,'vsn') ) % RBL ON-resistance determined by sn_degradation
    i_rbl_on = find( (sn_degradation >= sn_degr_vect) , 1 , 'last' );
elseif ( strcmp(ref_rate_mode,'ref_period') ) % RBL ON-resistance determined by refresh period
    i_rbl_on = find( (ref_period <= tret_vect) , 1 , 'first' );
else
    error('wrong ref_rate_mode')
end
% check that the index has been found
if ( isempty(i_rbl_on) )
    error('sn_degradation out of sn_degr_vect')
end
% get RBL ON-resistance
r_rbl_on = r_rbl_on_vect(i_rbl_on);
% delay of GC driving the RBL
tau_rbl_on      = r_rbl_on*( c_rbl + (n_rows-1)*c_rbl_cell + (c_wire_ver+c_sa) ) ;
tau_rbl_cells   = r_wire_ver*( n_rows*(n_rows-1)/2*c_rbl_cell + (n_rows-1)*(c_wire_ver+c_sa) ) ;
tau_sa          = r_wire_ver*(c_wire_ver+c_sa);
tau_rbl         = tau_rbl_on + tau_rbl_cells + tau_sa;
t_gc_rbl   = (-tau_rbl * log(1-h_rbl));
% delay of RBL muxing
if ( strcmp(rblmux_topology,'tree') )
    t_mux = eval_timing_rblmuxtree(my_gcedram_in);
elseif ( strcmp(rblmux_topology,'tristate') )
    t_mux = eval_timing_rblmuxtristate(my_gcedram_in);
else
    error('wrong rblmux_topology')
end
% RBL delay
trbl = t_gc_rbl + t_sa + t_mux;

%% maximum operating frequency (fmax)
% write and read delays
twrite  = max([twwl twbl]);
tread   = trwl + trbl;
% fmax
tmin = max([twrite tread]);
fmax = 1/tmin;


%% writing to output class
% key timing values
my_gcedram_out.twwl = twwl;
my_gcedram_out.twbl = twbl;
my_gcedram_out.trwl = trwl;
my_gcedram_out.trbl = trbl;
my_gcedram_out.fmax = fmax;
% internal delays
my_gcedram_out.t_ff             = t_ff;
my_gcedram_out.tdec             = tdec;
my_gcedram_out.t_ls             = t_ls;
my_gcedram_out.t_wwl_globadr    = t_wwl_globadr;
my_gcedram_out.t_inv_boost_fo1  = t_inv_boost_fo1;
my_gcedram_out.t_wwl_buffer     = t_wwl_buffer;
my_gcedram_out.t_inv_fo1        = t_inv_fo1;
my_gcedram_out.t_wbl_buffer     = t_wbl_buffer;
my_gcedram_out.t_rwl_globadr    = t_rwl_globadr;
my_gcedram_out.t_rwl_buffer     = t_rwl_buffer;
my_gcedram_out.t_gc_rbl         = t_gc_rbl;
my_gcedram_out.t_sa             = t_sa;
my_gcedram_out.t_mux            = t_mux;


