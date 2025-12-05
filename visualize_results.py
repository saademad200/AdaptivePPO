#!/usr/bin/env python3
"""
Visualize VinePPO Training Results
Analyzes wandb logs, checkpoints, and generates comparison plots
"""

import os
import json
import gzip
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import numpy as np

# Set style
sns.set_theme(style="whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)

def load_wandb_history(wandb_dir):
    """Load wandb event history"""
    run_dirs = [d for d in Path(wandb_dir).iterdir() if d.is_dir() and d.name.startswith('offline-run-')]
    if not run_dirs:
        run_dirs = [Path(wandb_dir) / 'latest-run']

    latest_run = max(run_dirs, key=lambda x: x.stat().st_mtime)
    print(f"Loading data from: {latest_run}")

    # Try to find event files
    event_files = list((latest_run / 'files').glob('*.csv*'))

    metrics = {}
    for event_file in event_files:
        print(f"  Found: {event_file.name}")
        if event_file.suffix == '.gz':
            with gzip.open(event_file, 'rt') as f:
                df = pd.read_csv(f)
                metrics[event_file.stem.replace('.csv', '')] = df
        else:
            df = pd.read_csv(event_file)
            metrics[event_file.stem] = df

    return metrics, latest_run

def load_json_files(wandb_dir):
    """Load JSON metric files"""
    run_dirs = [d for d in Path(wandb_dir).iterdir() if d.is_dir() and d.name.startswith('offline-run-')]
    if not run_dirs:
        run_dirs = [Path(wandb_dir) / 'latest-run']

    latest_run = max(run_dirs, key=lambda x: x.stat().st_mtime)

    json_files = list((latest_run / 'files').glob('*.json'))
    json_data = {}

    for json_file in json_files:
        try:
            with open(json_file, 'r') as f:
                data = json.load(f)
                json_data[json_file.stem] = data
                print(f"  Loaded JSON: {json_file.name}")
        except Exception as e:
            print(f"  Error loading {json_file.name}: {e}")

    return json_data

def plot_advantage_distribution(metrics, output_dir):
    """Plot advantage distribution over iterations"""
    print("\n=== Plotting Advantage Distribution ===")

    # Find advantage CSV files
    advantage_files = [k for k in metrics.keys() if 'advantages' in k.lower()]

    if not advantage_files:
        print("No advantage distribution data found")
        return

    fig, axes = plt.subplots(1, 2, figsize=(15, 5))

    for adv_file in advantage_files:
        df = metrics[adv_file]

        # Plot histogram
        axes[0].hist(df.iloc[:, 0], bins=50, alpha=0.7, label=adv_file.split('__')[1])

        # Plot cumulative distribution
        sorted_data = np.sort(df.iloc[:, 0])
        cumulative = np.arange(1, len(sorted_data) + 1) / len(sorted_data)
        axes[1].plot(sorted_data, cumulative, label=adv_file.split('__')[1])

    axes[0].set_xlabel('Advantage Value')
    axes[0].set_ylabel('Frequency')
    axes[0].set_title('Advantage Distribution')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    axes[1].set_xlabel('Advantage Value')
    axes[1].set_ylabel('Cumulative Probability')
    axes[1].set_title('Cumulative Advantage Distribution')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    output_file = output_dir / 'advantage_distribution.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Saved: {output_file}")
    plt.close()

def plot_value_distribution(metrics, output_dir):
    """Plot value distribution"""
    print("\n=== Plotting Value Distribution ===")

    value_files = [k for k in metrics.keys() if 'values' in k.lower()]

    if not value_files:
        print("No value distribution data found")
        return

    fig, axes = plt.subplots(1, 2, figsize=(15, 5))

    for val_file in value_files:
        df = metrics[val_file]

        # Plot histogram
        axes[0].hist(df.iloc[:, 0], bins=50, alpha=0.7, label=val_file.split('__')[1])

        # Box plot
        axes[1].boxplot([df.iloc[:, 0]], labels=[val_file.split('__')[1]])

    axes[0].set_xlabel('Value Estimate')
    axes[0].set_ylabel('Frequency')
    axes[0].set_title('Value Distribution')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    axes[1].set_ylabel('Value Estimate')
    axes[1].set_title('Value Distribution (Box Plot)')
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    output_file = output_dir / 'value_distribution.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Saved: {output_file}")
    plt.close()

def analyze_gradient_variance(json_data, output_dir):
    """Analyze gradient variance data"""
    print("\n=== Analyzing Gradient Variance ===")

    grad_files = [k for k in json_data.keys() if 'PPOGradientVariance' in k]

    if not grad_files:
        print("No gradient variance data found")
        return

    for grad_file in grad_files:
        data = json_data[grad_file]
        print(f"\nGradient Variance Analysis ({grad_file}):")
        for key, value in data.items():
            print(f"  {key}: {value}")

def create_summary_report(metrics, json_data, output_dir):
    """Create a summary report"""
    print("\n=== Creating Summary Report ===")

    report = []
    report.append("=" * 80)
    report.append("VinePPO Training Results Summary")
    report.append("=" * 80)
    report.append("")

    # Advantage statistics
    advantage_files = [k for k in metrics.keys() if 'advantages' in k.lower()]
    if advantage_files:
        report.append("Advantage Statistics:")
        for adv_file in advantage_files:
            df = metrics[adv_file]
            report.append(f"  File: {adv_file}")
            report.append(f"    Mean: {df.iloc[:, 0].mean():.4f}")
            report.append(f"    Std:  {df.iloc[:, 0].std():.4f}")
            report.append(f"    Min:  {df.iloc[:, 0].min():.4f}")
            report.append(f"    Max:  {df.iloc[:, 0].max():.4f}")
            report.append("")

    # Value statistics
    value_files = [k for k in metrics.keys() if 'values' in k.lower()]
    if value_files:
        report.append("Value Estimate Statistics:")
        for val_file in value_files:
            df = metrics[val_file]
            report.append(f"  File: {val_file}")
            report.append(f"    Mean: {df.iloc[:, 0].mean():.4f}")
            report.append(f"    Std:  {df.iloc[:, 0].std():.4f}")
            report.append(f"    Min:  {df.iloc[:, 0].min():.4f}")
            report.append(f"    Max:  {df.iloc[:, 0].max():.4f}")
            report.append("")

    # Gradient variance
    grad_files = [k for k in json_data.keys() if 'PPOGradientVariance' in k]
    if grad_files:
        report.append("Gradient Variance:")
        for grad_file in grad_files:
            data = json_data[grad_file]
            report.append(f"  {grad_file}:")
            for key, value in data.items():
                report.append(f"    {key}: {value}")
            report.append("")

    report.append("=" * 80)

    # Save report
    report_text = "\n".join(report)
    print(report_text)

    output_file = output_dir / 'summary_report.txt'
    with open(output_file, 'w') as f:
        f.write(report_text)
    print(f"\nSaved report: {output_file}")

def compare_with_paper(output_dir):
    """Create comparison table with paper results"""
    print("\n=== Paper Comparison ===")

    # VinePPO paper baseline results (from paper Table 1)
    paper_results = {
        'Model': ['Rho-1B SFT', 'Rho-1B + VinePPO'],
        'GSM8K': [40.5, 53.0],  # Approximate values from paper
        'MATH': [9.6, 16.2],
    }

    comparison = """
    ╔══════════════════════════════════════════════════════════════╗
    ║           VinePPO Paper Results (Reference)                  ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ Model                │ GSM8K Accuracy │ MATH Accuracy        ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ Rho-1B SFT           │     40.5%      │      9.6%            ║
    ║ Rho-1B + VinePPO     │     53.0%      │     16.2%            ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ Improvement          │    +12.5%      │     +6.6%            ║
    ╚══════════════════════════════════════════════════════════════╝

    Note: Your run only completed 1 iteration (iteration 0).
    The paper results are from 650 iterations of training.

    To get comparable results:
    1. Run full training: ./run.sh (will take ~several hours/days)
    2. Check num_iterations in config (should be 650)
    3. Monitor progress in wandb logs
    4. Final evaluation will show test accuracy
    """

    print(comparison)

    output_file = output_dir / 'paper_comparison.txt'
    with open(output_file, 'w') as f:
        f.write(comparison)
    print(f"Saved: {output_file}")

def main():
    # Setup paths
    wandb_dir = Path('wandb')
    output_dir = Path('results_analysis')
    output_dir.mkdir(exist_ok=True)

    if not wandb_dir.exists():
        print(f"Error: wandb directory not found at {wandb_dir}")
        print("Make sure you run this script from the VinePPO root directory")
        return

    print("=" * 80)
    print("VinePPO Results Visualization")
    print("=" * 80)

    # Load data
    print("\nLoading wandb data...")
    metrics, latest_run = load_wandb_history(wandb_dir)
    json_data = load_json_files(wandb_dir)

    print(f"\nFound {len(metrics)} CSV metric files")
    print(f"Found {len(json_data)} JSON metric files")

    # Generate visualizations
    if metrics:
        plot_advantage_distribution(metrics, output_dir)
        plot_value_distribution(metrics, output_dir)

    if json_data:
        analyze_gradient_variance(json_data, output_dir)

    # Create summary
    create_summary_report(metrics, json_data, output_dir)

    # Compare with paper
    compare_with_paper(output_dir)

    print("\n" + "=" * 80)
    print(f"Analysis complete! Check the '{output_dir}' directory for results.")
    print("=" * 80)

if __name__ == '__main__':
    main()
