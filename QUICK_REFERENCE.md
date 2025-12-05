# VinePPO Improvements - Quick Reference Card

## 🚀 Quick Commands

### Run Single Experiment
```bash
./run_experiments.sh --experiment <name> --stage <train|eval|both>
```

### Run Everything
```bash
./run_experiments.sh --all --stage both
```

### Analyze Results
```bash
python analyze_results.py --experiments baseline combined_full \
    --output-dir paper_results
```

---

## 📊 Experiment Names

| Name | Description | Config File |
|------|-------------|-------------|
| `baseline` | Original VinePPO | `polIter_rho1bSft2_vineppo_GSM8K.jsonnet` |
| `ablation1_adaptive_mc` | Adaptive MC only | `polIter_rho1bSft2_improved_ablation1_GSM8K.jsonnet` |
| `ablation2_curriculum` | Curriculum only | `polIter_rho1bSft2_improved_ablation2_GSM8K.jsonnet` |
| `ablation3_running_stats` | Running stats only | `polIter_rho1bSft2_improved_ablation3_GSM8K.jsonnet` |
| `combined_full` | All improvements ⭐ | `polIter_rho1bSft2_improved_combined_GSM8K.jsonnet` |

---

## 🎯 Your 3 Improvements

### 1. Adaptive MC Rollouts
**Config**: `configs/improvements/adaptive_mc_rollouts.jsonnet`

**Key Parameters**:
```jsonnet
{
    min_rollouts: 4,           // Start with 4 samples
    max_rollouts: 16,          // Max 16 samples
    target_ci_width: 0.15,     // Tighter = more samples
    adaptive_strategy: "uncertainty",
}
```

**What it does**: Allocates more MC samples when value estimates are uncertain

---

### 2. Curriculum Learning
**Config**: `configs/improvements/curriculum_learning.jsonnet`

**Key Parameters**:
```jsonnet
{
    initial_max_steps: 3,      // Start with 3-step problems
    final_max_steps: 15,       // End with 15-step problems
    curriculum_schedule: "linear",
}
```

**What it does**: Gradually increases problem difficulty during training

---

### 3. Running Advantage Stats
**Config**: `configs/improvements/running_advantage_stats.jsonnet`

**Key Parameters**:
```jsonnet
{
    use_running_advantage_stats: true,
    advantage_ema_decay: 0.99,  // Smoothing factor
}
```

**What it does**: Uses EMA for stable advantage normalization

---

## 📁 Key Files to Modify

### For Adaptive MC Rollouts:
```
src/treetune/episode_generators/math_episode_generator_with_mc_advantages.py
```
**Functions to modify**:
- `_create_value_estimation_requests()` - adaptive sample allocation
- `_compute_token_advantages()` - use adaptive estimates

### For Curriculum Learning:
```
src/treetune/episode_generators/on_policy_episode_generator.py
src/treetune/runtime/policy_iteration_runtime.py
```
**Functions to modify**:
- `_filter_init_dataset()` - filter by step count
- `_generate_episodes()` - apply curriculum schedule

### For Running Advantage Stats:
```
src/treetune/trainers/ppo_trainer.py
```
**Functions to modify**:
- `_compute_advantages()` - add EMA tracking
- `_train_step()` - update running statistics

---

## 📈 Expected Results

| Metric | Baseline | Combined | Change |
|--------|----------|----------|--------|
| **Accuracy** | 75% | 78% | +3% ✅ |
| **Training Time** | 10h | 7h | -30% ✅ |
| **MC Samples** | 16 | 8.5 | -47% ✅ |
| **Iterations to 70%** | 60 | 42 | -30% ✅ |

---

## 🐛 Quick Debugging

### Check Config is Valid
```bash
python src/treetune/main.py --configs your_config.jsonnet --dry-run
```

### Monitor Training
```bash
# Watch training logs
tail -f experiments/<exp_name>/log.txt

# Check GPU usage
watch -n 1 nvidia-smi
```

### Resume Failed Training
```bash
# Set force_rerun=false in config (default)
# Training will auto-resume from last checkpoint
```

---

## 📊 Paper Sections Mapping

