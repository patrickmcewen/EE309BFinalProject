function print_output(my_gcedram_out)
%% PRINT_OUTPUT prints the main output results of GEMTOO

%% data processing
d_width_um   = my_gcedram_out.d_width/1e-6;
d_height_um  = my_gcedram_out.d_height/1e-6;
area_um2     = d_width_um*d_height_um;

% timing breakdown helpers: percent of total path delay
pct = @(part,total) num2str(part/total*100,'%.1f');
ns  = @(t) num2str(t/1e-9,'%.4f');

% area breakdown helpers
um  = @(d) num2str(d/1e-6,'%.3f');
pct_area = @(d,dtot) num2str(d/dtot*100,'%.1f');


%% main
disp(' ');
disp('*** Summary of the key GC-eDRAM metrics ***');
disp(' ');
disp('Timing:');
disp(['     Fmax        [MHz]   = ',num2str(my_gcedram_out.fmax/1e6)]);
disp(['     WWL delay   [ns]    = ',ns(my_gcedram_out.twwl)]);
disp(['       subarray  [ns]    = ',ns(my_gcedram_out.twwl_subarray),' (',pct(my_gcedram_out.twwl_subarray,my_gcedram_out.twwl),'%)  distributed RC along GC cells']);
disp(['       local     [ns]    = ',ns(my_gcedram_out.twwl_local),  ' (',pct(my_gcedram_out.twwl_local,  my_gcedram_out.twwl),'%)  local WWL buffer + pre-driver inv']);
disp(['       global    [ns]    = ',ns(my_gcedram_out.twwl_global), ' (',pct(my_gcedram_out.twwl_global, my_gcedram_out.twwl),'%)  FF + decoder + LS + global addr routing']);
disp(['     WBL delay   [ns]    = ',ns(my_gcedram_out.twbl)]);
disp(['       subarray  [ns]    = ',ns(my_gcedram_out.twbl_subarray),' (',pct(my_gcedram_out.twbl_subarray,my_gcedram_out.twbl),'%)  distributed RC along GC cells + SN charging']);
disp(['       local     [ns]    = ',ns(my_gcedram_out.twbl_local),  ' (',pct(my_gcedram_out.twbl_local,  my_gcedram_out.twbl),'%)  local WBL buffer + pre-driver inv']);
disp(['       global    [ns]    = ',ns(my_gcedram_out.twbl_global), ' (',pct(my_gcedram_out.twbl_global, my_gcedram_out.twbl),'%)  FF']);
disp(['     RWL delay   [ns]    = ',ns(my_gcedram_out.trwl)]);
disp(['       subarray  [ns]    = ',ns(my_gcedram_out.trwl_subarray),' (',pct(my_gcedram_out.trwl_subarray,my_gcedram_out.trwl),'%)  distributed RC along GC cells']);
disp(['       local     [ns]    = ',ns(my_gcedram_out.trwl_local),  ' (',pct(my_gcedram_out.trwl_local,  my_gcedram_out.trwl),'%)  local RWL buffer + pre-driver inv']);
disp(['       global    [ns]    = ',ns(my_gcedram_out.trwl_global), ' (',pct(my_gcedram_out.trwl_global, my_gcedram_out.trwl),'%)  FF + decoder + global addr routing']);
disp(['     RBL delay   [ns]    = ',ns(my_gcedram_out.trbl)]);
disp(['       subarray  [ns]    = ',ns(my_gcedram_out.trbl_subarray),' (',pct(my_gcedram_out.trbl_subarray,my_gcedram_out.trbl),'%)  GC on-resistance + distributed cell RC']);
disp(['       local     [ns]    = ',ns(my_gcedram_out.trbl_local),  ' (',pct(my_gcedram_out.trbl_local,  my_gcedram_out.trbl),'%)  wire-to-SA + sense amplifier']);
disp(['       global    [ns]    = ',ns(my_gcedram_out.trbl_global), ' (',pct(my_gcedram_out.trbl_global, my_gcedram_out.trbl),'%)  RBL mux (0 if monolithic)']);
disp(' ');
disp('Availability and Bandwidth:');
disp(['     Availability    [%]         = ',num2str(my_gcedram_out.avail)]);
disp(['     Bandwidth       [GBytes/s]  = ',num2str(my_gcedram_out.bw/1e9/8)]);
disp(' ');
disp('Area:');
disp(['     Area                [um2]       = ',num2str(area_um2)]);
disp(['     Width               [um]        = ',num2str(d_width_um)]);
disp(['       subarray          [um]        = ',um(my_gcedram_out.d_width_subarray), ' (',pct_area(my_gcedram_out.d_width_subarray,my_gcedram_out.d_width),'%)  GC array columns']);
disp(['       local peripheral  [um]        = ',um(my_gcedram_out.d_width_local),    ' (',pct_area(my_gcedram_out.d_width_local,   my_gcedram_out.d_width),'%)  per-subarray WL buffers (+ FFs if partitioned)']);
disp(['       global            [um]        = ',um(my_gcedram_out.d_width_global),   ' (',pct_area(my_gcedram_out.d_width_global,  my_gcedram_out.d_width),'%)  decoder + LS + global addr bufs']);
disp(['     Height              [um]        = ',num2str(d_height_um)]);
disp(['       subarray          [um]        = ',um(my_gcedram_out.d_height_subarray),' (',pct_area(my_gcedram_out.d_height_subarray,my_gcedram_out.d_height),'%)  GC array rows']);
disp(['       local peripheral  [um]        = ',um(my_gcedram_out.d_height_local),  ' (',pct_area(my_gcedram_out.d_height_local,  my_gcedram_out.d_height),'%)  WBL buffer + FF + SA + mux buf']);
disp(['     Area efficiency     [%]         = ',num2str(my_gcedram_out.area_efficiency)]);
disp(['     Memory density      [bit/um2]   = ',num2str(my_gcedram_out.memory_density*1e-12)]);
disp(' ');



