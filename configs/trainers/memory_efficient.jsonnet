{
    // Memory-efficient training config for limited GPU memory (Tesla T4)
    trainer+: {
        training_args+: {
            per_device_train_batch_size: 16,  // Reduced from 32
            gradient_accumulation_steps: 2,    // Maintain effective batch size of 32
        },
    },
}
