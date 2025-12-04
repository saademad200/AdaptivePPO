{
    episode_generator+: {
        vllm_server+: {
            swap_space: 20,
            dtype: "float16",
        },
        dataset_shuffle_on_each_iteration: true,
        dataset_shuffle_before_portion: true,
    }
}