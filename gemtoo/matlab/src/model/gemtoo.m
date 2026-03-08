function [my_gcedram_out] = gemtoo(my_gcedram_in,my_gcedram_out)

%% GEMTOO: A Modelling Tool for Gain-Cell Embedded DRAMs
%   my_gcedram_out = GEMTOO(my_gcedram_in,my_gcedram_out) returns the
%   estimated timing, memory availability, bandwidth and area of the
%   GC-eDRAM specified in the input class my_gcedram_in.
%   
%   Example:
%       my_gcedram_in   = load_28fdsoi_3tn;                     % load input parameters
%       my_gcedram_out  = gcedram_out;                          % initiate output class
%       my_gcedram_out  = gemtoo(my_gcedram_in,my_gcedram_out); % estimate GC-eDRAM performance

%% rename input parameters
n_word  = my_gcedram_in.n_word;
n_rows  = my_gcedram_in.n_rows;
n_partitioning_bl   = my_gcedram_in.n_partitioning_bl;
n_partitioning_wl   = my_gcedram_in.n_partitioning_wl;
n_folding_bl        = my_gcedram_in.n_folding_bl;
n_folding_wl        = my_gcedram_in.n_folding_wl;

%% apply architectural transformations (partitioning and folding) to GC array
n_word = n_word / (2^(n_partitioning_wl + n_folding_wl)) ;
n_rows = n_rows / (2^(n_partitioning_bl + n_folding_bl)) ;

%%% input class is updated accordingly only for the evaluation with models
my_gcedram_in.n_word=n_word;
my_gcedram_in.n_rows=n_rows;

%% evaluate performance
my_gcedram_out = eval_timing(my_gcedram_in,my_gcedram_out);     % speed
my_gcedram_out = eval_area(my_gcedram_in,my_gcedram_out);       % area
my_gcedram_out = eval_availbw(my_gcedram_in,my_gcedram_out);    % availability and bandwidth


