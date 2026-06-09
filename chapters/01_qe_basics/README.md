# 第一章：量子 ESPRESSO 入门与 DFT 基础

## 1. 什么是密度泛函理论（DFT）

**密度泛函理论**（Density Functional Theory, DFT）是现代计算材料科学和量子化学的基石。其核心思想是：用**电子密度** ρ(r) 代替多体波函数 Ψ(r₁, r₂, …, rₙ) 作为基本变量，从而将一个 3N 维问题简化为 3 维问题。

### 1.1 Hohenberg-Kohn 定理

DFT 的理论基础由 Hohenberg 和 Kohn 于 1964 年奠定，包含两个基本定理：

- **第一定理（存在性定理）**：外势 v_ext(r) 是基态电子密度 ρ₀(r) 的唯一泛函（相差一个常数）。换言之，体系的所有基态性质都由电子密度唯一确定。
- **第二定理（变分原理）**：对于给定的外势，真实基态电子密度使得总能量泛函 E[ρ] 取全局最小值。

这一定理证明了"密度即一切"，但并未给出能量泛函的具体形式。

### 1.2 Kohn-Sham 方程

1965 年，Kohn 和 Sham 提出了一个巧妙的方案：引入一组**无相互作用**的辅助粒子，使其密度与真实体系相同。总能量泛函写为：

$$E[\rho] = T_s[\rho] + E_H[\rho] + E_{\text{ext}}[\rho] + E_{xc}[\rho]$$

其中：
- **$T_s[\rho]$**：无相互作用动能
- **$E_H[\rho]$**：经典 Hartree（库仑）能
- **$E_{\text{ext}}[\rho]$**：外势能（电子-离子相互作用）
- **$E_{xc}[\rho]$**：**交换关联能**——所有多体效应都被封装在此

由此得到的 **Kohn-Sham 方程**为一组自洽的单粒子方程：

$$\left[-\tfrac{1}{2}\nabla^2 + v_{\text{eff}}(\mathbf{r})\right] \psi_i(\mathbf{r}) = \varepsilon_i \psi_i(\mathbf{r})$$

其中有效势 $v_{\text{eff}} = v_{\text{ext}} + v_H + v_{xc}$。通过自洽迭代求解这些方程，即可获得体系的基态能量和电子结构。

> **关键概念**：交换关联泛函 E_xc[ρ] 的精确形式未知，需要近似。常用近似包括 **LDA**（局域密度近似）和 **GGA**（广义梯度近似，如 PBE）。量子 ESPRESSO 支持多种泛函，通过 `input_dft` 参数选择。

---

## 2. 量子 ESPRESSO 软件简介

**量子 ESPRESSO**（opEn-Source Package for Research in Electronic Structure, Simulation, and Optimisation）是一个开源的、基于平面波赝势方法的第一性原理计算软件包。它是世界上使用最广泛的 DFT 代码之一。

### 2.1 主要程序

| 程序 | 可执行文件 | 功能说明 |
|------|-----------|---------|
| **pw.x** | `pw.x` | 平面波自洽场计算（SCF、NSCF、结构优化、分子动力学等），核心程序 |
| **ph.x** | `ph.x` | 密度泛函微扰理论（DFPT）计算声子、介电常数、Born 有效电荷等 |
| **pp.x** | `pp.x` | 后处理工具，提取电荷密度、势函数、波函数等并输出可绘图数据 |
| **cp.x** | `cp.x` | Car-Parrinello 分子动力学模拟 |
| **bands.x** | `bands.x` | 能带结构后处理，将 NSCF 计算结果转换为绘图数据 |
| **dos.x** | `dos.x` | 态密度（DOS）计算 |
| **projwfc.x** | `projwfc.x` | 投影到原子轨道的局域态密度（PDOS），分析轨道贡献 |
| **ld1.x** | `ld1.x` | 原子代码，生成和测试赝势 |
| **dynmat.x** | `dynmat.x` | 声子动力学矩阵对角化，计算声子频率和简正模式 |
| **hp.x** | `hp.x` | DFT+U 方法中 Hubbard U 参数的线性响应计算 |

