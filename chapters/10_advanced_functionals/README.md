# 第十章：高级泛函与电子关联修正

## 1. 为什么需要超越标准 DFT？

标准 LDA/GGA 泛函在描述许多真实材料时存在三类系统性误差：

- **强关联体系**（NiO、FeO 等过渡金属氧化物）：d/f 电子的局域性很强，标准泛函的**自相互作用误差**使 d/f 轨道过于离域，Mott 绝缘体被误判为金属
- **弱相互作用**（石墨层间、分子晶体）：LDA/GGA **完全缺失**范德华色散力，导致层间距和分子堆积被严重误判
- **带隙问题**（Si、GaN 等半导体）：GGA 系统性低估带隙 30%–50%，因为交换关联势的不连续性未被正确描述

本章介绍量子 ESPRESSO 中三种高级修正方法及其物理动机和使用方式。

---

## 2. DFT+U：Hubbard 修正

### 2.1 物理动机

在含有 **3d/4f 过渡金属** 的氧化物中，d/f 轨道之间存在显著的**在位库仑排斥**（on-site Coulomb interaction）。标准 GGA 泛函由于自相互作用误差，严重低估了这种排斥，导致：

- **带隙**被严重低估（如 NiO 实验带隙 ~4.3 eV，GGA 仅给出 ~0.5 eV）
- **磁矩**不准确
- 电子占据数趋于分数值，而非正确的整数占据

**DFT+U** 方法通过在标准泛函上添加 Hubbard 修正项来解决此问题。QE 采用 **Dudarev 旋转不变方案**（PRB 57, 1505, 1998），修正能量为：

$$E_{\text{DFT+U}} = E_{\text{DFT}} + \frac{U_{\text{eff}}}{2} \sum_{I,\sigma} \text{Tr}\!\left[n^{\sigma}(I)\left(1 - n^{\sigma}(I)\right)\right]$$

其中 $n^\sigma(I)$ 是原子 I 的局域占据矩阵，$U_{\text{eff}} = U - J$。当占据数为整数（0 或 1）时修正为零；分数占据时修正为正，从而**推动电子整数化**，打开 Mott 带隙。

### 2.2 关键参数

| 参数 | 含义 | 典型值 |
|------|------|--------|
| `lda_plus_u` | 启用 DFT+U 修正 | `.true.` |
| `lda_plus_u_kind` | 方案：0 = Dudarev 旋转不变（推荐） | `0` |
| `Hubbard_U(i)` | 第 i 类原子的 Hubbard U 值 | Ni: 5.0, Fe: 4.3 (eV) |
| `Hubbard_J(i)` | 第 i 类原子的 Hund 耦合参数 | 0 或 0.5–1.0 (eV) |
| `U_projection_type` | 投影算符类型 | `'ortho-atomic'`（推荐） |
| `starting_ns_eigenvalue(m,ispin,ityp)` | 初始占据矩阵特征值，用于破缺对称性 | 0.0–1.0 |

> **注意**：QE 中 Hubbard_U 的单位是 **eV**，实际起作用的是 $U_{\text{eff}} = U - J$。选取不当的 U 值会导致错误结论，因此推荐使用 hp.x 从第一性原理计算 U 值。

### 2.3 计算设置要点

NiO 是经典的 Mott 绝缘体案例。关键设置：

- 反铁磁 NiO 需要将两个 Ni 原子定义为**不同的原子类型**（Ni1、Ni2）
- 分别赋予**相反的初始磁矩**（`starting_magnetization(1) = 0.5, (2) = -0.5`）
- 启用 `nspin = 2`（自旋极化）
- 设置 `lda_plus_u = .true.` 和合适的 `Hubbard_U` 值

详细输入文件见 [`inputs/nio_dftu_scf.in`](inputs/nio_dftu_scf.in)。

---

## 3. HP 程序：第一性原理计算 Hubbard U

**hp.x** 通过**线性响应理论**自洽计算 U 值，无需经验拟合。其物理基础是：U 是占据数对局域势的二阶导数（Cococcioni & de Gironcoli, PRB 71, 035105, 2005）。

### 3.1 工作流程

1. **第一步 SCF**：使用极小的 U（`Hubbard_U(i) = 1.d-8`，近似为零）进行自洽计算，获得参考态
2. **第二步 SCF**（可选但推荐）：使用 `startingpot='file'`、`startingwfc='file'` 从第一步结果读取，以更高精度重新自洽
3. **运行 hp.x**：对每个 Hubbard 原子施加势扰动，计算线性响应函数 χ，从中提取 U

### 3.2 hp.x 输入参数

```
&inputhp
   prefix = 'NiO',
   outdir = './tmp/',
   nq1 = 2, nq2 = 2, nq3 = 2,
   conv_thr_chi = 1.0d-8,
   iverbosity = 2
/
```

