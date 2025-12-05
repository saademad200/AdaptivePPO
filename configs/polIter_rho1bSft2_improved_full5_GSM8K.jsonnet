// Full Improvements: All 5 Methods Combined
// Maximum improvement configuration

(import 'polIter_rho1bSft2_vineppo_GSM8K.jsonnet')
+ (import 'improvements/adaptive_mc_rollouts.jsonnet')
+ (import 'improvements/curriculum_learning.jsonnet')
+ (import 'improvements/running_advantage_stats.jsonnet')
+ (import 'improvements/ensemble_diversity.jsonnet')
+ (import 'improvements/multi_horizon_values.jsonnet')
+ {
    // Experiment tracking
    experiment_name: "vineppo_improved_full5",

    // Note: This combines all 5 improvements for maximum effect
    // May require hyperparameter tuning to work well together

    // Adjust some parameters for compatibility
    episode_generator+: {
        // Reduce max_rollouts since we have more diversity methods
        max_rollouts: 12,  // Down from 16

        // Use fewer samples per horizon since we have ensemble diversity
        rollouts_per_horizon: [6, 4, 3],  // Reduced from [8, 6, 4]
    },
}
