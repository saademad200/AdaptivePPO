// Combined Improvements: All three improvements together
// This config combines adaptive MC, curriculum learning, and running advantage stats

(import 'adaptive_mc_rollouts.jsonnet')
+ (import 'curriculum_learning.jsonnet')
+ (import 'running_advantage_stats.jsonnet')
+ {
    // Additional tuning for combined approach
    trainer+: {
        params+: {
            // Slightly adjust PPO parameters for combined method
            cliprange: 0.2,              // Keep standard clip range
            init_kl_coef: 0.15,          // Slightly lower KL coefficient
        },
    },

    episode_generator+: {
        // Adjust curriculum to work better with adaptive rollouts
        curriculum_schedule: "exponential",  // Faster progression works better
    },
}
