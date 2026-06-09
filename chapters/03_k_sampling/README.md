# 第三章：k 空间采样与布里渊区

## 1. 倒格子与布里渊区

晶体的**周期性**决定了电子态可以用**波矢 k** 来标记。实空间中的布拉维格子对应一个**倒格子**（reciprocal lattice），其基矢 $\mathbf{b}_i$ 满足：

$$\mathbf{a}_i \cdot \mathbf{b}_j = 2\pi\,\delta_{ij}$$

倒格子的**第一布里渊区**（First Brillouin Zone, BZ）是倒空间中距离原点最近的区域，它是 k 空间中的基本不可约单元。所有独立的电子态都可以用布里渊区内的 k 点来描述。

## 2. 为什么需要 k 点采样

**布洛赫定理**指出，周期性势场中电子波函数可以写成：

$$\psi_{n\mathbf{k}}(\mathbf{r}) = e^{i\mathbf{k}\cdot\mathbf{r}}\,u_{n\mathbf{k}}(\mathbf{r})$$

其中 $u_{n\mathbf{k}}$ 具有晶格周期性。这意味着：
- 每个 **k 点** 独立求解一组薛定谔方程
- 总能量等物理量是对布里渊区内**所有 k 点的积分**

实际计算中我们无法对连续的 BZ 积分，必须选取一组**离散的 k 点**进行求和。k 点的选取直接决定了计算的精度和效率。

## 3. Monkhorst-Pack 网格

最常用的 k 点采样方案是 **Monkhorst-Pack (MP) 网格**：在布里渊区的三个倒格矢方向上分别取均匀分布的 $N_1 \times N_2 \times N_3$ 个 k 点：

$$\mathbf{k}_{ijk} = \frac{i}{N_1}\mathbf{b}_1 + \frac{j}{N_2}\mathbf{b}_2 + \frac{k}{N_3}\mathbf{b}_3$$

**网格密度的选择原则：**
- **金属体系**：费米面附近的态对积分贡献大，需要较密的 k 网格（通常 12x12x12 以上）
- **半导体/绝缘体**：能带间隙使得积分收敛更快，较稀疏的网格即可（通常 4x4x4 到 8x8x8）
- **表面/分子体系**：非周期方向只需 1 个 k 点

> **经验值**：Si 作为典型的半导体，ecutwfc=18 Ry 时，6x6x6 或 8x8x8 的 MP 网格通常足够收敛总能量至 ~1 meV/atom。

## 4. K_POINTS 卡的格式

QE 的 `K_POINTS` 卡支持多种格式，语法如下：

```fortran
K_POINTS {option}
n
kx1  ky1  kz1  weight1
kx2  ky2  kz2  weight2
...
```

### 4.1 各格式详解

| 格式 | 关键字 | 说明 | 适用场景 |
|------|--------|------|----------|
| `automatic` | `K_POINTS {automatic}` | 自动生成 Monkhorst-Pack 网格，支持偏移 | 绝大多数 SCF 计算 |
| `gamma` | `K_POINTS {Gamma}` | 仅使用 Gamma 点 (k=0) | 分子、超胞、Gamma-only 计算 |
| `crystal` | `K_POINTS {crystal}` | 手动指定 k 点，使用晶体坐标 (分数坐标) | 自定义 k 点采样 |
| `tpiba` | `K_POINTS {tpiba}` | 手动指定 k 点，使用 $2\pi/a$ 为单位的笛卡尔坐标 | 需要精确控制 k 点坐标 |
| `crystal_b` | `K_POINTS {crystal_b}` | 沿高对称路径的 k 点，晶体坐标，权重=两点间点数 | 能带结构计算 |
| `tpiba_b` | `K_POINTS {tpiba_b}` | 同上，但使用 $2\pi/a$ 单位 | 能带结构计算 |
| `crystal_c` | `K_POINTS {crystal_c}` | 定义倒空间矩形区域的均匀网格 | 等能面/费米面绘图 |
| `tpiba_c` | `K_POINTS {tpiba_c}` | 同上，但使用 $2\pi/a$ 单位 | 等能面/费米面绘图 |

### 4.2 automatic 格式语法

```
K_POINTS {automatic}
nk1  nk2  nk3  shift1  shift2  shift3
```

- `nk1 nk2 nk3`：三个方向的 k 点数目
- `shift1 shift2 shift3`：偏移量（0 或 1），控制网格是否偏离 Gamma 点

### 4.3 crystal_b 格式语法（能带计算）

```
K_POINTS {crystal_b}
n_points
kx1  ky1  kz1  n_seg1     ! 起点，n_seg1 为到下一点的分段数
kx2  ky2  kz2  n_seg2     ! 经过的高对称点
...
kxn  kyn  kzn  0          ! 终点，权重为 0
```

## 5. 偏移（Shift）的作用

Monkhorst-Pack 网格的偏移参数（shift）控制网格是否包含 Gamma 点：

| 偏移 | 网格特征 | 说明 |
|------|---------|------|
| `0 0 0` | 包含 Gamma 点 | 网格包含 k=0，偶数网格时对称性较低 |
| `1 1 1` | 不含 Gamma 点 | 偏移半个网格间距，对称性通常更高 |

> **建议**：对于偶数网格（如 4x4x4、6x6x6），使用 `1 1 1` 偏移通常能更好地利用晶体对称性，减少不可约 k 点数。对于奇数网格，`0 0 0` 即可。实际差异通常很小。

## 6. 对称性与不可约 k 点

晶体的**点群对称性**使得布里渊区中许多 k 点是等价的。QE 会自动利用对称性将全布里渊区的 k 点约化为**不可约布里渊区**（IBZ）中的 k 点，从而大幅减少计算量。

以 Si（Fd-3m，含 48 个对称操作）为例：
- 全 BZ: 8x8x8 = 512 个 k 点
- 不可约 BZ: 仅约 **20** 个 k 点

输出文件中会显示 `number of k points=` 和对称性约化信息，帮助确认采样是否合理。

## 7. k 点收敛性测试

确定合适的 k 点密度是 DFT 计算的第一步。标准流程：

```
对一系列递增的 MP 网格 (如 2x2x2 → 4x4x4 → ... → 10x10x10)：
  1. 保持其他参数不变（截断能、赝势等）
  2. 运行 SCF 计算
  3. 提取总能量
  4. 绘制 E(k网格) 曲线
  5. 选择能量变化 < 收敛阈值的最小网格
```

对于本章的练习，运行 [`scripts/k_convergence.sh`](scripts/k_convergence.sh) 脚本即可自动完成此流程。

## 8. 参数速查表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `k_points` | character | `'gamma'` | k 点生成方式 |
| `nk1, nk2, nk3` | integer | 0 | MP 网格各方向点数 |
| `k1, k2, k3` | integer | 0 | 偏移（0 或 1） |

## 9. 练习

1. 运行 `inputs/` 中的各输入文件，比较不同 k 网格的总能量
2. 运行 [`scripts/k_convergence.sh`](scripts/k_convergence.sh) 自动化收敛性测试
3. 思考：为什么 Gamma 点计算对 Si 的总能量偏差很大？

---

**下一章**：[第四章：能带结构与态密度](../04_bands_and_dos/)
