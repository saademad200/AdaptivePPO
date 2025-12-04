#!/bin/bash

# Path to output directory
APP_DIRECTORY="experiments/rho1-gsm8k"

# Seed for reproducibility
export APP_SEED="2746318213"

# Config file
CONFIGSTR="configs/polIter_rho1bSft2_vineppo_GSM8K.jsonnet"

# Number of available GPUs
NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
export WANDB_MODE=offline
export WANDB_DISABLED=true

echo "Using config: $CONFIGSTR"
echo "Number of GPUs detected: $NUM_GPUS"
echo "Output directory: $APP_DIRECTORY"

# Make sure output directory exists
mkdir -p $APP_DIRECTORY

# Run training (multi-GPU with DeepSpeed)
deepspeed --no_local_rank --num_gpus=$NUM_GPUS \
         src/treetune/main.py --configs "$CONFIGSTR" \
         run_iteration_loop

# Run evaluation (single GPU only - distributed evaluation not supported)
CUDA_VISIBLE_DEVICES=0 python src/treetune/main.py --configs "$CONFIGSTR" \
         run_evaluation
