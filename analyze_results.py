#!/usr/bin/env python3
"""
Results Analysis Script for VinePPO Improvements

This script analyzes experimental results and generates tables/plots for the research paper.
Usage: python analyze_results.py --experiments baseline ablation1_adaptive_mc combined_full
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Dict, List, Any

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def load_experiment_results(exp_dir: Path) -> Dict[str, Any]:
    """Load results from an experiment directory."""
    results = {
        "name": exp_dir.name,
        "config": None,
        "eval_results": [],
        "training_metrics": {},
    }

    # Load config
    config_path = exp_dir / "config.json"
    if config_path.exists():
        with open(config_path, "r") as f:
            results["config"] = json.load(f)

    # Load evaluation results
    eval_dir = exp_dir / "evaluation"
    if eval_dir.exists():
        for checkpoint_dir in eval_dir.iterdir():
            if checkpoint_dir.is_dir() and checkpoint_dir.name.startswith("ckpt--"):
                # Load checkpoint evaluation
                done_file = checkpoint_dir / "done"
                if done_file.exists():
                    results["eval_results"].append({
                        "checkpoint": checkpoint_dir.name,
                        # Add logic to parse evaluation metrics
                    })

    return results


def create_ablation_table(experiments: List[Dict[str, Any]]) -> pd.DataFrame:
    """Create ablation study comparison table."""
    data = []
    for exp in experiments:
        row = {
            "Method": exp["name"],
            "Accuracy (%)": 0.0,  # Parse from results
            "Training Time (h)": 0.0,
            "Avg MC Samples": 0,
            "Convergence Iter": 0,
        }
        data.append(row)

    df = pd.DataFrame(data)
    return df


def plot_training_curves(experiments: List[Dict[str, Any]], output_dir: Path):
    """Plot training curves comparing different methods."""
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))

    # Accuracy over iterations
    ax = axes[0, 0]
    for exp in experiments:
        # Plot accuracy curve
        ax.plot([], [], label=exp["name"])
    ax.set_xlabel("Iteration")
    ax.set_ylabel("Accuracy (%)")
    ax.set_title("Test Accuracy over Training")
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Loss over iterations
    ax = axes[0, 1]
    for exp in experiments:
        # Plot loss curve
        ax.plot([], [], label=exp["name"])
    ax.set_xlabel("Iteration")
    ax.set_ylabel("Loss")
    ax.set_title("Training Loss")
    ax.legend()
    ax.grid(True, alpha=0.3)

    # MC samples distribution (for adaptive MC)
    ax = axes[1, 0]
    # Histogram or violin plot of MC samples used
    ax.set_xlabel("Number of MC Samples")
    ax.set_ylabel("Frequency")
    ax.set_title("Distribution of MC Samples (Adaptive)")
    ax.grid(True, alpha=0.3)

    # Advantage statistics (for running stats)
    ax = axes[1, 1]
    # Plot running mean/std of advantages
    ax.set_xlabel("Iteration")
    ax.set_ylabel("Advantage Std")
    ax.set_title("Advantage Statistics over Time")
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_dir / "training_curves.png", dpi=300, bbox_inches="tight")
    print(f"Saved plot: {output_dir / 'training_curves.png'}")


def plot_efficiency_comparison(experiments: List[Dict[str, Any]], output_dir: Path):
    """Plot computational efficiency comparison."""
    fig, ax = plt.subplots(1, 1, figsize=(10, 6))

    methods = [exp["name"] for exp in experiments]
    time_per_iter = [0.0] * len(experiments)  # Parse from results
    mc_samples = [0.0] * len(experiments)

    x = np.arange(len(methods))
    width = 0.35

    ax.bar(x - width/2, time_per_iter, width, label="Time per Iter (min)", alpha=0.8)
    ax.bar(x + width/2, mc_samples, width, label="Avg MC Samples", alpha=0.8)

    ax.set_xlabel("Method")
    ax.set_ylabel("Value")
    ax.set_title("Computational Efficiency Comparison")
    ax.set_xticks(x)
    ax.set_xticklabels(methods, rotation=45, ha="right")
    ax.legend()
    ax.grid(True, alpha=0.3, axis="y")

    plt.tight_layout()
    plt.savefig(output_dir / "efficiency_comparison.png", dpi=300, bbox_inches="tight")
    print(f"Saved plot: {output_dir / 'efficiency_comparison.png'}")


def generate_latex_table(df: pd.DataFrame, output_dir: Path):
    """Generate LaTeX table for the paper."""
    latex_str = df.to_latex(index=False, float_format="%.2f")

    latex_file = output_dir / "ablation_table.tex"
    with open(latex_file, "w") as f:
        f.write(latex_str)

    print(f"Saved LaTeX table: {latex_file}")


def main():
    parser = argparse.ArgumentParser(description="Analyze VinePPO experiment results")
    parser.add_argument(
        "--experiments",
        nargs="+",
        required=True,
        help="List of experiment names to analyze",
    )
    parser.add_argument(
        "--exp-root",
        type=str,
        default="experiments",
        help="Root directory for experiments",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="paper_results",
        help="Output directory for figures and tables",
    )

    args = parser.parse_args()

    exp_root = Path(args.exp_root)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True, parents=True)

    # Load all experiment results
    print("Loading experiment results...")
    experiments = []
    for exp_name in args.experiments:
        exp_dir = exp_root / exp_name
        if not exp_dir.exists():
            print(f"Warning: Experiment directory not found: {exp_dir}")
            continue

        results = load_experiment_results(exp_dir)
        experiments.append(results)
        print(f"  Loaded: {exp_name}")

    if not experiments:
        print("Error: No valid experiments found!")
        sys.exit(1)

    # Generate ablation table
    print("\nGenerating ablation table...")
    ablation_df = create_ablation_table(experiments)
    print(ablation_df)
    ablation_df.to_csv(output_dir / "ablation_results.csv", index=False)
    generate_latex_table(ablation_df, output_dir)

    # Generate plots
    print("\nGenerating plots...")
    plot_training_curves(experiments, output_dir)
    plot_efficiency_comparison(experiments, output_dir)

    print("\n" + "="*60)
    print("Analysis complete!")
    print(f"Results saved to: {output_dir}")
    print("="*60)


if __name__ == "__main__":
    main()
