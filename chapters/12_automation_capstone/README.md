# 第十二章：综合实战与自动化

## 12.1 综合项目：从零完成 GaAs 的完整表征

本章以 **GaAs（砷化镓）** 为例，演示从结构优化到声子计算的完整工作流。GaAs 是典型的 III-V 族直接带隙半导体，闪锌矿结构（空间群 F-43m），广泛用于光电子器件。

### 12.1.1 工作流程总览

```
结构优化 → 收敛测试 → SCF → 能带+DOS → 声子 → 热力学性质
(relax)   (ecutwfc)  (scf)  (bands/dos)  (ph)   (thermodynamics)
```

| 步骤 | 计算类型 | 关键输出 | 参考文件 |
|------|---------|---------|---------|
| 1 | `relax` | 优化后的晶格常数、原子位置 | [`gaas_relax.in`](inputs/gaas_relax.in) |
| 2 | `scf`（多次） | E vs ecutwfc 收敛曲线 | 见脚本 |
| 3 | `scf` | 基态总能量、电荷密度 | [`gaas_scf.in`](inputs/gaas_scf.in) |
| 4 | `bands` | 能带结构、带隙 | [`gaas_bands.in`](inputs/gaas_bands.in) |
| 5 | `ph.x` | 声子频率、热力学量 | 见脚本 |

### 12.1.2 关键参数选择

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| **ecutwfc** | 50 Ry | 收敛测试后确定 |
| **ecutrho** | 400 Ry | PAW 赝势通常取 ecutwfc 的 8 倍 |
| **k 点** | 8x8x8 | SCF/DOS 计算 |
| **conv_thr** | 1.0d-8 | 电子收敛阈值 |
| **smearing** | gaussian, 0.01 | GaAs 为半导体，退化很小 |

---

## 12.2 Python 自动化 QE 计算

手动编辑大量输入文件容易出错且效率低下。下面介绍如何用 Python 实现自动化。

### 12.2.1 生成输入文件（字符串模板）

使用 Python 的 `string.Template` 将参数从输入文件中分离：

```python
from string import Template

SCF_TEMPLATE = Template("""\
&CONTROL
  calculation = 'scf'
  prefix = '${prefix}'
  outdir = './tmp'
  pseudo_dir = '${pseudo_dir}'
/
&SYSTEM
  ibrav = ${ibrav}
  celldm(1) = ${celldm1}
  ecutwfc = ${ecutwfc}
  ...
""")
# 用法:
content = SCF_TEMPLATE.substitute(prefix="gaas", ecutwfc=50, ...)
```

完整实现见 [`scripts/generate_inputs.py`](scripts/generate_inputs.py)，可批量生成不同截断能的输入文件。

### 12.2.2 解析输出文件

pw.x 输出是结构化文本，用**正则表达式**提取关键物理量：

```python
import re

def parse_energy(output: str) -> float:
    """从 pw.x 输出中提取总能量 (Ry)。"""
    m = re.search(r"!\s+total energy\s+=\s+([-\d.Ee+]+)\s+Ry", output)
    return float(m.group(1))
```

完整解析器见 [`scripts/parse_output.py`](scripts/parse_output.py)，支持提取：
- **总能量**（Ry 和 eV）
- **原子受力**（force）
- **应力/压力**（stress）
- **费米能**
- **收敛状态**

### 12.2.3 自动化收敛测试

```python
# 核心思路：循环修改参数 → 运行 → 提取能量 → 绘图
for ecut in [20, 30, 40, 50, 60, 70]:
    write_input(ecutwfc=ecut)
    run_pw("scf")
    energy[ecut] = parse_energy()
```

运行方式：

```bash
python scripts/convergence_test.py           # 完整运行
python scripts/convergence_test.py --dry-run # 仅生成输入文件
```

### 12.2.4 数据可视化（matplotlib）

收敛测试脚本自动绘制两种图：

- **绝对能量曲线**：E (Ry) vs ecutwfc，观察能量是否趋于平稳
- **相对精度曲线**：ΔE (meV) vs ecutwfc，判断是否达到所需精度

能带图绘制需配合 QE 的 `bands.x` 后处理工具提取数据，再用 matplotlib 绑定。

---

## 12.3 综合工作流脚本

[`scripts/run_workflow.sh`](scripts/run_workflow.sh) 将整个流程串联为一个自动化脚本：

```bash
# 设置 MPI 进程数并运行
NP=8 bash scripts/run_workflow.sh
```

脚本按顺序执行：结构优化 → 收敛测试 → SCF → 能带 → 声子，每步自动创建输出目录并记录日志。

