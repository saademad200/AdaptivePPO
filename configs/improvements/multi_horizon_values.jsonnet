// Improvement #5: Multi-Horizon Value Estimation
// Estimates values at multiple time scales for better credit assignment
{
    episode_generator+: {
        // Enable multi-horizon value estimation
        enable_multi_horizon: true,

        // Define horizons (lookahead distances)
        // Horizon 1 = immediate next step
        // Horizon 3 = 3 steps ahead
        // Horizon 5 = 5 steps ahead
        horizons: [1, 3, 5],  // Short-term, medium-term, long-term

        // Number of rollouts per horizon
        rollouts_per_horizon: [8, 6, 4],  // More for short-term, less for long-term
        // Rationale: Short-term is more certain, needs fewer samples
        //            Long-term is uncertain, but also less important

        // Horizon weights for combining estimates
        // These can be:
        // - Fixed: [0.5, 0.3, 0.2]
        // - Learned: Updated during training
        // - Adaptive: Based on uncertainty
        horizon_weights: [0.5, 0.3, 0.2],  // Prioritize short-term
        horizon_weight_type: "fixed",  // Options: "fixed", "learned", "adaptive"

        // Bootstrap values for intermediate steps
        use_bootstrap: true,
        bootstrap_discount: 0.99,  // Discount factor for future rewards

        // Temporal abstraction
        # Use intermediate rewards as bootstrap targets
        use_intermediate_rewards: true,
        intermediate_reward_type: "partial_correctness",  // Or "step_quality"

        // Variance reduction
        # Multi-horizon can increase variance, so use control variates
        use_control_variate: true,
        baseline_horizon: 1,  // Use horizon-1 as baseline

        // Adaptive horizon weights (if horizon_weight_type == "adaptive")
        adaptive_weight_update_rate: 0.01,
        adaptive_weight_based_on: "uncertainty",  // Or "performance"
    },
}
