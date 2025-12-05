// Pairwise Combination: Adaptive MC + Curriculum
// Tests synergy between adaptive rollouts and curriculum learning

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/adaptive_mc_rollouts.jsonnet')
+ (import 'improvements/curriculum_learning.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_mc_curriculum_combo",
}
