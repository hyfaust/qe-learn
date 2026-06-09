# 第七章：磁性与自旋极化计算

## 7.1 自旋极化 DFT 基础

在标准 DFT 中，电子密度 $\rho(\mathbf{r})$ 是唯一的基本变量。**自旋极化 DFT**（Spin-Polarized DFT）将电子密度扩展为两个分量：

$$\rho(\mathbf{r}) = \rho_\uparrow(\mathbf{r}) + \rho_\downarrow(\mathbf{r})$$

**自旋密度**定义为：

$$m(\mathbf{r}) = \rho_\uparrow(\mathbf{r}) - \rho_\downarrow(\mathbf{r})$$

当 $m(\mathbf{r}) \neq 0$ 时，系统具有**净磁矩**。自旋向上和自旋向下的 Kohn-Sham 本征值不同，这种现象称为**交换劈裂**（exchange splitting），是磁性材料能带结构的关键特征。

> **何时需要自旋极化计算？** 含有过渡金属（Fe, Co, Ni）、稀土元素、自由基或开壳层分子的体系，通常都需要 `nspin=2`。

---

## 7.2 核心参数详解

### `nspin` — 自旋模式

| 值 | 含义 |
|---|------|
| `1` | **非自旋极化**（默认），自旋简并 |
| `2` | **共线磁性**（collinear），自旋向上/向下分别计算 |
| `4` | **非共线磁性**（noncollinear），需配合 `noncolin=.true.` |

### `starting_magnetization` — 初始磁矩

该参数为每种原子类型设定**初始自旋极化度**，取值范围 $[-1, 1]$：

$$\text{starting\_magnetization} = \frac{N_\uparrow - N_\downarrow}{N_\uparrow + N_\downarrow}$$

| 值 | 含义 |
|----|------|
| `0.7` | 每个 Ni 原子初始自旋极化度 70%（适合 Ni） |
| `0.5` | 适合 Fe、Co 等 |
| `0.0` | 无初始磁矩（非磁性原子） |
| 负值 | 反铁磁排列中原子的反向磁矩 |

**设置策略**：
- **铁磁（FM）**：所有同类原子设置相同的正 `starting_magnetization`
- **反铁磁（AFM）**：同种原子通过不同 `ATOMIC_SPECIES` 标签区分，分别设置正、负初始磁矩
- 初始值只需"大致合理"，SCF 自洽后磁矩会收敛到物理正确值
- 初始值过小可能导致收敛到非磁性亚稳态

---

## 7.3 铁磁（FM）计算示例

以 **fcc Ni** 铁磁态为例，关键设置如下：

```fortran
&system
    ibrav = 2, celldm(1) = 6.48,
    nat = 1, ntyp = 1,
    ecutwfc = 24.0, ecutrho = 288.0,
    nspin = 2,
    starting_magnetization(1) = 0.7,
    occupations = 'smearing', smearing = 'mv', degauss = 0.02,
/
```

> 详细输入文件见 [`inputs/ni_fm_scf.in`](inputs/ni_fm_scf.in)。

---

## 7.4 反铁磁（AFM）计算设置

对于反铁磁体系（如 NiO），关键技巧是将**化学等价但磁性不等价**的原子定义为不同原子类型：

```fortran
&system
    ntyp = 3,   ! Ni_up, Ni_down, O
    nat = 4,
    nspin = 2,
    starting_magnetization(1) =  0.5,   ! Ni_up
    starting_magnetization(2) = -0.5,   ! Ni_down
    starting_magnetization(3) =  0.0,   ! O
/
ATOMIC_SPECIES
 Ni_up  58.69  Ni.pz-nd-rrkjus.UPF
 Ni_dn  58.69  Ni.pz-nd-rrkjus.UPF
 O      16.00  O.pbe-rrkjus.UPF
```

两种 Ni 原子共享同一赝势文件，但通过不同的标签与初始磁矩区分自旋方向。

---

## 7.5 Fe 铁磁 bcc 计算

**bcc Fe** 是磁性计算的经典测试体系：

```fortran
&system
    ibrav = 3, celldm(1) = 5.40,
    nat = 1, ntyp = 1,
    ecutwfc = 25.0, ecutrho = 250.0,
    nspin = 2,
    starting_magnetization(1) = 0.5,
    occupations = 'smearing', smearing = 'mv', degauss = 0.02,
/
```

> 详细输入文件见 [`inputs/fe_fm_scf.in`](inputs/fe_fm_scf.in)。

---

## 7.6 磁矩输出解读

SCF 计算完成后，输出文件中会出现两行关键信息：

```
total magnetization       =    0.63 Bohr mag/cell
absolute magnetization    =    0.63 Bohr mag/cell
```

