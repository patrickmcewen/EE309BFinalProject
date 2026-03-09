function my_gcedram_in = load_28fdsoi_3tn
% LOAD_28FDSOI_3TN provides the input parameters of a GC-eDRAM designed in
% 28nm FD-SOI with 3T all-NMOS GC
%
%   my_gcedram_in = LOAD_28FDSOI_3TN() assigns the parameters that are used
%   by GEMTOO as input


%% architecture
my_gcedram_in.n_rows    = 256;
my_gcedram_in.n_word    = 64;   

my_gcedram_in.peripheral_under_array = 0;

my_gcedram_in.n_partitioning_bl = 0;
my_gcedram_in.n_partitioning_wl = 0;
my_gcedram_in.n_folding_bl      = 0;
my_gcedram_in.n_folding_wl      = 0;

my_gcedram_in.ref_rate_mode     = 'ref_period'; % 'ref_period' or 'vsn'
my_gcedram_in.ref_period        = 3e-6;
my_gcedram_in.sn_degradation    = 30;

my_gcedram_in.globadr_buff = 1;
my_gcedram_in.rblmux_topology = 'tree';

%% circuits
my_gcedram_in.h_rwl = 0.9;
my_gcedram_in.h_rbl = 0.58; 
my_gcedram_in.h_wwl = 0.9;  
my_gcedram_in.h_wbl = 0.9;  

my_gcedram_in.gc_width      = sqrt(0.186e-12);  
my_gcedram_in.gc_height     = sqrt(0.186e-12);  

my_gcedram_in.c_wwl  = 63e-18;  
my_gcedram_in.c_wbl  = 37e-18;  
my_gcedram_in.c_rwl  = 65e-18;  
my_gcedram_in.c_rbl  = 47e-18;  
my_gcedram_in.c_sn   = 97e-18;  

my_gcedram_in.sn_degr_vect = [0:10:40];

my_gcedram_in.r_rbl_on_vect = 3/4.*0.9./[59e-6 , 47e-6 , 34e-6 , 22e-6 , 13e-6];
my_gcedram_in.r_wwl_on = 15e3;

my_gcedram_in.tret_vect = [0 , 45e-9 , 483e-9 , 3.98e-6 , 19.24e-6];

my_gcedram_in.r_wwl_buffer = 3/4*1.3/737e-6;
my_gcedram_in.c_wwl_buffer = 925e-18;       
my_gcedram_in.d_wwl_buffer = 1.5e-6;        

my_gcedram_in.r_wbl_buffer = 3/4*0.9/374e-6;    
my_gcedram_in.c_wbl_buffer = 1.546e-15;         
my_gcedram_in.d_wbl_buffer = 4e-6;              

my_gcedram_in.r_rwl_buffer = 3/4*0.9/505e-6;    
my_gcedram_in.c_rwl_buffer = 935e-18;           
my_gcedram_in.d_rwl_buffer = 1.5e-6;            

my_gcedram_in.r_globadr_buffer = 3/4*0.9/374e-6;
my_gcedram_in.c_globadr_buffer = 1.546e-15;
my_gcedram_in.d_globadr_buffer = 3e-6;            

my_gcedram_in.r_globadr_boost_buffer = 3/4*1.3/656e-6; 
my_gcedram_in.c_globadr_boost_buffer = 1.546e-15;      
my_gcedram_in.d_globadr_boost_buffer = 3e-6;            

my_gcedram_in.c_sa = 388e-18;   
my_gcedram_in.t_sa = 16e-12;    
my_gcedram_in.d_sa = 3e-6;      

my_gcedram_in.r_mux_buffer = 3/4*0.9/374e-6;    
my_gcedram_in.c_mux_buffer = 1.546e-15;         
my_gcedram_in.d_mux_buffer = 1e-6;              

my_gcedram_in.dec_intconbuff_2 = 0; 
my_gcedram_in.dec_intconbuff_3 = 1; 

my_gcedram_in.r_dec_buffer_2  = 3/4*0.9/292e-6; 
my_gcedram_in.c_dec_buffer_2  = 554e-18;        
my_gcedram_in.r_dec_buffer_3  = 3/4*0.9/292e-6; 
my_gcedram_in.c_dec_buffer_3  = 554e-18;        
my_gcedram_in.d_dec_intconbuff = 1e-6;          


%% technology
my_gcedram_in.r_wire_hor_per_m = 9.47e6;        
my_gcedram_in.c_wire_hor_per_m = 0.1517e-9*2;   
my_gcedram_in.r_wire_ver_per_m = 9.43e6;        
my_gcedram_in.c_wire_ver_per_m = 0.1471e-9*2;   

my_gcedram_in.t_inv_fo1         = 7.5e-12;
my_gcedram_in.t_inv_fo2         = 9e-12;
my_gcedram_in.t_inv_boost_fo1   = 7.5e-12;
my_gcedram_in.t_and_fo1         = 17e-12; 
my_gcedram_in.t_and_fo4         = 24e-12; 
my_gcedram_in.t_and_fo16        = 96e-12; 
my_gcedram_in.t_and_boost_fo1   = 14e-12; 
my_gcedram_in.t_ff              = 37e-12; 
my_gcedram_in.t_ls              = 50e-12; 

my_gcedram_in.c_and = 459e-18;

my_gcedram_in.d_and     = 0.5e-6;
my_gcedram_in.d_ls      = 1e-6;  
my_gcedram_in.d_ff      = 0e-6;  


