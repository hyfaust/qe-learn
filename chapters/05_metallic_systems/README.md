# 第五章：金属体系与展宽方法

## 金属与绝缘体的本质区别

在固体物理中，**金属**和**绝缘体**的核心区别在于**费米面**（Fermi surface）附近电子态的占据情况：

- **绝缘体/半导体**：存在**带隙**（band gap），费米能级位于价带顶和导带底之间，所有占据态和非占据态之间有明确分界
- **金属**：**无带隙**，费米能级穿过能带，存在部分占据的能带，形成费米面

在 DFT 计算中，这种区别直接影响数值求解策略。绝缘体的电子占据数在 0 k 格点上要么是 0 要么是 1（整数），而金属的占据数在费米面附近是**分数**的。

## 为什么金属需要展宽（Smearing）

金属计算面临一个关键的**数值不稳定性**问题。在 k 空间中离散采样时，费米面附近的 k 点可能恰好处于能带穿越费米能级的位置。微小的 k 点变化会导致某个态从"完全占据"变为"完全未占据"，使得总能量对 k 点网格极度敏感，导致 SCF 迭代难以收敛。

**展宽方法**的核心思想：将阶梯函数形式的费米-狄拉克占据数替换为**平滑函数**，用一个有限宽度 σ（即 `degauss` 参数）来模糊占据与未占据的边界，从而稳定数值计算。

在 Quantum ESPRESSO 中，通过以下参数控制展宽：

```
occupations = 'smearing'
smearing    = 'type'
degauss     = sigma    ! 以 Ry 为单位
```

## 展宽方法详解

### 1. Gaussian 展宽

最简单的展宽方法，将每个能级的 δ 函数替换为高斯函数：

$$f(\varepsilon) = \tfrac{1}{2}\,\text{erfc}\!\left(\frac{\varepsilon - \varepsilon_F}{\sigma}\right)$$

- **优点**：简单直观，易于理解
- **缺点**：收敛较慢，需要较大的 k 点网格
- **适用**：入门学习、简单测试

### 2. Methfessel-Paxton (MP) 展宽

通过 Hermite 多项式修正高斯函数，消除低阶矩的误差：

```
smearing = 'methfessel-paxton'
```

- **参数 N**：阶数（默认 N=1），控制修正的阶次
- **优点**：高阶矩被精确消去，总能量对 σ 的依赖极弱
- **缺点**：可能出现**负的占据数**（物理上不合理，但数学上正确）
- **适用**：**金属体系的首选方法**，特别是态密度计算

### 3. Marzari-Vanderbilt（冷展宽 / Cold Smearing）

由 Marzari 和 Vanderbilt 提出，最小化对物理基态的扰动：

```
smearing = 'marzari-vanderbilt'
```

- **优点**：总能量是 σ 的**单调递减函数**，便于外推到 σ→0
- **缺点**：也可能出现负占据数
- **适用**：需要精确总能量和力的计算（如结构优化）

### 4. Fermi-Dirac 展宽

直接使用物理的费米-狄拉克分布函数：

```
smearing = 'fermi-dirac'
```

- **物理意义**：对应真实温度 T，σ = k_B T
- **优点**：物理上最自然
- **缺点**：对 σ 值敏感，收敛较慢
- **适用**：需要与真实温度关联的计算、MD 模拟

## 展宽方法对比

| 方法 | 关键字 | 能量对 σ 的行为 | 负占据数 | 推荐场景 |
|------|--------|----------------|---------|---------|
| Gaussian | `gaussian` | 依赖较强 | 否 | 学习、测试 |
| Methfessel-Paxton | `methfessel-paxton` | 依赖极弱 | 可能 | **金属 SCF 首选** |
| Marzari-Vanderbilt | `marzari-vanderbilt` | 单调递减 | 可能 | 结构优化、力计算 |
| Fermi-Dirac | `fermi-dirac` | 依赖较强 | 否 | 有限温度 MD |

## degauss 参数的选择策略

`degauss` 是展宽宽度，以 **Ry** 为单位。选择原则：

