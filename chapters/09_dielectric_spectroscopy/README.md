# 第九章：介电与光谱性质

## 1. 介电函数理论基础

当电磁波入射到材料上时，材料中的电子会发生极化响应。**介电函数** ε(ω) 描述了这种响应的频率依赖关系，是理解材料光学性质的核心物理量。

### 1.1 线性响应理论

在外加电场 **E** 的作用下，材料产生感应极化 **P**：

$$P_i = \chi_{ij} E_j$$

其中 $\chi_{ij}$ 是**电极化率张量**。介电常数张量与极化率的关系为：

$$\varepsilon_{ij}(\omega) = \delta_{ij} + 4\pi \chi_{ij}(\omega)$$

对于立方晶系（如 Si、金刚石），介电张量退化为标量：ε = ε_xx = ε_yy = ε_zz。

### 1.2 静态介电常数

**静态介电常数** ε₀（ω→0 极限）反映了材料对外加静电场的屏蔽能力：
- 真空：ε₀ = 1
- 典型半导体：ε₀ = 10-15（Si: ~12, GaAs: ~13）
- 典型绝缘体：ε₀ = 3-5（金刚石: ~5.7）

> **关键概念**：QE 中通过 DFPT（ph.x 设置 `epsil=.true.`）计算**高频（电子）介电常数** ε∞，它等于静态介电常数中只考虑电子响应的部分（忽略离子贡献）。

---

## 2. Born 有效电荷

**Born 有效电荷** $Z^*$ 描述了离子位移引起的极化变化：

$$P_i = \sum_\kappa Z^*_{\kappa,ij}\, u_{\kappa,j}$$

其中 u_κ,j 是原子 κ 在 j 方向的位移。物理意义：
- Z* 反映了离子位移时电子云的重叠效应
- 对于离子晶体，Z* 通常接近形式电荷
- 对于共价晶体，Z* 可能显著偏离形式电荷
- **声子的 LO-TO 分裂**与 Born 电荷直接相关

> **关键概念**：Born 有效电荷和介电常数共同决定了长程库仑相互作用对声子频率的影响。在极性材料中，LO（纵光学）和 TO（横光学）声子在 Γ 点的频率分裂为：

$$\omega^2_{\text{LO}} = \omega^2_{\text{TO}} + \frac{4\pi}{\varepsilon_\infty} \cdot \frac{(Z^* e)^2}{\mu V}$$

---

## 3. 红外（IR）与拉曼（Raman）光谱

### 3.1 红外光谱

红外活性判据：声子模式必须引起偶极矩变化，即 Born 有效电荷不为零。IR 强度正比于：

$$I_{\text{IR}} \propto \left|\sum_\kappa Z^*_\kappa \cdot \mathbf{e}_\kappa(\nu)\right|^2$$

其中 e_κ(ν) 是模式 ν 中原子 κ 的本征矢量。

### 3.2 拉曼光谱

拉曼活性判据：声子模式必须引起介电极化率变化。拉曼张量由 DFPT 计算：

$$R_{\alpha\beta} = \frac{\partial \chi_{\alpha\beta}}{\partial u}$$

> **关键概念**：并非所有声子模式都是 IR 或 Raman 活性的。对称性选择定则决定了哪些模式可以被观测到。例如，在金刚石结构中，Γ 点只有一个三重简并的 T₂g 模式是 Raman 活性的。

---

## 4. QE 计算流程

### 4.1 通过 DFPT 计算光学性质

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│  pw.x SCF   │ →  │ ph.x Γ 点    │ →  │ dynmat.x     │
│  (基态)      │    │ epsil=.true. │    │ (IR/Raman)   │
│              │    │ lraman=.true.│    │              │
└─────────────┘    └──────────────┘    └──────────────┘
```

### 4.2 通过 epsilon.x 计算频率依赖介电函数

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│  pw.x SCF   │ →  │ pw.x NSCF    │ →  │ epsilon.x    │
│  (基态)      │    │ (更多能带)    │    │ (独立粒子)   │
└─────────────┘    └──────────────┘    └──────────────┘
```

