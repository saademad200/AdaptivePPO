// Improvement #4: Value Estimation with Ensemble Diversity
// Enhances MC rollout diversity for more robust value estimates
{
    episode_generator+: {
        // Enable diverse ensemble sampling
        enable_diverse_ensemble: true,

        // Temperature scheduling for rollouts
        // Different temperatures explore different parts of the distribution
        ensemble_temperatures: [0.7, 1.0, 1.3],  // Low (conservative), Normal, High (exploratory)

        // Nucleus sampling (top-p) with varying p values
        // Controls diversity by limiting to top probability mass
        ensemble_top_p: [0.8, 0.9, 0.95],  // Conservative, Standard, Exploratory

        // Number of samples per temperature/top-p configuration
        samples_per_config: 4,  // Total: 3 temps × 4 samples = 12 samples

        // Diversity measurement
        measure_diversity: true,  // Track unique completions
        min_diversity_ratio: 0.5,  // Warn if < 50% unique completions

        // Optional: Determinantal Point Process (DPP) for diversity
        use_dpp_sampling: false,  // Advanced: penalize similar samples
        dpp_kernel_type: "cosine",  // Similarity metric: "cosine" or "rbf"

        // Ensemble aggregation method
        ensemble_aggregation: "mean",  // Options: "mean", "median", "weighted"
        temperature_weights: [0.3, 0.4, 0.3],  // Weights for each temperature
    },
}
