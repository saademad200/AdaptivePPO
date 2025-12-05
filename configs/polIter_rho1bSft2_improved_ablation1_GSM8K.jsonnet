// Ablation Study #1: Adaptive MC Rollouts Only
// Tests the impact of adaptive rollout allocation independently

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/adaptive_mc_rollouts.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_adaptive_mc_ablation1",
}
