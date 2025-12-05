// Improvement #4: Running Statistics for Advantage Normalization
// Uses exponential moving average for more stable advantage normalization
{
    trainer+: {
        params+: {
            // Enable running statistics for advantage normalization
            use_running_advantage_stats: true,
            advantage_ema_decay: 0.99,          // Decay factor for EMA (0.99 = slow update)
            advantage_running_start_iter: 2,    // Start using running stats after N iterations

            // Variance reduction techniques
            clip_advantage_percentile: 99.0,    // Clip extreme advantages (optional)
            advantage_scale_factor: 1.0,        // Additional scaling (for tuning)
        },
    },
}
