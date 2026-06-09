# 第六章：结构优化与力学性质

## 概述

在实际计算中，实验测定的晶体结构往往不是 DFT 能量面的精确极小值。**结构优化**（Geometry Optimization / Relaxation）通过迭代调整原子位置和（可选的）晶格参数，使系统达到力学平衡状态——即所有原子受力趋近于零，应力张量趋近于零。这是几乎所有后续计算（声子谱、能带、分子动力学等）的前置步骤。

---

## 6.1 Hellmann-Feynman 力定理

结构优化的物理基础是 **Hellmann-Feynman 定理**：一旦电子基态通过自洽场（SCF）求解完成，原子核所受的力只需对电子密度的静电势求导即可获得：

$$
\mathbf{F}_I = -\frac{\partial E}{\partial \mathbf{R}_I} = -Z_I \nabla_{\mathbf{R}_I} \int \frac{\rho(\mathbf{r})}{|\mathbf{r} - \mathbf{R}_I|} d\mathbf{r} + \text{其他贡献}
$$

其中 $\mathbf{R}_I$ 为第 $I$ 个原子的坐标，$Z_I$ 为其有效电荷。在平面波基组中，"其他贡献"还包括非局域赝势项、离子-离子库仑排斥项、以及交换关联势的贡献。

Quantum ESPRESSO 在每次 SCF 收敛后自动计算并输出 **force on each atom**（单位：Ry/Bohr）。当所有原子上的力都足够小时，结构即达到力学平衡。

---

## 6.2 应力张量

对于周期性体系，除了原子力之外，晶格本身的形变也对应一个热力学驱动力——**应力张量** $\sigma_{\alpha\beta}$（stress tensor）。它是一个 $3 \times 3$ 的对称张量，描述单位面积上沿 $\beta$ 方向的面元所受的 $\alpha$ 方向的力。

在 QE 中，应力以 **kbar** 为单位输出，且必须在输入中设置 `tstress = .true.` 才会计算。**变晶格优化**（vc-relax）正是通过最小化应力张量来同时优化晶格参数和原子位置。

---

## 6.3 结构优化类型

QE 的 `pw.x` 支持两种结构优化模式，通过 `calculation` 参数指定：

| 模式 | `calculation` 值 | 优化对象 | 适用场景 |
|------|------------------|----------|----------|
| **固定晶格优化** | `'relax'` | 仅原子位置 | 分子、表面吸附、已知晶格常数的晶体 |
| **变晶格优化** | `'vc-relax'` | 原子位置 + 晶格参数 | 未知晶格常数、高压/低压研究、弹性常数 |

### 6.3.1 relax（固定晶格）

- 晶胞形状和体积保持不变
- 只优化 `ATOMIC_POSITIONS` 中的原子坐标
- 每步 SCF 后计算 Hellmann-Feynman 力，通过 BFGS 更新原子位置
- 收敛判据：所有原子受力 < `forc_conv_thr`

### 6.3.2 vc-relax（变晶格）

- 同时优化原子位置和晶格参数（`CELL_PARAMETERS`）
- 需要计算应力张量（自动开启 `tstress`）
- 每步包含一个 SCF 计算 + 力/应力的双重优化
- 可通过 `&CELL` 中的 `press` 参数设定外部压力（等压优化）
- 收敛判据需同时满足力和能量的阈值

---

## 6.4 BFGS 优化算法

QE 的默认优化算法是 **BFGS**（Broyden-Fletcher-Goldfarb-Shanno），一种拟牛顿方法：

1. 从当前构型出发，计算力（梯度）和 Hessian 矩阵的近似
2. 沿搜索方向 $\mathbf{d} = -\mathbf{H}^{-1} \cdot \mathbf{g}$（$\mathbf{H}$ 为近似 Hessian，$\mathbf{g}$ 为力向量）进行线搜索
3. 根据新旧梯度的差更新 Hessian 近似
4. 重复直到收敛

BFGS 的优点是**超线性收敛**，对初始 Hessian 不敏感。QE 在首次迭代中使用一个经验初始 Hessian，随后逐步更新。

**关键参数**：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `ion_dynamics` | `'bfgs'` | 离子优化算法。可选 `'bfgs'`、`'damp'`、`'fire'` |
| `trust_radius_max` | 0.8 Bohr | 线搜索的最大步长 |
| `trust_radius_min` | 1.0d-4 Bohr | 线搜索的最小步长 |
| `trust_radius_ini` | 0.5 Bohr | 初始信任半径 |
| `w_1` | 0.01 | 线搜索中的 Wolfe 条件参数 |
| `w_2` | 0.5 | 线搜索中的 Wolfe 条件参数 |
| `bfgs_ndim` | 1 | BFGS 更新所用的历史步数（>1 为 L-BFGS） |
| `upscale` | 10.0 | 能量不再下降时，将电子收敛阈值放大的倍数 |

> **提示**：对于较难收敛的体系，可将 `bfgs_ndim` 设为 5~7 以使用有限内存 BFGS，或切换为 `ion_dynamics = 'fire'`（FIRE 算法）。

---

## 6.5 &CELL namelist 参数详解

`&CELL` namelist 仅在 `calculation = 'vc-relax'` 时生效，控制晶格优化行为：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `cell_dynamics` | `'none'` | 晶格优化算法。常用 `'bfgs'`（推荐）或 `'damp-w'`（Wentzcovitch 阻尼动力学） |
| `press` | 0.0 kbar | 目标外部压力 |
| `wmass` | 自动计算 | 晶格自由度的"虚拟质量"。阻尼动力学中控制收敛速度 |
| `cell_factor` | 1.2 | FFT 网格安全因子。晶格变化较大时需增大此值（如 1.5~2.0） |
| `press_conv_thr` | 0.5 kbar | 压力收敛阈值 |

