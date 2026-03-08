function my_gcedram_out = eval_availbw(my_gcedram_in,my_gcedram_out)
%% EVAL_AVAILBW evaluates the memory availability and bandwidth of the GC-eDRAM

%% rename input parameters
fmax        = my_gcedram_out.fmax;
n_rows      = my_gcedram_in.n_rows;
n_word      = my_gcedram_in.n_word;
ref_rate_mode=my_gcedram_in.ref_rate_mode;
ref_period=my_gcedram_in.ref_period;
sn_degradation=my_gcedram_in.sn_degradation;
sn_degr_vect=my_gcedram_in.sn_degr_vect;
tret_vect = my_gcedram_in.tret_vect;

%% availability

% refresh period
if ( strcmp(ref_rate_mode,'vsn') ) % refresh period determined by sn_degradation
    i_tret = find( (sn_degradation >= sn_degr_vect) , 1 , 'last' );
    ref_period = tret_vect(i_tret); % overwrite ref_period with corresponding retention time
elseif ( strcmp(ref_rate_mode,'ref_period') ) % refresh period specified as input parameter
    % do nothing, ref_period already specified as input
else
    error('wrong ref_rate_mode')
end

% stalling time (time spent for refreshing the memory content)
% NOTE: folding/partitioning with horizontal cut has been already taken into account
tstall = n_rows/fmax ;

% memory availability
avail = ( 1 - tstall/ref_period ) * 100;

%% bandwidth
bw = n_word * fmax * (avail/100);


%% writing to output class
my_gcedram_out.avail = avail;
my_gcedram_out.bw    = bw;


