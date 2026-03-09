% class for outputs of GEMTOO
classdef gcedram_out
    properties
        %% timing
        % key timing values
        tread    % read delay [s]
        twrite   % write delay [s]
        twwl    % WWL delay [s]
        twbl    % WBL delay [s]
        trwl    % RWL delay [s]
        trbl    % RBL delay [s]
        fmax    % max operating frequency (fmax) [Hz]
        % internal delays
        t_ff
        tdec
        t_ls
        t_wwl_globadr
        t_inv_boost_fo1
        t_wwl_buffer
        t_inv_fo1
        t_wbl_buffer
        t_rwl_globadr
        t_rwl_buffer
        t_gc_rbl
        t_sa
        t_mux
        
        %% availability and bandwidth
        avail   % memory availability [%]
        bw      % memory bandwidth [bit/s]

        %% area
        total_area          % total memory area [m2]
        d_width             % memory width [m]
        d_height            % memory height [m]
        area_efficiency     % area efficiency [%] : ratio between the area of the GC arrays and the total memory area
        memory_density      % memory density [bit/m2]
        % area breakdown: width-direction contributions [m]
        d_width_subarray    % GC array width contribution (all sub-arrays combined)
        d_width_local       % local peripheral width contribution (buffers, FFs replicated per sub-array)
        d_width_global      % global peripheral width contribution (decoder, level shifter, global address buffers)
        % area breakdown: height-direction contributions [m]
        d_height_subarray   % GC array height contribution (all sub-arrays combined)
        d_height_local      % local peripheral height contribution (WBL buffer, FF, SA, mux buffer)

        %% timing breakdown (subarray / local peripheral / global)
        % WWL path breakdown
        twwl_subarray   % WWL delay component: distributed RC along word-line cells [s]
        twwl_local      % WWL delay component: local WWL buffer resistance + pre-driver inverter [s]
        twwl_global     % WWL delay component: flip-flop + decoder + level shifter + global address routing [s]
        % WBL path breakdown
        twbl_subarray   % WBL delay component: distributed RC along bit-line cells + SN charging via WWL transistor [s]
        twbl_local      % WBL delay component: local WBL buffer resistance + pre-driver inverter [s]
        twbl_global     % WBL delay component: flip-flop [s]
        % RWL path breakdown
        trwl_subarray   % RWL delay component: distributed RC along word-line cells [s]
        trwl_local      % RWL delay component: local RWL buffer resistance + pre-driver inverter [s]
        trwl_global     % RWL delay component: flip-flop + decoder + global address routing [s]
        % RBL path breakdown
        trbl_subarray   % RBL delay component: GC on-resistance + distributed cell RC along bit-line [s]
        trbl_local      % RBL delay component: last wire segment to SA + sense amplifier delay [s]
        trbl_global     % RBL delay component: RBL mux (selects across sub-arrays; 0 if monolithic) [s]

    end
end


