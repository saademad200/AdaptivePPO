#!/bin/bash
# Experiment Runner for VinePPO Improvements
# This script automates running all experiments for the research project

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
export APP_SEED="2746318213"
NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

# Weights & Biases (optional)
export WANDB_PROJECT="vineppo-improvements"
# export WANDB_RUN_ID="unique_run_id"  # Uncomment and set if needed

# ============================================================================
# Experiment Definitions
# ============================================================================

declare -A EXPERIMENTS=(
    ["baseline"]="configs/polIter_rho1bSft2_vineppo_GSM8K.jsonnet"
    ["ablation1_adaptive_mc"]="configs/polIter_rho1bSft2_improved_ablation1_GSM8K.jsonnet"
    ["ablation2_curriculum"]="configs/polIter_rho1bSft2_improved_ablation2_GSM8K.jsonnet"
    ["ablation3_running_stats"]="configs/polIter_rho1bSft2_improved_ablation3_GSM8K.jsonnet"
    ["ablation4_ensemble"]="configs/polIter_rho1bSft2_improved_ablation4_GSM8K.jsonnet"
    ["ablation5_multihorizon"]="configs/polIter_rho1bSft2_improved_ablation5_GSM8K.jsonnet"
    ["combined_basic"]="configs/polIter_rho1bSft2_improved_combined_GSM8K.jsonnet"
    ["combined_full5"]="configs/polIter_rho1bSft2_improved_full5_GSM8K.jsonnet"
    ["combo_mc_curriculum"]="configs/polIter_rho1bSft2_improved_mc_curriculum_GSM8K.jsonnet"
)

# ============================================================================
# Helper Functions
# ============================================================================

run_experiment() {
    local exp_name=$1
    local config_file=$2
    local stage=$3  # "train" or "eval" or "both"

    echo "=========================================="
    echo "Running: $exp_name"
    echo "Config: $config_file"
    echo "Stage: $stage"
    echo "=========================================="

    export APP_DIRECTORY="experiments/${exp_name}"
    mkdir -p "$APP_DIRECTORY"

    # Training
    if [ "$stage" == "train" ] || [ "$stage" == "both" ]; then
        echo "Starting training..."
        deepspeed --no_local_rank --num_gpus=$NUM_GPUS \
            src/treetune/main.py --configs "$config_file" \
            run_iteration_loop
        echo "Training complete for $exp_name"
    fi

    # Evaluation (single GPU only - distributed evaluation not supported)
    if [ "$stage" == "eval" ] || [ "$stage" == "both" ]; then
        echo "Starting evaluation (single GPU)..."
        CUDA_VISIBLE_DEVICES=0 python src/treetune/main.py --configs "$config_file" \
            run_evaluation
        echo "Evaluation complete for $exp_name"
    fi

    echo "Finished: $exp_name"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --all               Run all experiments (baseline + ablations + combined)
    --baseline          Run baseline VinePPO only
    --ablations         Run first 3 ablation studies (Core improvements)
    --ablations_all     Run all 5 ablation studies (Core + Advanced)
    --combined          Run combined improvements (first 3 only)
    --combined_all      Run full combined improvements (all 5)
    --experiment NAME   Run specific experiment by name
    --stage STAGE       Which stage to run: train, eval, or both (default: both)
    --list              List all available experiments
    -h, --help          Show this help message

Examples:
    # Run everything
    $0 --all

    # Run baseline only
    $0 --baseline --stage train

    # Run specific experiment
    $0 --experiment ablation1_adaptive_mc

    # Run first 3 ablations (Core improvements - for class project)
    $0 --ablations

    # Run all 5 ablations (Core + Advanced - for publication)
    $0 --ablations_all

    # Run combined (first 3 improvements)
    $0 --combined

    # Run full combined (all 5 improvements)
    $0 --combined_all

    # List available experiments
    $0 --list
EOF
}

list_experiments() {
    echo "Available experiments:"
    for exp_name in "${!EXPERIMENTS[@]}"; do
        echo "  - $exp_name: ${EXPERIMENTS[$exp_name]}"
    done
}

# Parse arguments
STAGE="both"
RUN_MODE=""
SPECIFIC_EXP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            RUN_MODE="all"
            shift
            ;;
        --baseline)
            RUN_MODE="baseline"
            shift
            ;;
        --ablations)
            RUN_MODE="ablations"
            shift
            ;;
        --ablations_all)
            RUN_MODE="ablations_all"
            shift
            ;;
        --combined)
            RUN_MODE="combined"
            shift
            ;;
        --combined_all)
            RUN_MODE="combined_all"
            shift
            ;;
        --experiment)
            RUN_MODE="specific"
            SPECIFIC_EXP="$2"
            shift 2
            ;;
        --stage)
            STAGE="$2"
            shift 2
            ;;
        --list)
            list_experiments
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute based on mode
case $RUN_MODE in
    "all")
        echo "Running ALL experiments..."
        for exp_name in "${!EXPERIMENTS[@]}"; do
            run_experiment "$exp_name" "${EXPERIMENTS[$exp_name]}" "$STAGE"
        done
        ;;

    "baseline")
        echo "Running BASELINE only..."
        run_experiment "baseline" "${EXPERIMENTS[baseline]}" "$STAGE"
        ;;

    "ablations")
        echo "Running ABLATION studies (first 3)..."
        run_experiment "ablation1_adaptive_mc" "${EXPERIMENTS[ablation1_adaptive_mc]}" "$STAGE"
        run_experiment "ablation2_curriculum" "${EXPERIMENTS[ablation2_curriculum]}" "$STAGE"
        run_experiment "ablation3_running_stats" "${EXPERIMENTS[ablation3_running_stats]}" "$STAGE"
        ;;

    "ablations_all")
        echo "Running ALL ABLATION studies (5 total)..."
        run_experiment "ablation1_adaptive_mc" "${EXPERIMENTS[ablation1_adaptive_mc]}" "$STAGE"
        run_experiment "ablation2_curriculum" "${EXPERIMENTS[ablation2_curriculum]}" "$STAGE"
        run_experiment "ablation3_running_stats" "${EXPERIMENTS[ablation3_running_stats]}" "$STAGE"
        run_experiment "ablation4_ensemble" "${EXPERIMENTS[ablation4_ensemble]}" "$STAGE"
        run_experiment "ablation5_multihorizon" "${EXPERIMENTS[ablation5_multihorizon]}" "$STAGE"
        ;;

    "combined")
        echo "Running COMBINED improvements (first 3)..."
        run_experiment "combined_basic" "${EXPERIMENTS[combined_basic]}" "$STAGE"
        ;;

    "combined_all")
        echo "Running FULL COMBINED improvements (all 5)..."
        run_experiment "combined_full5" "${EXPERIMENTS[combined_full5]}" "$STAGE"
        ;;

    "specific")
        if [ -z "$SPECIFIC_EXP" ]; then
            echo "Error: No experiment name provided"
            show_usage
            exit 1
        fi

        if [ -z "${EXPERIMENTS[$SPECIFIC_EXP]}" ]; then
            echo "Error: Unknown experiment '$SPECIFIC_EXP'"
            list_experiments
            exit 1
        fi

        run_experiment "$SPECIFIC_EXP" "${EXPERIMENTS[$SPECIFIC_EXP]}" "$STAGE"
        ;;

    *)
        echo "Error: No run mode specified"
        show_usage
        exit 1
        ;;
esac

echo "=========================================="
echo "All experiments completed!"
echo "=========================================="
