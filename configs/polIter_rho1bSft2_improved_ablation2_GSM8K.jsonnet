// Ablation Study #2: Curriculum Learning Only
// Tests the impact of step-level curriculum independently

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/curriculum_learning.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_curriculum_ablation2",
}