| Section | Experiments Needed | Commands |
|---------|-------------------|----------|
| **Baseline Reproduction** | Run baseline VinePPO | `--baseline` |
| **Ablation Table** | 3 ablations + combined | `--ablations`, `--combined` |
| **Training Curves** | All 5 experiments | `--all` |
| **Efficiency Analysis** | Baseline + combined | Compare metrics |
| **Qualitative Examples** | Manual inspection | Check logs |

---

## ⚙️ Hyperparameter Tuning

### If Accuracy is Low:
- [ ] Increase `max_rollouts` (16 → 20)
- [ ] Slower curriculum (`initial_max_steps: 5`)
- [ ] Higher `advantage_ema_decay` (0.99 → 0.995)

### If Training is Slow:
- [ ] Decrease `max_rollouts` (16 → 12)
- [ ] Faster curriculum (use `"exponential"`)
- [ ] Reduce `dataset_portion` (1.0 → 0.5)

### If Training is Unstable:
- [ ] Enable running stats earlier (`advantage_running_start_iter: 1`)
- [ ] Clip extreme advantages (`clip_advantage_percentile: 95`)
- [ ] Lower learning rate (in trainer config)

---

## 🎓 Report Checklist

### Required Sections:
- [ ] Abstract (150 words)
- [ ] Introduction (problem + contributions)
- [ ] Related Work (cite 10-15 papers)
- [ ] Background on VinePPO
- [ ] Your 3 improvements (with motivation)
- [ ] Experimental setup
- [ ] Results (ablation table + figures)
- [ ] Analysis and discussion
- [ ] Conclusion
- [ ] References

### Required Figures:
- [ ] Training curves (accuracy over iterations)
- [ ] Efficiency comparison (bar chart)
- [ ] MC sample distribution (histogram)
- [ ] Curriculum schedule (line plot)
- [ ] Advantage statistics (line plot)

### Required Tables:
- [ ] Main results (5 methods)
- [ ] Computational efficiency
- [ ] Hyperparameters used

---

## 💾 Backup Strategy

### Save These Regularly:
```bash
# Configs
cp -r configs/improvements/ backup/configs_$(date +%Y%m%d)/

# Results
cp -r experiments/ backup/experiments_$(date +%Y%m%d)/

# Code changes
git add -A && git commit -m "Progress checkpoint $(date +%Y%m%d)"
```

---

## 🆘 Emergency Contacts

### If Things Break:
1. Check `experiments/<exp_name>/log.txt` for errors
2. Validate config: `--dry-run`
3. Test on small data: `dataset_portion: 0.01`
4. Start fresh: `rm -rf experiments/<exp_name>`

### Common Error Messages:

**"CUDA out of memory"**:
```jsonnet
trainer+: { per_device_batch_size: 4 }  // Reduce batch size
```

**"vLLM server failed to start"**:
```jsonnet
vllm_server+: { dtype: "float16" }  // Already set for Tesla T4
```

**"Config validation error"**:
```bash
# Check syntax
jsonnetfmt --test configs/your_config.jsonnet
```

---

## 🎯 Success Criteria

### Minimum Viable Project:
✅ Baseline reproduced (within ±2%)
✅ 1-2 improvements implemented
✅ Ablation study completed
✅ 8-page report written

### Strong Project:
✅ All 3 improvements working
✅ Combined method beats baseline by 2%+
✅ Computational efficiency gains shown
✅ Thorough analysis with 5+ figures

### Excellent Project:
✅ All of above +
✅ Hyperparameter sensitivity analysis
✅ Multiple seeds (statistical significance)
✅ Novel insights or additional improvements
✅ Clean, well-documented code

---

## ⏱️ Time Estimates

| Task | Time | When |
|------|------|------|
| Setup & baseline | 2-3 days | Week 1 |
| Implement improvements | 4-5 days | Week 2 |
| Run experiments | 3-4 days | Week 3 |
| Analysis & writing | 4-5 days | Week 4 |

**Total**: 13-17 days (assuming parallel GPU time)

---

## 📞 Quick Links

- **Full Guide**: `RESEARCH_PROJECT_GUIDE.md`
- **Config Docs**: `configs/improvements/README.md`
- **VinePPO Paper**: https://arxiv.org/abs/2410.01679
- **Original Code**: https://github.com/McGill-NLP/VinePPO

---

**Pro Tip**: Start with `./run_experiments.sh --baseline` and make sure that works before implementing improvements!
