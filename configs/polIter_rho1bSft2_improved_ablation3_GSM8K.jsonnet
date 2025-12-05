// Ablation Study #3: Running Advantage Stats Only
// Tests the impact of running statistics for advantage normalization

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/running_advantage_stats.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_running_stats_ablation3",
}