### 2.2 QE 源代码目录结构（`~/qe-7.0/`）

| 目录 | 说明 |
|------|------|
| `PW/` | 平面波 DFT 计算核心代码（pw.x 的源代码） |
| `PHonon/` | 声子计算代码（ph.x、dynmat.x 等） |
| `PP/` | 后处理工具代码（pp.x、bands.x、dos.x、projwfc.x 等） |
| `CPV/` | Car-Parrinello 分子动力学代码（cp.x） |
| `Modules/` | 共享模块，包含通用数据结构、I/O、并行工具等 |
| `FFTXlib/` | FFT 库，负责实空间与倒空间的快速傅里叶变换 |
| `LAXlib/` | 线性代数库，矩阵对角化等 |
| `XClib/` | 交换关联泛函库 |
| `KS_Solvers/` | Kohn-Sham 方程求解器（Davidson、CG 等算法） |
| `atomic/` | 原子代码（ld1.x），用于生成赝势 |
| `NEB/` | 过渡态搜索（Nudged Elastic Band 方法） |
| `EPW/` | 电子-声子耦合与输运性质计算 |
| `HP/` | Hubbard 参数计算 |
| `TDDFPT/` | 含时密度泛函理论（光学性质） |
| `pseudo/` | 内置赝势文件库 |
| `GUI/` | 图形用户界面相关 |
| `Doc/` | 文档与示例 |
| `install/` | 编译安装脚本 |

---

## 3. 输入文件结构详解

量子 ESPRESSO 的输入文件（以 pw.x 为例）由 **Namelist** 和 **Card** 两部分组成，采用 Fortran 自由格式。

### 3.1 基本结构

```
&CONTROL
  ...
/
&SYSTEM
  ...
/
&ELECTRONS
  ...
/

ATOMIC_SPECIES
...
ATOMIC_POSITIONS
...
K_POINTS
...
```

### 3.2 Namelist 详解

#### &CONTROL — 控制参数

控制计算类型、输入输出行为等。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `calculation` | 字符串 | `'scf'` | 计算类型：`'scf'`（自洽场）、`'nscf'`（非自洽）、`'bands'`（能带）、`'relax'`（离子弛豫）、`'vc-relax'`（可变晶格弛豫）、`'md'`（分子动力学） |
| `prefix` | 字符串 | `'pwscf'` | 输出文件前缀，所有输出文件以此前缀命名 |
| `outdir` | 字符串 | `'./'` | 临时文件（波函数、电荷密度等）存放目录 |
| `pseudo_dir` | 字符串 | `'./'` | 赝势文件搜索目录 |
| `verbosity` | 字符串 | `'default'` | 输出详细程度：`'low'`、`'default'`、`'high'` |
| `tprnfor` | 逻辑 | `.FALSE.` | 是否打印原子受力 |
| `tstress` | 逻辑 | `.FALSE.` | 是否计算并打印应力张量 |
| `disk_io` | 字符串 | `'default'` | 磁盘 I/O 级别：`'none'`、`'low'`、`'default'`、`'high'` |
| `restart_mode` | 字符串 | `'from_scratch'` | 重启模式：`'from_scratch'`（从头算）、`'restart'`（从上次中断处继续） |
| `wf_collect` | 逻辑 | `.FALSE.` | 是否将所有 k 点的波函数收集到一个文件中 |
| `nstep` | 整数 | `1` | SCF 迭代最大步数（relax/md 时为离子步数） |
| `etot_conv_thr` | 实数 | `1.0e-4` | 总能量收敛阈值（Rydberg） |
| `forc_conv_thr` | 实数 | `1.0e-3` | 力收敛阈值（Rydberg/Bohr），用于 relax |
| `dt` | 实数 | `20.D0` | CP 分子动力学时间步长（a.u.） |

