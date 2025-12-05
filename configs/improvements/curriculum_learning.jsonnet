// Improvement #2: Step-Level Curriculum Learning
// Gradually increases problem complexity during training
{
    episode_generator+: {
        // Curriculum learning for reasoning steps
        enable_curriculum: true,
        curriculum_type: "step_based",  // Options: "step_based", "difficulty_based"

        // Step-based curriculum parameters
        initial_max_steps: 3,           // Start with simple 3-step problems
        final_max_steps: 15,            // Progress to full 15-step problems
        curriculum_schedule: "linear",   // Options: "linear", "exponential", "adaptive"

        // Adaptive curriculum (adjusts based on performance)
        adaptive_curriculum: false,
        performance_threshold: 0.65,    // Move to next level if accuracy > 65%
        lookback_iterations: 5,         // Number of iterations to average performance
    },
}
