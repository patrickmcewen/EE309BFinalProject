#!/bin/bash

source /etc/profile.d/modules.sh
module load base
module load matlab/latest

if ! conda env list | grep -q "^ee309b_final "; then
    conda env create -f environment.yaml
fi
conda activate ee309b_final