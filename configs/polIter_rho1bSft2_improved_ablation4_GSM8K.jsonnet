// Ablation Study #4: Ensemble Diversity Only
// Tests the impact of diverse ensemble sampling independently

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/ensemble_diversity.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_ensemble_diversity_ablation4",
}
