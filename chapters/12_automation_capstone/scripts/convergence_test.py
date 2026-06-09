#!/usr/bin/env python3
"""
convergence_test.py — 自动化截断能收敛测试 + matplotlib 可视化

工作流程:
    1. 用 generate_inputs.py 的逻辑生成一系列 ecutwfc 输入文件
    2. 依次调用 pw.x 运行 SCF 计算
    3. 解析每个输出的总能量
    4. 绘制收敛曲线 (E vs ecutwfc)

用法:
    python convergence_test.py              # 使用默认参数
    python convergence_test.py --dry-run    # 仅生成输入，不运行计算

依赖: numpy, matplotlib（可选；--dry-run 模式无依赖）
"""
import os
import re
import subprocess
import argparse
from string import Template

# ---------------------------------------------------------------------------
# 参数
# ---------------------------------------------------------------------------
ECUT_LIST = [20, 30, 40, 50, 60, 70, 80]  # Ry
ECUT_RATIO = 8                             # ecutrho = ecutwfc * ratio
PW_CMD = "pw.x"                            # pw.x 可执行文件路径
NPROC = 4                                  # MPI 进程数
OUTPUT_DIR = "conv_test"

# ---------------------------------------------------------------------------
# 输入模板
# ---------------------------------------------------------------------------
SCF_TPL = Template("""\
&CONTROL
  calculation='scf', prefix='gaas', outdir='./tmp',
  pseudo_dir='/home/faust/pseudo', restart_mode='from_scratch'
/
&SYSTEM
  ibrav=2, celldm(1)=10.6917, nat=2, ntyp=2,
  ecutwfc=$ecutwfc, ecutrho=$ecutrho, nbnd=20
/
&ELECTRONS
  conv_thr=1.0d-8, mixing_beta=0.3
/
ATOMIC_SPECIES
Ga  69.723  Ga.pbe-dn-kjpaw_psl.1.0.0.UPF
As  74.922  As.pbe-n-kjpaw_psl.1.0.0.UPF
ATOMIC_POSITIONS crystal
Ga  0.00  0.00  0.00
As  0.25  0.25  0.25
K_POINTS automatic
8 8 8 0 0 0
""")


def parse_energy(out_file: str) -> float | None:
    """从 pw.x 输出中提取总能量 (Ry)。"""
    with open(out_file) as f:
        text = f.read()
    m = re.search(r"!\s+total energy\s+=\s+([-\d.Ee+]+)\s+Ry", text)
    return float(m.group(1)) if m else None


def run_conv_test(dry_run: bool = False):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    results = []

    print(f"{'ecutwfc':>8} {'ecutrho':>8} {'E (Ry)':>20} {'状态'}")
    print("-" * 50)

    for ecut in ECUT_LIST:
        ecutrho = ecut * ECUT_RATIO
        in_name = os.path.join(OUTPUT_DIR, f"ecut{ecut}.in")
        out_name = os.path.join(OUTPUT_DIR, f"ecut{ecut}.out")

        # 写入输入文件
        with open(in_name, "w") as f:
            f.write(SCF_TPL.substitute(ecutwfc=ecut, ecutrho=ecutrho))

        if dry_run:
            print(f"{ecut:>8} {ecutrho:>8} {'(dry-run)':>20}  已生成")
            continue

        # 运行 pw.x
        cmd = f"mpirun -np {NPROC} {PW_CMD} -in {in_name}"
        with open(out_name, "w") as fout:
            subprocess.run(cmd, shell=True, stdout=fout, stderr=subprocess.STDOUT)

        energy = parse_energy(out_name)
        status = "OK" if energy else "FAILED"
        results.append((ecut, energy))
        e_str = f"{energy:20.10f}" if energy else "N/A"
        print(f"{ecut:>8} {ecutrho:>8} {e_str}  {status}")

    return results


def plot_convergence(results: list[tuple[int, float | None]], save_path: str = "convergence.png"):
    """绘制 E vs ecutwfc 收敛曲线。"""
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("警告: 未安装 matplotlib，跳过绘图。")
        return

    ecuts = [r[0] for r in results if r[1] is not None]
    energies = [r[1] for r in results if r[1] is not None]

    if len(energies) < 2:
        print("数据点不足，无法绘图。")
        return

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    # 左图: 绝对能量
    ax1.plot(ecuts, energies, "o-", color="#2563eb", linewidth=2)
    ax1.set_xlabel("Ecutwfc (Ry)", fontsize=12)
    ax1.set_ylabel("Total Energy (Ry)", fontsize=12)
    ax1.set_title("GaAs: 总能量 vs 截断能", fontsize=13)
    ax1.grid(True, alpha=0.3)

    # 右图: 相对于最终值的差异 (meV)
    e_ref = energies[-1]
    delta_meV = [(e - e_ref) * 13605.693 for e in energies]  # Ry -> meV
    ax2.plot(ecuts, delta_meV, "s-", color="#dc2626", linewidth=2)
    ax2.axhline(y=1.0, color="gray", linestyle="--", label="1 meV 阈值")
    ax2.set_xlabel("Ecutwfc (Ry)", fontsize=12)
    ax2.set_ylabel("ΔE (meV/atom)", fontsize=12)
    ax2.set_title("GaAs: 能量收敛精度", fontsize=13)
    ax2.grid(True, alpha=0.3)
    ax2.legend()

    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    print(f"\n收敛曲线已保存至: {save_path}")


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="截断能收敛测试自动化")
    parser.add_argument("--dry-run", action="store_true", help="仅生成输入文件，不运行计算")
    parser.add_argument("--plot-only", type=str, help="仅从已有结果文件绘图")
    args = parser.parse_args()

    if args.plot_only:
        # 从文件读取结果并绘图（每行: ecutwfc  energy）
        results = []
        with open(args.plot_only) as f:
            for line in f:
                parts = line.split()
                if len(parts) == 2:
                    results.append((int(parts[0]), float(parts[1])))
        plot_convergence(results)
    else:
        results = run_conv_test(dry_run=args.dry_run)
        if not args.dry_run and results:
            plot_convergence(results)
            # 保存原始数据
            data_file = os.path.join(OUTPUT_DIR, "energies.dat")
            with open(data_file, "w") as f:
                for ecut, e in results:
                    if e is not None:
                        f.write(f"{ecut} {e:.10f}\n")
            print(f"能量数据已保存至: {data_file}")
