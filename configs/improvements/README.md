# VinePPO Improvements - Config Documentation

This directory contains modular configuration files for the improved VinePPO method.

## Overview

Three main improvements are implemented:
1. **Adaptive MC Rollouts** - Dynamic allocation of Monte Carlo samples
2. **Curriculum Learning** - Progressive difficulty scheduling
3. **Running Advantage Stats** - Stable advantage normalization using EMA

## Config Files

### Individual Improvements (Modular)
- `adaptive_mc_rollouts.jsonnet` - Improvement #1
- `curriculum_learning.jsonnet` - Improvement #2
- `running_advantage_stats.jsonnet` - Improvement #3
- `combined_improvements.jsonnet` - All improvements together

### Experiment Configs (In parent configs/ directory)
- `polIter_rho1bSft2_vineppo_GSM8K.jsonnet` - **Baseline**
- `polIter_rho1bSft2_improved_ablation1_GSM8K.jsonnet` - Ablation #1 (Adaptive MC only)
- `polIter_rho1bSft2_improved_ablation2_GSM8K.jsonnet` - Ablation #2 (Curriculum only)
- `polIter_rho1bSft2_improved_ablation3_GSM8K.jsonnet` - Ablation #3 (Running stats only)
- `polIter_rho1bSft2_improved_combined_GSM8K.jsonnet` - **Main improved method**
- `polIter_rho1bSft2_improved_mc_curriculum_GSM8K.jsonnet` - Pairwise combo

## Recommended Experiment Plan

### Phase 1: Baseline (Week 1)
```bash
# Run baseline VinePPO
CONFIGSTR="configs/polIter_rho1bSft2_vineppo_GSM8K.jsonnet"
APP_DIRECTORY="experiments/baseline_vineppo"
```

### Phase 2: Ablation Studies (Week 2)
Run each improvement individually:

```bash
# Ablation #1: Adaptive MC
CONFIGSTR="configs/polIter_rho1bSft2_improved_ablation1_GSM8K.jsonnet"
APP_DIRECTORY="experiments/ablation1_adaptive_mc"

# Ablation #2: Curriculum
CONFIGSTR="configs/polIter_rho1bSft2_improved_ablation2_GSM8K.jsonnet"
APP_DIRECTORY="experiments/ablation2_curriculum"

# Ablation #3: Running Stats
CONFIGSTR="configs/polIter_rho1bSft2_improved_ablation3_GSM8K.jsonnet"
APP_DIRECTORY="experiments/ablation3_running_stats"
```

### Phase 3: Combined Method (Week 3)
```bash
# Full improved method
CONFIGSTR="configs/polIter_rho1bSft2_improved_combined_GSM8K.jsonnet"
APP_DIRECTORY="experiments/improved_combined"
```

## Expected Results

| Method | Accuracy | Training Time | MC Samples | Notes |
|--------|----------|---------------|------------|-------|
| Baseline VinePPO | ~75% | 100% | Fixed (16) | Reference |
| + Adaptive MC | ~76% | 75% | 4-16 (avg ~8) | 25% faster |
| + Curriculum | ~77% | 80% | Fixed (16) | Better convergence |
| + Running Stats | ~76% | 100% | Fixed (16) | More stable |
| **Combined** | **~78%** | **70%** | 4-16 (avg ~8) | **Best overall** |

## Hyperparameter Tuning

### Adaptive MC Rollouts
- `min_rollouts`: Lower = more efficient, but less robust (recommended: 4-8)
- `max_rollouts`: Higher = better estimates, slower (recommended: 12-20)
- `target_ci_width`: Tighter = more samples (recommended: 0.10-0.20)

### Curriculum Learning
- `initial_max_steps`: Start easier (recommended: 3-5)
- `final_max_steps`: Full complexity (recommended: 12-15)
- `curriculum_schedule`: Linear works well for GSM8K

### Running Advantage Stats
- `advantage_ema_decay`: Higher = smoother but slower adaptation (recommended: 0.95-0.99)
- `advantage_running_start_iter`: Wait for stats to stabilize (recommended: 2-5)

## Paper Sections Mapping

### Ablation Table
Compare all 5 variants:
- Baseline
- +Adaptive MC (ablation1)
- +Curriculum (ablation2)
- +Running Stats (ablation3)
- Combined (main)

### Computational Efficiency
- Measure wall-clock time per iteration
- Track total MC samples used
- Plot convergence curves (iterations to target accuracy)

### Analysis
- **Adaptive MC**: Show CI width vs. samples allocated
- **Curriculum**: Plot max_steps schedule and accuracy over iterations
- **Running Stats**: Show advantage variance over time
