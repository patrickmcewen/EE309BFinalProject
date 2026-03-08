% class for outputs of GEMTOO
classdef gcedram_out
    properties
        %% timing
        % key timing values
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
        d_width             % memory width [m]
        d_height            % memory height [m]
        area_efficiency     % area efficiency [%] : ratio between the area of the GC arrays and the total memory area
        memory_density      % memory density [bit/m2]

    end
end


