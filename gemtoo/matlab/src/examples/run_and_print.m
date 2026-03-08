function run_and_print

%% RUN_AND_PRINT executes GEMTOO and prints the output results

disp(' '); disp('*** Test example of GEMTOO ***');


%% init

disp(' '); disp('Load input parameters...');
my_gcedram_in   = load_28fdsoi_3tn; % load input parameters

disp(' '); disp('Initiate output class...');
my_gcedram_out  = gcedram_out;      % initiate output class

%% main

disp(' '); disp('Executing GEMTOO...');
my_gcedram_out  = gemtoo(my_gcedram_in,my_gcedram_out); % execute GEMTOO

print_output(my_gcedram_out);                           % print output results

