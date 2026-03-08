function tdec = eval_timing_rowdecoder(my_gcedram_in)
%% EVAL_TIMING_ROWDECODER evaluates the delay of the row decoder

%% rename input parameters
n_rows = my_gcedram_in.n_rows;
gc_height   = my_gcedram_in.gc_height;

dec_intconbuff_2 = my_gcedram_in.dec_intconbuff_2;
dec_intconbuff_3 = my_gcedram_in.dec_intconbuff_3;

r_dec_buffer_2 = my_gcedram_in.r_dec_buffer_2;
c_dec_buffer_2 = my_gcedram_in.c_dec_buffer_2;
r_dec_buffer_3 = my_gcedram_in.r_dec_buffer_3;
c_dec_buffer_3 = my_gcedram_in.c_dec_buffer_3;

r_wire_ver_per_m    = my_gcedram_in.r_wire_ver_per_m;
c_wire_ver_per_m    = my_gcedram_in.c_wire_ver_per_m;

t_inv_fo1 = my_gcedram_in.t_inv_fo1;
t_inv_fo2 = my_gcedram_in.t_inv_fo2;
t_and_fo1 = my_gcedram_in.t_and_fo1;
t_and_fo4 = my_gcedram_in.t_and_fo4;
t_and_fo16 = my_gcedram_in.t_and_fo16;
c_and = my_gcedram_in.c_and;

%% init

% min and max number of acceptable bits for input address
n_adr_in_min = 3;
n_adr_in_max = 8;

%% main

% number of bits of input address
n_adr_in = log2(n_rows);

% check n_adr_in
if ( (n_adr_in < n_adr_in_min) || (n_adr_in > n_adr_in_max) )
    error('number of rows out of accepted range');
end

% derive number of stages
n_stages = ceil(log2(n_adr_in));

% R and C of wire unit (vertical)
c_wire_ver = gc_height * c_wire_ver_per_m;
r_wire_ver = gc_height * r_wire_ver_per_m;

% delay derived based on number of stages
if (n_stages==2) % 2-stage rowdecoder for n_adr_in from 3 to 4
    % considering both with or without RC buffering
    if (dec_intconbuff_2==0)
        tdec_1 = 2*t_inv_fo2 + t_and_fo4;
        tdec_2 = t_and_fo1;
    elseif (dec_intconbuff_2==1)
        tdec_1 = 2*t_inv_fo2 + t_and_fo1;
        n_wire_2 = 8+(16-8)/2; % number of unit wires
        tau_rc_buff_2 = r_dec_buffer_2*(c_dec_buffer_2 + n_wire_2*c_wire_ver + 4*c_and) + r_wire_ver*( (n_wire_2+1)*n_wire_2/2*c_wire_ver + n_wire_2*(4*c_and) );
        t_rc_buff_2 = t_inv_fo1 + (-tau_rc_buff_2 * log(1-0.5)); 
        tdec_2 = t_rc_buff_2 + t_and_fo1;
    else
        error('unexpected dec_intconbuff_1');
    end
    tdec = tdec_1 + tdec_2 + t_and_fo1;
elseif (n_stages==3) % 3-stage rowdecoder for n_adr_in from 5 to 8
    % pre-calculating the RC buffers
    % RC buffer for stage 2
    n_wire_2 = 16+(32-16)/2; % number of unit wires
    tau_rc_buff_2 = r_dec_buffer_2*(c_dec_buffer_2 + n_wire_2*c_wire_ver + 4*c_and) + r_wire_ver*( (n_wire_2+1)*n_wire_2/2*c_wire_ver + n_wire_2*(4*c_and) );
    t_rc_buff_2 = t_inv_fo1 + (-tau_rc_buff_2 * log(1-0.5));
    % RC buffer for stage 3
    n_wire_3 = 32+(256-32)/2; % number of unit wires
    tau_rc_buff_3 = r_dec_buffer_3*(c_dec_buffer_3 + n_wire_3*c_wire_ver + 16*c_and) + r_wire_ver*( (n_wire_3+1)*n_wire_3/2*c_wire_ver + n_wire_3*(16*c_and) );
    t_rc_buff_3 = t_inv_fo1 + (-tau_rc_buff_3 * log(1-0.5));
    % considering both with or without RC buffering
    if      ( dec_intconbuff_2==0 && dec_intconbuff_3==0 )
        tdec_1 = 2*t_inv_fo2 + t_and_fo4;
        tdec_2 = t_and_fo16;
        tdec_3 = t_and_fo1;
    elseif  ( dec_intconbuff_2==1 && dec_intconbuff_3==0 )
        tdec_1 = 2*t_inv_fo2 + t_and_fo1;
        tdec_2 = t_rc_buff_2 + t_and_fo16;
        tdec_3 = t_and_fo1;
    elseif  ( dec_intconbuff_2==0 && dec_intconbuff_3==1 )
        tdec_1 = 2*t_inv_fo2 + t_and_fo4;
        tdec_2 = t_and_fo1;
        tdec_3 = t_rc_buff_3 + t_and_fo1;
    elseif  ( dec_intconbuff_2==1 && dec_intconbuff_3==1 )
        tdec_1 = 2*t_inv_fo2 + t_and_fo4;
        tdec_2 = t_rc_buff_2 + t_and_fo16;
        tdec_3 = t_rc_buff_3 + t_and_fo1;
    else
        error('unexpected dec_intconbuff_*');
    end
    tdec = tdec_1 + tdec_2 + tdec_3 + t_and_fo1;
else
    error('number of rows out of accepted range');
end