---

## 12.4 高通量计算简介

**高通量计算（High-Throughput Computing）** 是对大量材料进行系统化自动计算的范式，核心思想：

1. **标准化输入**：统一赝势、k 点密度、截断能等参数
2. **批量生成**：脚本化生成数百至数千个计算任务
3. **自动提交**：与作业调度系统（SLURM、PBS）集成
4. **结果收集**：自动解析并存入数据库
5. **数据分析**：统计筛选、机器学习建模

典型应用场景：筛选带隙合适的半导体材料、寻找高迁移率载流子材料、合金相图计算等。

---

## 12.5 ASE (Atomic Simulation Environment)

**ASE** 是 Python 编写的原子模拟工具包，提供：

- **晶体结构构建**：`ase.build.bulk("GaAs", "zincblende", a=5.65)`
- **计算器接口**：将 QE 包装为 `Espresso` 计算器
- **结构优化**：内置 BFGS、FIRE 等优化器
- **分析工具**：径向分布函数、配位数等

```python
from ase.build import bulk
from ase.calculators.espresso import Espresso

atoms = bulk("GaAs", "zincblende", a=5.65)
calc = Espresso(pseudopotentials={"Ga": "Ga.pbe-dn.UPF", "As": "As.pbe-n.UPF"},
                ecutwfc=50, kpts=(8, 8, 8))
atoms.calc = calc
energy = atoms.get_potential_energy()
```

ASE 的优势在于将 QE 计算无缝融入 Python 科学计算生态。

---

## 12.6 AiiDA 工作流引擎

**AiiDA**（Automated Interactive Infrastructure and Database for Computational Science）是面向计算材料学的**工作流管理框架**，核心功能：

- **可重复性**：自动记录完整计算图（provenance graph），从输入到输出全链路可追溯
- **工作流编程**：用 Python 定义复杂工作流，支持条件分支、循环、并行
- **任务调度**：自动提交到 HPC 集群，失败自动重试
- **数据查询**：用 QueryBuilder 在数据库中搜索计算结果

```python
from aiida import load_profile
load_profile()
from aiida.engine import run
from aiida_quantumespresso.workflows.pw.relax import PwRelaxWorkChain
# 定义并运行结构优化工作流
```

AiiDA 适合需要高可重复性和大规模自动化的研究项目。

---

## 12.7 最佳实践与常见陷阱

### 最佳实践

1. **先收敛再生产**：永远先做 ecutwfc 和 k 点收敛测试
2. **检查伪势**：确认赝势覆盖所需电子态（特别是 d 电子）
3. **逐步验证**：每一步检查输出的合理性，不要盲目提交后续计算
4. **版本控制**：用 Git 管理输入文件和脚本
5. **记录日志**：每个计算保存输入、输出和运行脚本

### 常见陷阱

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 带隙偏小 | LDA/GGA 的系统误差 | 使用 HSE06 杂化泛函 |
| 声子出现虚频 | 结构未充分优化 | 检查力和应力收敛 |
| 计算不收敛 | 初始磁矩/电子数不对 | 调整 `mixing_beta`，检查 `nbnd` |
| 内存不足 | ecutrho 过大 | 降低 ecutrho 比值或使用集群 |
| k 点不足 | 金属体系需要更多 k 点 | 增加 k 点密度或使用展宽方法 |

---

## 12.8 学习资源推荐

| 资源 | 说明 |
|------|------|
| [QE 官方文档](https://www.quantum-espresso.org/Doc/INPUT_PW.html) | pw.x 完整输入参数说明 |
| [QE Wiki](https://www.quantum-espresso.org/wiki/) | 教程和 FAQ |
| [ASE 文档](https://wiki.fysik.dtu.dk/ase/) | Python 原子模拟工具 |
| [AiiDA 文档](https://aiida.readthedocs.io/) | 工作流引擎教程 |
| [Materials Cloud](https://www.materialscloud.org/) | 计算材料数据和工具 |
| [Materials Project](https://materialsproject.org/) | 高通量材料数据库 |

---

> **本章配套文件：**
> - `inputs/` — GaAs 结构优化、SCF、能带输入文件
> - [`scripts/generate_inputs.py`](scripts/generate_inputs.py) — 输入文件生成器
> - [`scripts/parse_output.py`](scripts/parse_output.py) — 输出解析工具
> - [`scripts/convergence_test.py`](scripts/convergence_test.py) — 收敛测试自动化
> - [`scripts/run_workflow.sh`](scripts/run_workflow.sh) — 完整工作流脚本