| 参数 | 含义 | 说明 |
|------|------|------|
| `prefix` | 体系前缀 | 必须与 SCF 计算的 prefix 完全一致 |
| `outdir` | 输出目录 | 必须与 SCF 计算的 outdir 完全一致 |
| `nq1/2/3` | q 点网格 | 超胞扩展倍数，通常与 SCF 的 k 网格一致 |
| `conv_thr_chi` | 极化率收敛阈值 | 1.0d-8 为推荐精度 |
| `iverbosity` | 输出详细程度 | 1 = 基本，2 = 详细 |

> **重要提示**：hp.x 的计算成本约为普通 SCF 的 **10–50 倍**（取决于原子数和 q 网格），但对于获得可靠的 U 值是必要的投资。

详细输入文件见 [`inputs/nio_hp.in`](inputs/nio_hp.in)。

---

## 4. 范德华修正方法

### 4.1 问题本质

标准 DFT 泛函基于**局域或半局域**近似，无法描述**色散相互作用**（London dispersion）。色散力源于瞬时偶极-偶极关联，是一种**非局域的量子效应**，对以下体系至关重要：

- 层状材料（石墨、MoS₂、h-BN）
- 分子晶体和有机半导体
- 分子在表面的吸附

### 4.2 DFT-D2/D3 半经验色散修正

**Grimme 方法**在 DFT 能量上添加原子对间的色散校正：

$$E_{\text{disp}} = -\sum_{A<B} \left[ \frac{C_6^{AB}}{R^6} \cdot f_{\text{damp}}(R) + \frac{C_8^{AB}}{R^8} \cdot f_{\text{damp}}(R) \right]$$

| 参数 | D2 | D3 | D3(BJ) |
|------|----|----|--------|
| 色散系数 | 元素依赖（固定） | 元素和化学环境依赖 | 同 D3 |
| 阻尼函数 | Tang-Toennies | 原始 | Becke-Johnson（推荐） |
| 三体项 | 无 | 有 | 有 |
| 精度 | 中等 | 高 | 很高 |

QE 中的设置：

```
! DFT-D3(BJ)（推荐）
vdw_corr = 'dft-d3'
dftd3_version = 4

! DFT-D2
vdw_corr = 'dft-d'
```

**D3(BJ) 是性价比最高的选择**——计算成本几乎为零，精度优异。

### 4.3 非局域 vdW-DF 泛函

**vdW-DF** 将色散效应直接纳入交换关联泛函，通过密度依赖的非局域核描述色散关联能：

$$E_{xc} = E_x^{\text{revPBE}} + E_c^{\text{LDA}} + E_c^{\text{nl}}[\rho]$$

在 QE 中通过 `input_dft` 设置：

| input_dft 值 | 说明 | 推荐场景 |
|--------------|------|---------|
| `'vdw-df'` | 原始 vdW-DF（revPBE 交换） | 通用 |
| `'vdw-df2'` | vdW-DF2（改进交换泛函） | 分子体系 |
| `'vdw-df-cx'` | vdW-DF-CX | 固体（推荐） |
| `'vdw-df-obk8'` | optB88-vdW | 表面吸附（推荐） |

> **使用注意**：vdW-DF 需使用 **PBE 赘势**；`ecutrho` 通常需要较大值（`~10 × ecutwfc`）；计算成本比 DFT-D3 高约 50%–100%。

---

## 5. 杂化泛函（HSE06）

### 5.1 理论背景

**杂化泛函**将一部分 **Hartree-Fock 精确交换**混入 DFT 交换关联泛函。HF 交换不含自相互作用误差，因此杂化泛函能显著改善带隙预测。

**HSE06**（Heyd-Scuseria-Ernzerhof）仅在**短程**混合 HF 交换，长程仍用 PBE，兼顾精度和效率：

$$E_{xc}^{\text{HSE06}} = a \cdot E_x^{\text{HF,SR}}(\omega) + (1-a) \cdot E_x^{\text{PBE,SR}}(\omega) + E_x^{\text{PBE,LR}}(\omega) + E_c^{\text{PBE}}$$

其中 `a = 0.25` 是交换混合比例，`ω = 0.208 Å⁻¹` 是屏蔽参数。

### 5.2 关键参数

| 参数 | 含义 | HSE06 默认值 |
|------|------|-------------|
| `input_dft` | 泛函类型 | `'hse'` |
| `nqx1, nqx2, nqx3` | 交换积分 q 点网格 | 与 k 网格一致 |
| `exx_fraction` | HF 交换混合比例 a | `0.25` |
| `screening_parameter` | 屏蔽参数 ω (Å⁻¹) | `0.208` |
| `exxdiv_treatment` | 发散项处理 | `'gygi-baldereschi'` |
| `x_gamma_extrapolation` | Gamma 点外推加速收敛 | `.TRUE.` |

**nqx 参数**控制交换能积分的 q 点网格，对精度和成本影响极大：
- `nqx = 1`：仅 Gamma 点，最快但精度最低
- `nqx = 2`：较好平衡（推荐起步值）
- `nqx = 4`：高精度，但计算量急剧增加