- **过小**：收敛慢，需要极密的 k 点网格
- **过大**：物理量被过度模糊，偏离真实值
- **经验值**：
  - Al 等自由电子金属：`degauss = 0.03 ~ 0.05 Ry`
  - Cu、Ni 等 d 电子金属：`degauss = 0.01 ~ 0.03 Ry`
- **收敛测试**：先固定 k 点网格，扫描 degauss 值，使总能量变化 < 1 meV/atom

最佳实践：进行 **degauss 和 k 点网格的联合收敛测试**，找到使总能量收敛的最优组合。

## 金属计算需要更多 k 点

金属计算中 k 点网格通常比绝缘体**密 2~4 倍**，原因：

1. **费米面采样**：需要足够密的网格精确描述费米面的形状
2. **展宽收敛**：小 degauss 值要求更密的网格
3. **经验起点**：FCC 金属通常从 `8×8×8` 或 `10×10×10` 开始测试

## 超软赝势与 ecutrho

Cu 的赝势 `Cu.pz-d-rrkjus.UPF` 是**超软赝势**（USPP），注意名字中的 "rrkjus"。与 norm-conserving 赝势相比：

- `ecutwfc` 较低（25 Ry vs 通常 40+ Ry），平面波截断能更小
- 需要额外设置 `ecutrho`（电荷密度截断能），通常为 `ecutwfc` 的 8~12 倍
- 对于 USPP，`ecutrho = 300 Ry` 对应 `ecutwfc` 的 12 倍

```
ecutwfc = 25.0
ecutrho = 300.0    ! 超软赝势必须指定
```

Al 使用的 `Al.pz-vbc.UPF` 是 norm-conserving 赝势，不需要指定 `ecutrho`。

## 三种金属的对比

### Al — 自由电子金属

- FCC 结构，`celldm(1) = 7.50 Bohr`
- **s-p 电子**，能带接近自由电子抛物线
- 费米面接近球形，k 点收敛较快
- 使用 Marzari-Vanderbilt 展宽，`degauss = 0.05 Ry`

### Cu — d 电子金属

- FCC 结构，`celldm(1) = 6.73 Bohr`
- **d 电子**在费米面附近形成复杂能带结构
- 费米面有明显的 neck 结构，需要更密的 k 点
- 使用超软赝势，`ecutrho = 300.0`
- `degauss = 0.02 Ry`（比 Al 更小，因为 d 带更窄）

### Ni — 磁性金属（第七章预览）

- FCC 结构，`celldm(1) = 6.48 Bohr`
- **自旋极化**：`nspin = 2`，需要设置初始磁矩
- d 电子的交换劈裂导致自旋向上/向下的能带分裂
- 本章仅做了解，详细计算将在第七章展开

## 本章输入文件说明

| 文件 | 体系 | 说明 |
|------|------|------|
| [`inputs/al_scf.in`](inputs/al_scf.in) | Al FCC | SCF 基态，Marzari-Vanderbilt 展宽 |
| [`inputs/cu_scf.in`](inputs/cu_scf.in) | Cu FCC | SCF 基态，超软赝势，Marzari-Vanderbilt 展宽 |
| [`inputs/cu_scf_gauss.in`](inputs/cu_scf_gauss.in) | Cu FCC | 对比：Gaussian 展宽 |
| [`inputs/al_bands.in`](inputs/al_bands.in) | Al FCC | 能带计算（沿 Γ-X-W-L-Γ-K 路径） |
| [`inputs/cu_bands.in`](inputs/cu_bands.in) | Cu FCC | 能带计算 |
| [`inputs/al_bands.pp.in`](inputs/al_bands.pp.in) | Al | bands.x 后处理 |
| [`inputs/cu_bands.pp.in`](inputs/cu_bands.pp.in) | Cu | bands.x 后处理 |

## 练习

1. 对 Al 进行 degauss 收敛测试：固定 `8 8 8` k 点，扫描 degauss = 0.01, 0.02, 0.03, 0.05, 0.07, 0.10 Ry，比较总能量
2. 对比 Cu 使用 Gaussian 和 Marzari-Vanderbilt 展宽的总能量差异
3. 画出 Al 和 Cu 的能带结构，比较 s-p 金属和 d 金属的能带特征
