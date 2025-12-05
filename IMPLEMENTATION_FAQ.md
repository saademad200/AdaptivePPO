# Implementation FAQ: Will Python Code Handle Config Changes?

## ❓ Your Question
> "You have added all the experiments in config files. Is it sufficient? Will the Python files be able to handle these?"

## ✅ Short Answer
**Not automatically** - you need to implement the Python code to support these config parameters. The configs define **what** you want, but you need to write **how** it works.

---

## 📋 Current Status

### ✅ What Works Now (No Code Changes Needed)
- Baseline VinePPO
- All existing parameters in configs
- Running experiments with current code

### ❌ What Needs Implementation (Code Changes Required)

#### 1. Adaptive MC Rollouts
**Config parameters added**:
```jsonnet
{
    adaptive_rollouts: true,
    min_rollouts: 4,
    max_rollouts: 16,
    target_ci_width: 0.15,
}
```

**Code that needs to be written**: ⚠️ NOT YET IMPLEMENTED
- File: `src/treetune/episode_generators/math_episode_generator_with_mc_advantages.py`
- Functions to modify:
  - `_create_value_estimation_requests()` - Add adaptive sample logic
  - `_compute_token_advantages()` - Use adaptive estimates
  - `_update_trajectories_w_values()` - Handle variable sample sizes

#### 2. Curriculum Learning
**Config parameters added**:
```jsonnet
{
    enable_curriculum: true,
    initial_max_steps: 3,
    final_max_steps: 15,
    curriculum_schedule: "linear",
}
```

**Code that needs to be written**: ⚠️ NOT YET IMPLEMENTED
- Files:
  - `src/treetune/episode_generators/on_policy_episode_generator.py`
  - `src/treetune/runtime/policy_iteration_runtime.py`
- Functions to modify:
  - `_filter_init_dataset()` - Add step-count filtering
  - `_generate_episodes()` - Apply curriculum schedule
  - `get_current_max_steps()` - Compute schedule

#### 3. Running Advantage Statistics
**Config parameters added**:
```jsonnet
{
    use_running_advantage_stats: true,
    advantage_ema_decay: 0.99,
}
```

**Code that needs to be written**: ⚠️ NOT YET IMPLEMENTED
- File: `src/treetune/trainers/ppo_trainer.py`
- Functions to modify:
  - `__init__()` - Initialize EMA variables
  - `_compute_advantages()` - Add EMA tracking
  - `_normalize_advantages()` - Use running stats

---

## 🔧 Implementation Checklist

### Step 1: Understand the Baseline Code
**Before implementing anything**, run and understand:

```bash
# Run baseline first
./run_experiments.sh --baseline --stage train

# This will:
# 1. Show you how the existing code works
# 2. Give you a reference for where to add changes
# 3. Provide baseline results to compare against
```

### Step 2: Implement Each Improvement

#### Priority Order (Easiest to Hardest):

1. **Running Advantage Stats** (Easiest - ~4 hours)
   - Only modifies trainer
   - Clear implementation path
   - Easy to test

2. **Curriculum Learning** (Medium - ~8 hours)
   - Modifies episode generator + runtime
   - Straightforward filtering logic
   - Easy to validate

3. **Adaptive MC Rollouts** (Hardest - ~12 hours)
   - Complex logic for adaptive sampling
   - Requires understanding MC estimation
   - Needs careful testing

---

## 📝 Detailed Implementation Guide

### Implementation #1: Running Advantage Statistics

**File to modify**: `src/treetune/trainers/ppo_trainer.py`

**Step 1**: Add EMA variables to `__init__`

```python
class PPOTrainer(DeepSpeedPolicyTrainer):
    def __init__(self, ...):
        # ... existing code ...

        # NEW: Add running statistics
        self.use_running_advantage_stats = self.ppo_hparams.get(
            'use_running_advantage_stats', False
        )
        self.advantage_ema_decay = self.ppo_hparams.get(
            'advantage_ema_decay', 0.99
        )
        self.running_adv_mean = 0.0
        self.running_adv_std = 1.0
        self.running_stats_initialized = False
```

**Step 2**: Modify advantage normalization

Find the function that normalizes advantages (likely in `_train_step` or `_compute_advantages`):

