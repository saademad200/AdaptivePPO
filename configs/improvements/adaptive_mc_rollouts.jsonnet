// Improvement #1: Adaptive Monte Carlo Rollout Strategy
// Dynamically adjusts the number of MC samples based on uncertainty
{
    episode_generator+: {
        // Configuration for adaptive rollout allocation
        adaptive_rollouts: true,
        min_rollouts: 4,              // Minimum number of rollouts per state
        max_rollouts: 16,             // Maximum number of rollouts per state
        target_ci_width: 0.15,        // Target confidence interval width
        adaptive_strategy: "uncertainty",  // Options: "uncertainty", "criticality", "hybrid"

        // Uncertainty-based: allocate more samples when CI is wide
        // Criticality-based: allocate more samples to early steps
        // Hybrid: combine both strategies
    },
}