**注意**：epsilon.x 计算的是独立粒子近似下的介电函数，不包含局域场效应和激子效应。

---

## 5. 关键参数详解

### ph.x 光学性质参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `epsil` | LOGICAL | .false. | 是否计算介电常数和 Born 有效电荷 |
| `lraman` | LOGICAL | .false. | 是否计算非共价拉曼张量 |
| `fildyn` | CHARACTER | 'matdyn' | 动力学矩阵输出文件名 |
| `tr2_ph` | REAL | 1.0d-14 | DFPT 收敛阈值 |

### epsilon.x 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `prefix` | CHARACTER | — | 与 pw.x 一致的前缀 |
| `outdir` | CHARACTER | — | 临时文件目录 |
| `niter` | INTEGER | 100 | 最大迭代次数 |
| `ethr_n` | REAL | 1.0d-6 | 收敛阈值 |

### dynmat.x 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `fildyn` | CHARACTER | — | 输入动力学矩阵文件名 |
| `filout` | CHARACTER | 'dynmat.out' | 输出本征值/本征矢文件 |
| `asr` | CHARACTER | 'no' | 声学求和规则（'no', 'simple', 'crystal'） |
| `q(3)` | REAL | 0,0,0 | q 点坐标 |

---

## 6. 实操示例

### 6.1 金刚石（C）的介电性质和 IR/Raman 光谱

详见 [`inputs/`](inputs/) 目录中的示例文件：

1. [`inputs/c_scf.in`](inputs/c_scf.in) — SCF 基态计算
2. [`inputs/c_ph_gamma.in`](inputs/c_ph_gamma.in) — Γ 点声子 + 介电常数 + Born 电荷
3. [`inputs/c_dynmat.in`](inputs/c_dynmat.in) — dynmat.x 后处理提取 IR/Raman 强度

运行流程参见 [`scripts/spectroscopy_workflow.sh`](scripts/spectroscopy_workflow.sh)。

### 6.2 Si 的频率依赖介电函数

使用 epsilon.x 计算 Si 的光学吸收谱：

1. [`inputs/si_scf.in`](inputs/si_scf.in) — SCF 基态计算
2. [`inputs/si_scf.nscf.in`](inputs/si_scf.nscf.in) — NSCF 计算（更多能带）
3. [`inputs/si_epsilon.in`](inputs/si_epsilon.in) — epsilon.x 计算

---

## 7. 注意事项

1. **绝缘体 vs 金属**：DFPT 计算光学性质仅适用于绝缘体/半导体。金属的光学性质需要不同的方法。

2. **收敛性**：介电性质对 k 点和截断能的收敛性要求通常比总能量更高。建议使用比 SCF 更密的 k 网格。

3. **LO-TO 分裂**：在极性材料中，ph.x 设置 `epsil=.true.` 后会自动处理 LO-TO 分裂。需要提供 Born 有效电荷和介电常数。

4. **拉曼张量**：`lraman=.true.` 计算成本较高，因为需要求解额外的 Sternheimer 方程。

5. **epsilon.x 的局限**：独立粒子近似会低估带隙，导致吸收边蓝移。更精确的结果需要 GW+BSE 方法。

---

## 8. 关键概念速查

| 概念 | 说明 |
|------|------|
| **介电函数** ε(ω) | 描述材料对电磁场的频率依赖响应 |
| **Born 有效电荷** Z* | 离子位移引起的极化变化，决定 IR 活性和 LO-TO 分裂 |
| **IR 活性** | 声子模式引起偶极矩变化 → 可被红外光谱观测 |
| **Raman 活性** | 声子模式引起极化率变化 → 可被拉曼光谱观测 |
| **LO-TO 分裂** | 极性材料中 Γ 点纵光学和横光学声子的频率差 |
| **独立粒子近似** | epsilon.x 使用的近似，忽略电子-空穴相互作用 |