```python
def _normalize_advantages(self, advantages):
    """Normalize advantages using batch or running statistics."""

    if self.use_running_advantage_stats and self.running_stats_initialized:
        # Use running statistics (EMA)
        batch_mean = advantages.mean().item()
        batch_std = advantages.std().item()

        # Update running statistics
        self.running_adv_mean = (
            self.advantage_ema_decay * self.running_adv_mean +
            (1 - self.advantage_ema_decay) * batch_mean
        )
        self.running_adv_std = (
            self.advantage_ema_decay * self.running_adv_std +
            (1 - self.advantage_ema_decay) * batch_std
        )

        # Normalize using running stats
        normalized = (advantages - self.running_adv_mean) / (self.running_adv_std + 1e-8)

        # Log statistics
        if self.cloud_logger:
            self.cloud_logger.log({
                'train/running_adv_mean': self.running_adv_mean,
                'train/running_adv_std': self.running_adv_std,
                'train/batch_adv_mean': batch_mean,
                'train/batch_adv_std': batch_std,
            })
    else:
        # Use batch statistics (original)
        normalized = (advantages - advantages.mean()) / (advantages.std() + 1e-8)

        # Initialize running stats from first batch
        if self.use_running_advantage_stats and not self.running_stats_initialized:
            self.running_adv_mean = advantages.mean().item()
            self.running_adv_std = advantages.std().item()
            self.running_stats_initialized = True

    return normalized
```

**Step 3**: Add to checkpoint save/load

```python
def save_checkpoint(self, ...):
    # ... existing code ...

    # Save running statistics
    if self.use_running_advantage_stats:
        checkpoint['running_adv_mean'] = self.running_adv_mean
        checkpoint['running_adv_std'] = self.running_adv_std
        checkpoint['running_stats_initialized'] = self.running_stats_initialized

def load_checkpoint(self, ...):
    # ... existing code ...

    # Load running statistics
    if self.use_running_advantage_stats:
        self.running_adv_mean = checkpoint.get('running_adv_mean', 0.0)
        self.running_adv_std = checkpoint.get('running_adv_std', 1.0)
        self.running_stats_initialized = checkpoint.get('running_stats_initialized', False)
```

**Testing**:
```bash
# Test with running stats config
./run_experiments.sh --experiment ablation3_running_stats --stage train

# Check logs for:
# - train/running_adv_mean (should change slowly)
# - train/running_adv_std (should stabilize over time)
```

---

### Implementation #2: Curriculum Learning

**Files to modify**:
1. `src/treetune/episode_generators/on_policy_episode_generator.py`
2. `src/treetune/runtime/policy_iteration_runtime.py`

**Step 1**: Add curriculum parameters to episode generator

```python
class OnPolicyEpisodeGenerator(EpisodeGenerator):
    def __init__(self, ...):
        # ... existing code ...

        # NEW: Curriculum learning parameters
        self.enable_curriculum = kwargs.get('enable_curriculum', False)
        self.initial_max_steps = kwargs.get('initial_max_steps', 3)
        self.final_max_steps = kwargs.get('final_max_steps', 15)
        self.curriculum_schedule = kwargs.get('curriculum_schedule', 'linear')
        self.current_max_steps = self.initial_max_steps
```

**Step 2**: Add step counting function

```python
def _count_reasoning_steps(self, example):
    """Count the number of reasoning steps in a solution."""
    solution = example.get('solution', '') or example.get('answer_without_calculator', '')

    # Count steps (solutions in GSM8K format like "Step 1...\nStep 2...\n#### Answer")
    steps = solution.split('\n')
    # Filter out empty lines and answer line
    reasoning_steps = [s for s in steps if s.strip() and not s.startswith('####')]

    return len(reasoning_steps)
```

**Step 3**: Modify dataset filtering

```python
def _filter_init_dataset(self, ds):
    """Filter dataset based on curriculum."""
    # Apply original filters (length, etc.)
    ds = super()._filter_init_dataset(ds)

    if not self.enable_curriculum:
        return ds

    # Filter by step count
    def filter_by_steps(example):
        num_steps = self._count_reasoning_steps(example)
        return num_steps <= self.current_max_steps

    filtered_ds = ds.filter(filter_by_steps, num_proc=4)

    logger.info(f"Curriculum filtering: {len(ds)} → {len(filtered_ds)} examples "
                f"(max_steps={self.current_max_steps})")

    return filtered_ds
```