> **注意**：`cell_dynamics = 'bfgs'` 是 QE 7.0 中 vc-relax 的推荐选项，比旧版的 `'damp-w'` 收敛更快更稳定。

---

## 6.6 收敛判据

结构优化的收敛需要同时满足以下条件：

| 参数 | 默认值 | 位置 | 说明 |
|------|--------|------|------|
| `forc_conv_thr` | 1.0d-4 Ry/Bohr | `&CONTROL` | 最大残余力的阈值。越小精度越高，但步数越多 |
| `etot_conv_thr` | 1.0d-4 Ry | `&CONTROL` | 相邻两步能量变化的阈值 |
| `nstep` | 50 | `&CONTROL`（relax）/ `&IONS`（vc-relax）| 最大离子步数 |

**典型取值建议**：

- **常规结构优化**：`forc_conv_thr = 1.0d-4`，`etot_conv_thr = 1.0d-5`
- **高精度**（如声子前的优化）：`forc_conv_thr = 1.0d-5`，`etot_conv_thr = 1.0d-6`
- **粗略搜索**：`forc_conv_thr = 1.0d-3`，`etot_conv_thr = 1.0d-4`

> **重要**：`etot_conv_thr` 是相邻两步之间的能量差，不是绝对能量。它与电子自洽的 `conv_thr` 是不同的概念。

---

## 6.7 ibrav 与 CELL_PARAMETERS 的关系

`ibrav` 是 QE 中定义晶格类型的快捷方式：

| `ibrav` | 晶格类型 | 自由参数 |
|---------|----------|----------|
| 1 | 简立方 (SC) | `celldm(1)` |
| 2 | 面心立方 (FCC) | `celldm(1)` |
| 3 | 体心立方 (BCC) | `celldm(1)` |
| 4 | 六方 (Hexagonal) | `celldm(1)`, `celldm(3)` |
| 0 | **通用** | 需提供 `CELL_PARAMETERS` |

**关键规则**：

- **`relax` 模式**：`ibrav` 可以非零（晶格固定），也可以为 0（配合 `CELL_PARAMETERS`，但晶格仍不优化）
- **`vc-relax` 模式**：**必须设置 `ibrav = 0`**，并显式提供 `CELL_PARAMETERS`，因为优化器需要直接操作晶格矢量
- `ibrav != 0` 时，`CELL_PARAMETERS` 不应出现在输入中（由 `celldm` 自动生成）
- `ibrav = 0` 时，`CELL_PARAMETERS` **必须**出现，单位可以是 `bohr`、`angstrom` 或 `alat`

> **最佳实践**：在 vc-relax 之前，先用 `relax` 预优化原子位置（固定实验晶格参数），再进行全优化，以避免初始应力过大导致的收敛问题。

---

## 6.8 实际操作注意事项

### 初始结构选择

1. **优先使用实验值**：初始晶格参数取自 XRD 或文献，通常在 DFT 平衡值附近 1~2% 以内
2. **先做 scf 测试**：在放松结构之前，先用实验结构做一次 SCF，检查力和应力的量级
3. **先 relax 再 vc-relax**：先固定晶格优化原子位置，再放开晶格，可减少 vc-relax 的步数

### 收敛困难的处理

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 力震荡不下降 | 步长过大或 Hessian 不准确 | 减小 `trust_radius_max`（如 0.1~0.3） |
| 能量上升后才下降 | 初始结构远离极小值 | 使用更合理的初始构型，或先用 `ion_dynamics = 'fire'` |
| vc-relax 不收敛 | 晶格变化过大 | 增大 `cell_factor`（如 1.5~2.0），减小 `trust_radius_max` |
| 达到最大步数仍未收敛 | 体系复杂或阈值过严 | 适当放宽 `forc_conv_thr`，或增大 `nstep` |
| 对称性报错 | 优化中晶体对称性降低 | 设置 `nosym = .true.` 或检查初始结构对称性 |

### 从优化结果提取后续计算的结构

优化完成后，输出文件末尾会打印最终的晶格参数和原子坐标。可直接从输出中提取：

```
Begin final coordinates
     new unit-cell volume = ...
CELL_PARAMETERS (angstrom)
   ...
ATOMIC_POSITIONS (angstrom)
   ...
End final coordinates
```

将这些内容复制到下一步计算的输入文件中即可。

---

## 6.9 输入文件示例

本章提供三个输入文件：

| 文件 | 说明 |
|------|------|
| [`inputs/si_relax.in`](inputs/si_relax.in) | Si 晶体固定晶格优化（relax） |
| [`inputs/si_vc_relax.in`](inputs/si_vc_relax.in) | Si 晶体变晶格优化（vc-relax） |
| [`inputs/h2o_relax.in`](inputs/h2o_relax.in) | H₂O 分子结构优化（大晶胞，relax） |

工作流脚本 [`scripts/relax_workflow.sh`](scripts/relax_workflow.sh) 演示了完整的 relax -> vc-relax 两步优化流程。

---

## 6.10 练习

1. 运行 [`si_relax.in`](inputs/si_relax.in)，观察每步的力和能量变化，比较收敛前后的原子坐标
2. 运行 [`si_vc_relax.in`](inputs/si_vc_relax.in)，对比优化前后的晶格常数与实验值（$a = 5.431$ Å）的差异
3. 修改 [`si_vc_relax.in`](inputs/si_vc_relax.in) 中的 `press` 参数为 100 kbar 和 500 kbar，观察晶格常数的变化趋势
4. 对 [`h2o_relax.in`](inputs/h2o_relax.in)，检查优化后的 O-H 键长和 H-O-H 键角，与实验值（$d_{OH} = 0.958$ Å, $\angle_{HOH} = 104.5°$）对比
