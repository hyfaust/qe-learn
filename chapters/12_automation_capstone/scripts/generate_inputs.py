#!/usr/bin/env python3
"""
generate_inputs.py — 使用字符串模板自动生成 Quantum ESPRESSO 输入文件

用法:
    python generate_inputs.py
    生成 GaAs 在不同 ecutwfc 下的 SCF 输入文件，用于收敛性测试。

依赖: 仅 Python 标准库 (string.Template)
"""
import os
from string import Template

# ---------------------------------------------------------------------------
# 1. 模板定义：用 ${变量名} 作为占位符
# ---------------------------------------------------------------------------
SCF_TEMPLATE = Template("""\
&CONTROL
  calculation  = 'scf'
  prefix       = '${prefix}'
  outdir       = './tmp'
  pseudo_dir   = '${pseudo_dir}'
  restart_mode = 'from_scratch'
/

&SYSTEM
  ibrav     = ${ibrav}
  celldm(1) = ${celldm1}
  nat       = ${nat}
  ntyp      = ${ntyp}
  ecutwfc   = ${ecutwfc}
  ecutrho   = ${ecutrho}
  nbnd      = ${nbnd}
/

&ELECTRONS
  conv_thr    = ${conv_thr}
  mixing_beta = ${mixing_beta}
  electron_maxstep = 200
/

ATOMIC_SPECIES
${species}

ATOMIC_POSITIONS crystal
${positions}

K_POINTS automatic
${kpoints}
""")

# ---------------------------------------------------------------------------
# 2. 材料参数
# ---------------------------------------------------------------------------
GAAS_PARAMS = {
    "prefix": "gaas",
    "pseudo_dir": "/home/faust/pseudo",
    "ibrav": 2,
    "celldm1": 10.6917,
    "nat": 2,
    "ntyp": 2,
    "nbnd": 20,
    "conv_thr": "1.0d-8",
    "mixing_beta": 0.3,
    "species": (
        "Ga  69.723  Ga.pbe-dn-kjpaw_psl.1.0.0.UPF\n"
        "As  74.922  As.pbe-n-kjpaw_psl.1.0.0.UPF"
    ),
    "positions": (
        "Ga  0.00  0.00  0.00\n"
        "As  0.25  0.25  0.25"
    ),
    "kpoints": "8 8 8 0 0 0",
}


def generate_scf_input(ecutwfc: float, ecutrho: float, output_dir: str = "inputs_auto") -> str:
    """为给定的截断能生成一个 SCF 输入文件。"""
    params = GAAS_PARAMS.copy()
    params["ecutwfc"] = ecutwfc
    params["ecutrho"] = ecutrho

    content = SCF_TEMPLATE.substitute(params)

    os.makedirs(output_dir, exist_ok=True)
    filename = os.path.join(output_dir, f"gaas_scf_ecut{int(ecutwfc)}.in")
    with open(filename, "w") as f:
        f.write(content)

    print(f"  已生成: {filename}")
    return filename


# ---------------------------------------------------------------------------
# 3. 主程序：批量生成不同截断能的输入文件
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    print("=" * 50)
    print("  QE 输入文件生成器 (模板化)")
    print("=" * 50)

    # 收敛测试用的截断能列表 (Ry)
    ecutwfc_list = [20, 30, 40, 50, 60, 70]

    # ecu trho 通常设为 ecutwfc 的 8-12 倍 (对于 PAW 赝势)
    ratio = 8

    for ecutwfc in ecutwfc_list:
        generate_scf_input(ecutwfc, ecutwfc * ratio)

    print(f"\n共生成 {len(ecutwfc_list)} 个输入文件。")
    print("可使用以下命令运行收敛测试:")
    print("  mpirun -np 4 pw.x -in gaas_scf_ecut20.in > gaas_scf_ecut20.out")
