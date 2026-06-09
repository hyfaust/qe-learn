#!/usr/bin/env python3
"""
parse_output.py — 解析 Quantum ESPRESSO pw.x 输出文件，提取关键物理量

用法:
    python parse_output.py <输出文件>
    python parse_output.py gaas_relax.out

提取内容:
    - total energy (总能量)
    - forces (原子受力)
    - pressure (压力/应力)
    - Fermi energy (费米能)
    - convergence information (收敛信息)

依赖: 仅 Python 标准库 (re)
"""
import re
import sys


def parse_pw_output(filename: str) -> dict:
    """解析 pw.x 输出文件，返回包含物理量的字典。"""
    result = {
        "file": filename,
        "total_energy_Ry": None,
        "total_energy_eV": None,
        "fermi_energy_eV": None,
        "forces": [],
        "pressure_GPa": None,
        "converged": False,
        "n_scf_steps": 0,
        "wall_time_s": None,
    }

    with open(filename, "r") as f:
        content = f.read()

    # --- 总能量 ---
    m = re.search(r"!\s+total energy\s+=\s+([-\d.]+[eE]?[-+]?\d*)\s+Ry", content)
    if m:
        energy_ry = float(m.group(1))
        result["total_energy_Ry"] = energy_ry
        result["total_energy_eV"] = energy_ry * 13.605693  # Ry -> eV

    # --- 费米能 ---
    m = re.search(r"the Fermi energy is\s+([-\d.]+[eE]?[-+]?\d*)\s+ev", content)
    if m:
        result["fermi_energy_eV"] = float(m.group(1))

    # --- 原子受力 ---
    force_pattern = re.compile(
        r"atom\s+\d+\s+type\s+\d+\s+force\s*=\s*"
        r"([-\d.Ee+]+)\s+([-\d.Ee+]+)\s+([-\d.Ee+]+)"
    )
    for fm in force_pattern.finditer(content):
        result["forces"].append([float(fm.group(i)) for i in (1, 2, 3)])

    # --- 压力 / 应力 ---
    m = re.search(r"total\s+stress\s*\(Ry/bohr\*\*3\)\s+.*?P=\s+([-\d.]+)", content, re.DOTALL)
    if m:
        # P (kbar) -> GPa: 1 kbar = 0.1 GPa
        result["pressure_GPa"] = float(m.group(1)) * 0.1

    # --- SCF 收敛 ---
    if "convergence has been achieved" in content.lower() or "JOB DONE" in content:
        result["converged"] = True

    scf_steps = re.findall(r"convergence has been achieved", content)
    result["n_scf_steps"] = len(scf_steps)

    # --- 计算时间 ---
    m = re.search(r"total wall time\s*:\s*(\S+)", content)
    if m:
        result["wall_time_s"] = m.group(1)

    return result


def print_summary(info: dict) -> None:
    """以格式化表格的形式打印解析结果。"""
    print("=" * 55)
    print(f"  文件: {info['file']}")
    print("=" * 55)
    print(f"  收敛状态      : {'是' if info['converged'] else '否'}")
    if info["total_energy_Ry"] is not None:
        print(f"  总能量 (Ry)   : {info['total_energy_Ry']:>18.10f}")
        print(f"  总能量 (eV)   : {info['total_energy_eV']:>18.6f}")
    if info["fermi_energy_eV"] is not None:
        print(f"  费米能 (eV)   : {info['fermi_energy_eV']:>18.6f}")
    if info["pressure_GPa"] is not None:
        print(f"  压力 (GPa)    : {info['pressure_GPa']:>18.4f}")
    if info["forces"]:
        print(f"  原子力数      : {len(info['forces'])}")
    if info["wall_time_s"]:
        print(f"  计算时间      : {info['wall_time_s']}")
    print("=" * 55)


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python parse_output.py <pw.x输出文件> [更多输出文件...]")
        sys.exit(1)

    for fname in sys.argv[1:]:
        try:
            data = parse_pw_output(fname)
            print_summary(data)
        except FileNotFoundError:
            print(f"错误: 文件 {fname} 不存在。")
        except Exception as e:
            print(f"解析 {fname} 时出错: {e}")