**Step 4**: Add curriculum update function

```python
def update_curriculum(self, iteration, total_iterations):
    """Update curriculum schedule based on training progress."""
    if not self.enable_curriculum:
        return

    progress = iteration / total_iterations

    if self.curriculum_schedule == 'linear':
        self.current_max_steps = int(
            self.initial_max_steps +
            (self.final_max_steps - self.initial_max_steps) * progress
        )
    elif self.curriculum_schedule == 'exponential':
        # Exponential growth: slower at first, faster later
        exp_progress = progress ** 2
        self.current_max_steps = int(
            self.initial_max_steps +
            (self.final_max_steps - self.initial_max_steps) * exp_progress
        )

    logger.info(f"Curriculum update: iteration {iteration}/{total_iterations}, "
                f"max_steps={self.current_max_steps}")
```

**Step 5**: Update runtime to call curriculum update

In `src/treetune/runtime/policy_iteration_runtime.py`:

```python
def _generate_episodes(self, iteration_id, ...):
    # NEW: Update curriculum before generating episodes
    if hasattr(self.episode_generator, 'update_curriculum'):
        self.episode_generator.update_curriculum(
            iteration_id,
            self.num_iterations
        )

    # ... existing episode generation code ...
```

**Testing**:
```bash
# Test curriculum config
./run_experiments.sh --experiment ablation2_curriculum --stage train

# Check logs for:
# - "Curriculum update: iteration X/100, max_steps=Y"
# - "Curriculum filtering: 7100 → Z examples"
# - Progressive increase in max_steps over iterations
```

---

### Implementation #3: Adaptive MC Rollouts

**File to modify**: `src/treetune/episode_generators/math_episode_generator_with_mc_advantages.py`

**This is the most complex** - I'll provide a high-level outline:

**Step 1**: Add adaptive parameters

```python
class MathEpisodeGeneratorWithMCAdvantages(MathEpisodeGenerator):
    def __init__(self, ...):
        # ... existing code ...

        # NEW: Adaptive MC parameters
        self.adaptive_rollouts = kwargs.get('adaptive_rollouts', False)
        self.min_rollouts = kwargs.get('min_rollouts', 4)
        self.max_rollouts = kwargs.get('max_rollouts', 16)
        self.target_ci_width = kwargs.get('target_ci_width', 0.15)
```

**Step 2**: Add confidence interval computation

```python
def _compute_confidence_interval(self, samples):
    """Compute 95% confidence interval for binary outcomes."""
    import scipy.stats as stats

    n = len(samples)
    p = np.mean(samples)  # Success rate

    # Wilson score interval
    z = 1.96  # 95% confidence
    denominator = 1 + z**2 / n
    centre = (p + z**2 / (2*n)) / denominator
    margin = z * np.sqrt((p*(1-p) + z**2/(4*n)) / n) / denominator

    ci_lower = centre - margin
    ci_upper = centre + margin
    ci_width = ci_upper - ci_lower

    return ci_width, (ci_lower, ci_upper)
```

**Step 3**: Modify value estimation to use adaptive sampling

```python
def _create_value_estimation_requests_adaptive(self, trajectories, results_root_dir):
    """Create requests with adaptive number of rollouts."""

    all_requests = []

    for traj_idx, traj in enumerate(trajectories):
        for value_idx in range(len(traj['steps']) + 1):
            # Determine number of rollouts adaptively
            if self.adaptive_rollouts:
                # Start with minimum
                num_rollouts = self.min_rollouts

                # Will sample more if needed (implemented in inference strategy)
                adaptive_config = {
                    'min_rollouts': self.min_rollouts,
                    'max_rollouts': self.max_rollouts,
                    'target_ci_width': self.target_ci_width,
                    'adaptive': True,
                }
            else:
                # Fixed rollouts (original)
                num_rollouts = self.max_rollouts
                adaptive_config = {'adaptive': False}

            request = {
                'traj_idx': traj_idx,
                'value_idx': value_idx,
                'num_rollouts': num_rollouts,
                'adaptive_config': adaptive_config,
                # ... other fields ...
            }
            all_requests.append(request)

    return all_requests
```