> **实践建议**：从 `nqx = 1` 开始测试，逐步增大至结果收敛。对于带隙计算，通常 `nqx = 2` 已足够。

---

## 6. 适用场景与计算成本对比

### 6.1 方法选择指南

| 问题类型 | 推荐方法 | 理由 |
|---------|---------|------|
| 过渡金属氧化物电子结构 | DFT+U | 成本低，直接修正 d 电子局域化 |
| 稀土化合物 4f 电子 | DFT+U | 4f 强关联必须修正 |
| 层状材料层间距 | DFT-D3(BJ) | 性价比最高 |
| 分子吸附能 | DFT-D3(BJ) | 弱相互作用修正 |
| 半导体带隙 | HSE06 | 系统性精度最好 |
| 分子晶体结构 | DFT-D3 或 vdW-DF | 色散力主导 |
| 绝缘体反铁磁态 | DFT+U | 确保绝缘体基态 |

### 6.2 计算成本对比

以标准 PBE SCF 为基准（相对成本 = 1×）：

| 方法 | 相对成本 | 内存需求 | 并行扩展性 | 备注 |
|------|---------|---------|-----------|------|
| **PBE** | **1×** | 低 | 优秀 | 基准 |
| **PBE + DFT-D3** | **~1×** | 低 | 优秀 | 几乎无额外开销 |
| **PBE + DFT-D2** | **~1×** | 低 | 优秀 | 同上 |
| **PBE + vdW-DF** | **~1.5×** | 中等 | 良好 | 非局域核需额外 FFT |
| **GGA+U** | **~1×** | 低 | 优秀 | 仅添加对角修正，成本极低 |
| **hp.x (Hubbard U)** | **~10–50×** | 中等 | 良好 | 需对每个原子/扰动做响应 |
| **HSE06 (nqx=1)** | **~10–20×** | 高 | 中等 | Fock 交换积分是瓶颈 |
| **HSE06 (nqx=2)** | **~30–80×** | 很高 | 中等 | q 点增加使成本快速上升 |
| **PBE0 (nqx=2)** | **~30–80×** | 很高 | 中等 | 与 HSE 类似但无屏蔽 |

> **总结建议**：
> - 含过渡金属的体系：先用 **GGA+U** 快速探索，再用 **hp.x** 标定 U 值
> - 层状/分子体系：**DFT-D3(BJ)** 是默认推荐，几乎无额外成本
> - 带隙计算：GGA+U 不够时再用 **HSE06**，从 nqx=1 开始测试

---

## 7. 文件说明

| 文件 | 说明 |
|------|------|
| [`inputs/nio_dftu_scf.in`](inputs/nio_dftu_scf.in) | NiO 反铁磁态 DFT+U 自洽计算 |
| [`inputs/nio_hp.in`](inputs/nio_hp.in) | hp.x 计算 NiO 的 Hubbard U 参数 |
| [`inputs/graphene_vdw.in`](inputs/graphene_vdw.in) | 石墨烯 vdW-D3 色散修正（层间距优化） |
| [`inputs/si_hse_scf.in`](inputs/si_hse_scf.in) | Si HSE06 杂化泛函 SCF 计算 |
| [`inputs/h2o_dftd3.in`](inputs/h2o_dftd3.in) | 水分子 DFT-D3 色散修正 |
| [`scripts/advanced_functionals.sh`](scripts/advanced_functionals.sh) | 完整的高级泛函计算流程脚本 |

---

## 8. 练习

1. 将 NiO 的 `Hubbard_U` 从 5.0 改为 0.1，观察带隙如何变化
2. 石墨烯分别用 `vdw_corr='dft-d'`（D2）和 `vdw_corr='dft-d3'`（D3）计算，比较层间距差异
3. Si 用 `nqx=1` 和 `nqx=2` 分别运行 HSE06，观察总能量和带隙的收敛情况
4. 运行 hp.x 计算 NiO 的 Hubbard U，与文献值（~5–6 eV）比较

---

## 参考文献

1. **DFT+U**: Anisimov V.I. et al., *PRB* **44**, 943 (1991)
2. **旋转不变 DFT+U (Dudarev)**: Dudarev S.L. et al., *PRB* **57**, 1505 (1998)
3. **hp.x**: Cococcioni M. & de Gironcoli S., *PRB* **71**, 035105 (2005); Timrov I. et al., *PRB* **98**, 085127 (2018)
4. **DFT-D2**: Grimme S., *J. Comput. Chem.* **27**, 1787 (2006)
5. **DFT-D3**: Grimme S. et al., *J. Comput. Chem.* **32**, 1456 (2011)
6. **vdW-DF**: Dion M. et al., *PRL* **92**, 246401 (2004)
7. **HSE06**: Heyd J. et al., *J. Chem. Phys.* **118**, 8207 (2003); Krukau A.V. et al., *J. Chem. Phys.* **125**, 224106 (2006)