| 物理量 | 含义 |
|--------|------|
| **total magnetization** | $\int (\rho_\uparrow - \rho_\downarrow) d\mathbf{r}$，总磁矩，可为正或负 |
| **absolute magnetization** | $\int |\rho_\uparrow - \rho_\downarrow| d\mathbf{r}$，绝对磁矩，始终非负 |

- 铁磁态：两者相等
- 反铁磁态：total $\approx 0$，absolute 仍为有限值
- 单位为 **Bohr 磁子/原胞**（Bohr mag/cell）

每种原子的磁矩可通过 Bader 分布或投影态密度进一步分解。

---

## 7.7 非共线磁性与自旋轨道耦合

### 非共线磁性（Noncollinear Magnetism）

在真实材料中，磁矩方向不一定平行排列。**非共线磁性**允许每个原子的磁矩指向任意方向：

```fortran
&system
    noncolin = .true.,
    starting_magnetization(1) = 0.5,
    angle1(1) = 90.0,    ! 极角（与 z 轴夹角）
    angle2(1) =  0.0,    ! 方位角（在 xy 平面内）
/
```

### 自旋轨道耦合（SOC）

**自旋轨道耦合**（Spin-Orbit Coupling）是自旋与轨道角动量之间的相对论性相互作用，对于以下情况至关重要：

- **磁晶各向异性能**（Magnetic Anisotropy Energy, MAE）
- **拓扑绝缘体**、**Rashba 效应**
- 重元素体系（5d、4f 电子）

```fortran
&system
    noncolin = .true.,
    lspinorb = .true.,
    starting_magnetization(1) = 0.5,
/
```

> **注意**：SOC 计算必须使用**全电子势**或包含 SOC 信息的赝势。标准标量相对论赝势不能直接用于 SOC 计算。计算量约为普通自旋极化的 **4 倍**。

---

## 7.8 展宽方法对磁性计算的影响

金属体系的磁性计算对**展宽方法**（smearing）特别敏感：

| 展宽方法 | `smearing` | 对磁性的影响 |
|----------|-----------|-------------|
| Methfessel-Paxton | `'mp'` | 高阶展宽，对力和应力精度高，磁性计算推荐 |
| Marzari-Vanderbilt | `'mv'` | 冷展宽，对总能和磁矩较好，推荐用于磁性 |
| Fermi-Dirac | `'fd'` | 有明确物理温度含义，适合有限温度模拟 |
| Gaussian | `'gaussian'` | 简单但收敛慢，磁矩可能偏大 |

**关键建议**：
- `deaussa` 值不宜过大（建议 0.01-0.05 Ry），否则会人为展宽态密度，影响磁矩
- 不同展宽方法下 `degauss` 的含义不同，不可直接比较
- 磁性计算建议先用较大 `degauss` 快速收敛，再逐步减小到 0.01-0.02 Ry 精确计算

---

## 7.9 参数速查表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `nspin` | INTEGER | `1` | 1=非极化, 2=共线, 4=非共线 |
| `starting_magnetization(i)` | REAL | `0.0` | 第 i 类原子的初始磁极化度 [-1,1] |
| `noncolin` | LOGICAL | `.false.` | 非共线磁性开关 |
| `lspinorb` | LOGICAL | `.false.` | 自旋轨道耦合开关 |
| `angle1(i)` | REAL | `0.0` | 非共线模式下第 i 类原子磁矩极角（度） |
| `angle2(i)` | REAL | `0.0` | 非共线模式下第 i 类原子磁矩方位角（度） |
| `report` | INTEGER | `0` | >0 时输出每原子投影磁矩 |

---

## 7.10 计算流程概览

```
1. 结构建模 → 2. 设置 nspin=2 与 starting_magnetization
     → 3. SCF 自洽 → 4. 检查 total/absolute magnetization
     → 5. （可选）能带/态密度 → 6. （可选）非共线/SOC
```

---

## 文件索引

| 文件 | 说明 |
|------|------|
| [`inputs/ni_fm_scf.in`](inputs/ni_fm_scf.in) | Ni fcc 铁磁 SCF 计算 |
| [`inputs/ni_fm_bands.in`](inputs/ni_fm_bands.in) | Ni 铁磁能带计算 |
| [`inputs/ni_bands.pp.in`](inputs/ni_bands.pp.in) | bands.x 能带后处理 |
| [`inputs/fe_fm_scf.in`](inputs/fe_fm_scf.in) | Fe bcc 铁磁 SCF 计算 |
| [`scripts/magnetism_workflow.sh`](scripts/magnetism_workflow.sh) | 完整磁性计算工作流脚本 |