**Note**: Full implementation of adaptive MC is complex and requires modifying the inference strategy to sample iteratively. For your project, you might simplify to:
- Use minimum samples for high-confidence steps (> 80% success)
- Use maximum samples for uncertain steps
- This gives most of the benefit with simpler implementation

---

## 🎯 Simplified Implementation Strategy

### For Your Class Project

**Option 1: Full Implementation** (Recommended if you have 3-4 weeks)
- Implement all three improvements as described above
- Most work, but best learning experience
- Strong paper with complete ablations

**Option 2: Partial Implementation** (If time is limited)
- Fully implement Running Stats + Curriculum (easier)
- Simulate Adaptive MC (use rule-based thresholds)
- Still publishable results, less complex

**Option 3: Baseline + Analysis** (Minimum viable)
- Run baseline VinePPO thoroughly
- Implement configs and show experimental setup
- Discuss proposed improvements in "Future Work"
- Still acceptable for class project

---

## 🚦 What Happens If You Run Configs Without Implementation?

### Current Behavior

If you run the improvement configs NOW (without implementing):

```bash
./run_experiments.sh --experiment ablation1_adaptive_mc
```

**What happens**:
1. ✅ Script runs
2. ✅ Config loads
3. ⚠️ **New parameters are IGNORED** (Python doesn't know about them)
4. ❌ Runs like baseline (no actual improvement)
5. ❌ Results will be identical to baseline

**The configs are specifications**, not implementations!

---

## ✅ Verification Checklist

### How to Know Your Implementation Works

#### For Running Advantage Stats:
- [ ] Log files show `train/running_adv_mean` and `train/running_adv_std`
- [ ] Values change slowly over iterations (not jumping)
- [ ] Training curves are smoother than baseline
- [ ] Checkpoints contain running statistics

#### For Curriculum Learning:
- [ ] Log files show "Curriculum filtering: X → Y examples"
- [ ] `max_steps` increases over iterations
- [ ] Early iterations have more examples than later
- [ ] Final accuracy improves vs baseline

#### For Adaptive MC:
- [ ] Log files show "Adaptive MC: used X samples (min=4, max=16)"
- [ ] Average samples < 16 (e.g., 8-10)
- [ ] Easy steps use fewer samples
- [ ] Hard steps use more samples
- [ ] Training is faster than baseline

---

## 📚 Learning Resources

### To Understand the Codebase

1. **Start here**: `src/treetune/runtime/policy_iteration_runtime.py:162`
   - Main training loop
   - Shows how everything connects

2. **Episode generation**: `src/treetune/episode_generators/math_episode_generator_with_mc_advantages.py`
   - How MC rollouts work
   - Where to add adaptive logic

3. **Training**: `src/treetune/trainers/ppo_trainer.py`
   - PPO algorithm
   - Where to add running stats

### Debugging Tips

```python
# Add lots of logging!
logger.info(f"DEBUG: current_max_steps={self.current_max_steps}")
logger.info(f"DEBUG: num_rollouts={num_rollouts}")
logger.info(f"DEBUG: running_mean={self.running_adv_mean}")

# Use debugger
import pdb; pdb.set_trace()  # Pause here

# Test on small dataset first
# In config:
episode_generator+: {
    dataset_portion: 0.01,  # Use 1% of data for testing
}
```

---

## 🎓 Summary

### Question 1: "Will Python code handle config changes?"

**Answer**: No, not automatically. You need to:
1. ✅ Configs define parameters (DONE - you have these)
2. ❌ Python code reads and uses them (TODO - needs implementation)
3. ⚠️ Without implementation, configs are ignored

### Question 2: "Is adding to config sufficient?"

**Answer**: It's the first step! Now you need:
1. Step 1: Add parameters to config ✅ (DONE)
2. Step 2: Implement Python code to use them ⚠️ (TODO)
3. Step 3: Test and validate 📝 (TODO)
4. Step 4: Run experiments and analyze 🧪 (TODO)

### Next Steps:

1. **Run baseline first** to understand the code
2. **Implement one improvement** at a time (start with easiest)
3. **Test each thoroughly** before moving to next
4. **Combine them** once all work individually
5. **Write your paper** with results!

**The configs are your roadmap - now you need to build the car!** 🚗