#### &SYSTEM — 体系参数

定义晶体结构、电子数、截断能等物理参数。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `ibrav` | 整数 | `0` | Bravais 格子类型编号（0 表示手动指定 `CELL_PARAMETERS`；1=fcc, 2=bcc, 3=sc, 4=hex, 等） |
| `nat` | 整数 | — | **必须指定**：体系中原子总数 |
| `ntyp` | 整数 | — | **必须指定**：不同原子种类数 |
| `ecutwfc` | 实数 | — | **必须指定**：波函数平面波截断能（单位：Ry） |
| `ecutrho` | 实数 | `4*ecutwfc` | 电荷密度截断能（Ry），对于超软赝势/PAW 需手动增大 |
| `a` / `b` / `c` | 实数 | — | 晶格参数（单位：Bohr，可配合 `celldm(1)` 等） |
| `celldm(i)` | 实数 | — | 晶格参数的无量纲形式，`celldm(1)` = a（Bohr） |
| `occupations` | 字符串 | `'fixed'` | 占据数方案：`'fixed'`（绝缘体）、`'smearing'`（金属） |
| `smearing` | 字符串 | `'gaussian'` | 展宽方法：`'gaussian'`、`'methfessel-paxton'`、`'marzari-vanderbilt'`、`'fermi-dirac'` |
| `degauss` | 实数 | `0.01` | 展宽宽度（Ry），金属体系通常 0.01–0.05 |
| `input_dft` | 字符串 | (自动) | 指定交换关联泛函，如 `'PBE'`、`'LDA'`、`'BLYP'` 等 |
| `nspin` | 整数 | `1` | 自旋极化：1=非极化，2=共线自旋极化 |
| `nbnd` | 整数 | (自动) | 能带数，默认为价电子数/2 + 额外空带 |
| `tot_charge` | 实数 | `0.0` | 体系总电荷（正值=失去电子） |
| `lda_plus_u` | 逻辑 | `.FALSE.` | 是否启用 DFT+U |
| `lda_plus_u_kind` | 整数 | `0` | DFT+U 类型：0=简化旋转不变，1=完整旋转不变 |
| `Hubbard_U(i)` | 实数 | `0.D0` | 第 i 种原子的 U 值（eV） |
| `nosym` | 逻辑 | `.FALSE.` | 是否禁用对称性 |
| `nosym_evc` | 逻辑 | `.FALSE.` | 是否禁用对称性（同时影响电荷密度和波函数） |
| `london` | 逻辑 | `.FALSE.` | 是否启用 DFT-D2 色散修正 |
| `vdw_corr` | 字符串 | `'none'` | 范德华修正：`'DFT-D'`、`'TS'`、`'XDM'` 等 |
| `ecfixed` | 实数 | — | 固定截断能（用于 `ecutrho` 控制） |
| `qcutz` | 实数 | — | 增压能量（Gaussian 固定） |
| `q2sigma` | 实数 | — | 高斯展宽宽度 |

#### &ELECTRONS — 电子自洽参数

控制电子步迭代的收敛行为。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `electron_maxstep` | 整数 | `100` | 电子自洽迭代最大步数 |
| `conv_thr` | 实数 | `1.0e-6` | 电子步能量收敛阈值（Rydberg） |
| `mixing_mode` | 字符串 | `'plain'` | 电荷密度混合方式：`'plain'`、`'TF'`（Thomas-Fermi）、`'local-TF'` |
| `mixing_beta` | 实数 | `0.7` | 密度混合参数 β（0 < β ≤ 1），较大值收敛快但可能不稳定 |
| `mixing_ndim` | 整数 | `8` | 密度混合的历史向量数 |
| `diagonalization` | 字符串 | `'david'` | 对角化算法：`'david'`（Davidson）、`'cg'`（共轭梯度） |
| `diago_thr_init` | 实数 | — | 初始对角化阈值 |
| `electron_maxstep` | 整数 | `100` | SCF 迭代最大步数 |
| `startingwfc` | 字符串 | `'atomic+random'` | 初始波函数：`'atomic'`、`'atomic+random'`、`'random'`、`'file'` |
| `startingpot` | 字符串 | `'atomic'` | 初始势：`'atomic'`、`'file'` |
| `scf_must_converge` | 逻辑 | `.TRUE.` | SCF 不收敛时是否停止计算 |
| `ortho_para` | 整数 | — | 正交化并行参数 |

