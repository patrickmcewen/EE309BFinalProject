function print_output(my_gcedram_out)
%% PRINT_OUTPUT prints the main output results of GEMTOO

%% data processing
d_width_um   = my_gcedram_out.d_width/1e-6;
d_height_um  = my_gcedram_out.d_height/1e-6;
area_um2     = d_width_um*d_height_um;


%% main
disp(' ');
disp('*** Summary of the key GC-eDRAM metrics ***');
disp(' ');
disp(['Timing:']);
disp(['     Fmax        [MHz]   = ',num2str(my_gcedram_out.fmax/1e6)]);
disp(['     WWL delay   [ns]    = ',num2str(my_gcedram_out.twwl/1e-9)]);
disp(['     WBL delay   [ns]    = ',num2str(my_gcedram_out.twbl/1e-9)]);
disp(['     RWL delay   [ns]    = ',num2str(my_gcedram_out.trwl/1e-9)]);
disp(['     RBL delay   [ns]    = ',num2str(my_gcedram_out.trbl/1e-9)]);
disp(' ');
disp(['Availability and Bandwidth:']);
disp(['     Availability    [%]         = ',num2str(my_gcedram_out.avail)]);
disp(['     Bandwidth       [GBytes/s]  = ',num2str(my_gcedram_out.bw/1e9/8)]);
disp(' ');
disp(['Area:']);
disp(['     Area                [um2]       = ',num2str(area_um2)]);
disp(['     Width               [um]        = ',num2str(d_width_um)]);
disp(['     Heigth              [um]        = ',num2str(d_height_um)]);
disp(['     Area efficiency     [%]         = ',num2str(my_gcedram_out.area_efficiency)]);
disp(['     Memory density      [bit/um2]   = ',num2str(my_gcedram_out.memory_density*1e-12)]);
disp(' ');



