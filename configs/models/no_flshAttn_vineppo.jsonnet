{
    // Disable FlashAttention for GPUs with compute capability < 8.0 (e.g., Tesla T4)
    // VinePPO uses actor_model and reference_model (no critic)
    trainer+: {
        actor_model+: {
            pretrained_args+: {
                use_flash_attention_2: false,
            },
        },
        reference_model+: {
            pretrained_args+: {
                use_flash_attention_2: false,
            },
        },
    },
}