### 3.3 Card 详解

Card 部分不使用 `&`/`/` 界定，以关键词开头，后跟数据行。

#### ATOMIC_SPECIES — 原子种类

定义每种原子的标签、质量和赝势文件名。

```
ATOMIC_SPECIES
  Si  28.086  Si.pbe-n-rrkjus_psl.1.0.0.UPF
```

格式：`标签  质量(amu)  赝势文件名`

- **质量**：用于分子动力学和声子计算中的离子运动；SCF 中影响不大但不可省略
- **赝势文件**：路径相对于 `pseudo_dir`；常见格式为 `.UPF`（Unified Pseudopotential Format）

#### ATOMIC_POSITIONS — 原子坐标

```
ATOMIC_POSITIONS {crystal}
  Si   0.00  0.00  0.00
  Si   0.25  0.25  0.25
```

坐标选项：

| 单位 | 关键词 | 说明 |
|------|--------|------|
| 晶体坐标 | `crystal` | 以晶格矢量为基，值域 [0, 1)，**最常用** |
| 笛卡尔坐标（alat） | `alat` 或 省略 | 以 `celldm(1)` 或 `a` 为单位 |
| 笛卡尔坐标（Bohr） | `bohr` | 以 Bohr 原子单位 |
| 笛卡尔坐标（Angstrom） | `angstrom` | 以埃为单位 |

可以给单个原子添加约束（用于结构优化）：

```
ATOMIC_POSITIONS {crystal}
  Si   0.00  0.00  0.00  0  0  0    ! 固定此原子
  Si   0.25  0.25  0.25              ! 允许自由移动
```

#### K_POINTS — k 点采样

定义布里渊区中的 k 点网格或路径。

**自动网格**（用于 SCF/NSCF）：
```
K_POINTS {automatic}
  4  4  4  0  0  0
```
格式：`nk1 nk2 nk3 sk1 sk2 sk3`，其中 `sk` 为位移（0=Gamma 中心，1=Monkhorst-Pack）。

**手动列表**（用于能带）：
```
K_POINTS {crystal_b}
  5
  0.000  0.000  0.000  20   ! Γ
  0.500  0.500  0.000  20   ! X
  0.375  0.375  0.750  20   ! K
  0.000  0.000  0.000  20   ! Γ
  0.500  0.500  0.500  20   ! L
```

#### CELL_PARAMETERS — 晶格矢量

当 `ibrav = 0` 时必须提供：

```
CELL_PARAMETERS {angstrom}
  5.43  0.00  0.00
  0.00  5.43  0.00
  0.00  0.00  5.43
```

---

## 4. 单位系统

量子 ESPRESSO 使用 **Rydberg 原子单位制**（Rydberg Atomic Units），这是初学者最容易混淆的地方之一。

| 物理量 | 单位 | 与 SI 的换算 |
|--------|------|-------------|
| 能量 | Ry（Rydberg） | 1 Ry = 13.605693 eV |
| 长度 | Bohr（a.u.） | 1 Bohr = 0.529177 Å |
| 力 | Ry/Bohr | 1 Ry/Bohr ≈ 25.711 eV/Å |
| 压力 | kbar | 1 kbar = 0.1 GPa |
| 磁场 | Tesla | — |
| 温度 | Kelvin | — |

