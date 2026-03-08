% class for inputs of GEMTOO
classdef gcedram_in
    properties
        %% architecture
        
        % GC array (monolithic representation)
        n_rows % number of rows in GC array
        n_word % number of coloumns in GC array and wordsize of the GC-eDRAM

        % architectural transformations
        n_partitioning_bl   % partitioning factor for BL cut
        n_partitioning_wl   % partitioning factor for WL cut
        n_folding_bl        % folding factor for BL cut
        n_folding_wl        % folding factor for WL cut

        % refresh rate
        ref_rate_mode       % 'ref_period' determines the refresh rate based on ref_period, 'vsn' determines the refresh rate based on sn_degradation
        ref_period          % refresh period, used when ref_rate_mode=='refperiod' [s]
        sn_degradation      % worst-case voltage degradation of the SN [%]
        
        % misc
        globadr_buff    % global-address buffers are inserted at each GC array when equal to 1
        rblmux_topology % RBL muxing topology: 'tree' for NAND-based tree, 'tristate' for tristate-buffer muxing     
        
        %% circuits
        
        % threshold for detection of input voltage transition
        %   Example: h_rwl=0.9 specifies that the RWL port of the GC is enabled
        %   when the signal crosses 90% of the voltage swing
        h_wwl % threshold of WWL port in GC [0-1]
        h_wbl % threshold of WBL port in GC [0-1]
        h_rwl % threshold of RWL port in GC [0-1]
        h_rbl % threshold of the RBL sense amplifier [0-1]
        
        % gain cell (GC)
        %   dimensions
        gc_width    % GC width [m]
        gc_height   % GC height [m]
        %   capacitances
        c_wwl   % capacitance of the WWL port in GC [F]
        c_wbl   % capacitance of the WBL port in GC [F]
        c_rwl   % capacitance of the RWL port in GC [F]
        c_rbl   % capacitance of the RBL port in GC [F]
        c_sn    % capacitance of the storage node (SN) in GC [F]
        %   deterioration of data in SN
        sn_degr_vect    % vector of percentage levels of considered voltage degradation in SN [%]
        %   resistances
        r_rbl_on_vect   % vector of ON-resistances of RBL port in GC for corresponding values of sn_degr_vect [ohm]
        r_wwl_on % ON-resistance of WWL port in GC [ohm]
        %   data retention time (or corresponding refresh period)
        tret_vect   % data retention time for for corresponding values of sn_degr_vect [s]       
        % buffers
        %   local WWL
        r_wwl_buffer    % output ON-resistance of local-WWL buffer [ohm]
        c_wwl_buffer    % output capacitance of local-WWL buffer [F]
        d_wwl_buffer    % width or height of local-WWL buffer [m]
        %   local WBL
        r_wbl_buffer    % output ON-resistance of local-WBL buffer [ohm]
        c_wbl_buffer    % output capacitance of local-WBL buffer [F]
        d_wbl_buffer    % width or height of local-WBL buffer [m]
        %   local RWL
        r_rwl_buffer    % output ON-resistance of local-RWL buffer [ohm]
        c_rwl_buffer    % output capacitance of local-RWL buffer [F]
        d_rwl_buffer    % width or height of local-RWL buffer [m]
        %   global-RWL buffer
        r_globadr_buffer    % output ON-resistance of global-RWL buffer [ohm]
        c_globadr_buffer    % output capacitance of global-RWL buffer [F]
        d_globadr_buffer    % width or height of global-RWL buffer [m]
        %   boosted global-WWL buffer
        r_globadr_boost_buffer  % output ON-resistance of boosted global-WWL buffer [ohm]
        c_globadr_boost_buffer  % output capacitance of boosted global-WWL buffer [F]
        d_globadr_boost_buffer  % width or height of boosted global-WWL buffer [m]
        
        % RBL sense amplifier
        c_sa    % output capacitance of the RBL sense amplifier [F]
        t_sa    % propagation delay of the RBL sense amplifier [s]
        d_sa    % width or height of of the RBL sense amplifier [m]
        
        % RBL muxing: tristate buffer
        r_mux_buffer    % output ON-resistance of tristate buffer for RBL muxing [ohm]
        c_mux_buffer    % output capacitance of tristate buffer for RBL muxing [F]
        d_mux_buffer    % width or height of of tristate buffer for RBL muxing [m]
        
        % row decoders
        %   interconnect buffers
        dec_intconbuff_2    % a layer of interconnect buffers is added before the 2nd layer of logic in the decoder when equal to 1
        dec_intconbuff_3    % a layer of interconnect buffers is added before the 3rd layer of logic in the decoder when equal to 1
        %   buffers
        r_dec_buffer_2      % output ON-resistance of interconnect buffer before the 2nd layer of logic in the decoder [ohm]
        c_dec_buffer_2      % output capacitance of interconnect buffer before the 2nd layer of logic in the decoder [F]
        r_dec_buffer_3      % output ON-resistance of interconnect buffer before the 3rd layer of logic in the decoder [ohm]
        c_dec_buffer_3      % output capacitance of interconnect buffer before the 3rd layer of logic in the decoder [F]
        d_dec_intconbuff    % width or height of of interconnect buffer in the decoder [m]
        
        
        %% technology
        
        % wiring parasitics
        r_wire_hor_per_m    % parasitic resistance of horizontal wiring used for WLs [ohm]
        c_wire_hor_per_m    % parasitic capacitance of horizontal wiring used for WLs [F]
        r_wire_ver_per_m    % parasitic resistance of vertical wiring used for BLs [ohm]
        c_wire_ver_per_m    % parasitic capacitance of vertical wiring used for BLs [F]
        
        % standard cells
        %   propagation delays
        t_inv_fo1       % propagation delay of FO1 inverter [s]
        t_inv_fo2       % propagation delay of FO2 inverter [s]
        t_inv_boost_fo1 % propagation delay of FO1 inverter with boosted voltage [s]
        t_and_fo1       % propagation delay of FO1 AND [s]
        t_and_fo4       % propagation delay of FO4 AND [s]
        t_and_fo16      % propagation delay of FO16 AND [s]
        t_and_boost_fo1 % propagation delay of FO1 AND with boosted voltage [s]
        t_ff            % propagation delay of flip-flop [s]
        t_ls            % propagation delay of level shifter [s]
        %   input capacitances
        c_and % input capacitance of AND [F]
        %   dimensions
        d_and   % width or height of AND [m]
        d_ls    % width or height of level shifter [m]
        d_ff    % width or height of flip-flop [m]

    end
end


