// Ablation Study #5: Multi-Horizon Value Estimation Only
// Tests the impact of multi-horizon values independently

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/multi_horizon_values.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_multi_horizon_ablation5",
}