> **注意**：虽然输入中可以用 `angstrom` 指定原子坐标和晶格参数，但输出文件中的能量始终以 **Rydberg** 为单位。如果需要转换为 eV，乘以 13.6057。

---

## 5. 输出文件解读

运行 `pw.x` 后，输出包含以下几个部分：

### 5.1 标准输出（stdout）

通常重定向到 `.out` 文件，包含完整的计算日志：

```
     Program PWSCF v.7.0 starts on ...
     ... reading namelist &CONTROL
     ... reading namelist &SYSTEM
     ...
     number of atoms/cell      =            2
     number of atomic types    =            1
     ...
     kinetic-energy cutoff     =      30.0000  Ry
     charge density cutoff     =     240.0000  Ry
     ...
     Self-Consistent Calculation
     iteration #  1     ecut=  30.00 Ry     beta= 0.70
     ...
     convergence has been achieved in   8 iterations
```

### 5.2 关键输出信息

- **总能量**：`!    total energy              =  -xxx.xxxx xxxx Ry`
- **费米能**：`the Fermi energy is    x.xxxx ev`
- **原子受力**：`Total force =     x.xxxx`（relax 时重要）
- **应力张量**：`total   stress  (Ry/bohr**3)`（vc-relax 时重要）

### 5.3 临时文件（`outdir/prefix.*`）

| 文件 | 说明 |
|------|------|
| `prefix.save/` | 保存目录，含电荷密度、波函数等 |
| `prefix.wfc*` | 波函数文件 |
| `prefix.xml` | 结构与计算参数的 XML 文件 |
| `prefix.EXIT` | 存在此文件则程序优雅退出 |

---

## 6. 关键概念

- **自洽场（SCF）**：Kohn-Sham 方程必须自洽求解——由猜测的电荷密度出发，构造有效势，求解 KS 方程得到波函数，再由波函数计算新密度，如此迭代直到收敛。收敛判据通常为总能量变化小于 `conv_thr`。
- **平面波基组**：QE 用平面波展开波函数。`ecutwfc` 控制基组大小——截断能越高，基组越大，结果越精确但计算越慢。需要进行 **截断能收敛测试**。
- **赝势（Pseudopotential）**：用赝势代替全电子势来处理内层电子，大幅减少计算量。QE 支持 **NCPP**（范数守恒赝势）、**USPP**（超软赝势）和 **PAW**（投影缀加波）。超软赝势需要更大的 `ecutrho`。
- **k 点采样**：对于周期性体系，需要在布里渊区中离散采样。k 点越多越精确，但计算量线性增长。需要进行 **k 点收敛测试**。
- **Rydberg 原子单位**：QE 内部使用 Rydberg 单位（1 Ry = 13.6057 eV），初学者务必注意与 eV 的换算。
- **对称性**：QE 自动检测晶体空间群对称性以减少 k 点数和计算量。使用 `nosym = .TRUE.` 可禁用（调试时有用）。
- **交换关联泛函**：DFT 中唯一需要近似的部分。LDA 适用于简单金属和半导体；PBE（GGA）是通用性最广的选择；对于弱相互作用需添加色散修正（DFT-D3, MBD 等）。

---

## 7. 动手实践：硅晶体的 SCF 计算

请参考本章的输入文件示例和运行脚本：

- **输入文件**：[`inputs/si_scf.in`](inputs/si_scf.in) — 完整的 Si SCF 计算输入，带详细中文注释
- **运行脚本**：[`scripts/run.sh`](scripts/run.sh) — 使用 pw.x 运行计算的 bash 脚本

---

## 参考资料

- [Quantum ESPRESSO 官方文档](https://www.quantum-espresso.org/Doc/INPUT_PW.html)
- P. Giannozzi et al., *J. Phys.: Condens. Matter* **21**, 395502 (2009)
- R. M. Martin, *Electronic Structure: Basic Theory and Practical Methods*, Cambridge University Press
- D. Sholl & J. Steckel, *Density Functional Theory: A Practical Introduction*, Wiley
