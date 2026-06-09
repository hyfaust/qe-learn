# 第四章：能带结构与态密度

## 4.1 能带理论基础

### Bloch 定理

在周期性晶体中，电子波函数满足 **Bloch 定理**：$\psi_{n\mathbf{k}}(\mathbf{r}) = e^{i\mathbf{k}\cdot\mathbf{r}} u_{n\mathbf{k}}(\mathbf{r})$，其中 $u_{n\mathbf{k}}$ 具有晶格周期性。每个 $\mathbf{k}$ 点对应一组离散能量本征值 $E_n(\mathbf{k})$，将 $E_n(\mathbf{k})$ 沿布里渊区高对称路径画出，即为**能带结构**。

- **价带**：被电子占据的最高能带；**导带**：未占据的最低能带
- **带隙**：价带顶与导带底的能量差，决定材料的导电性质

---

## 4.2 计算工作流

```
┌─────────────┐     ┌───────────────────┐     ┌───────────────┐
│  SCF 自洽   │────▶│  bands / nscf 计算 │────▶│  后处理提取    │
│  si_scf.in  │     │  si_bands.in 或    │     │  bands.x      │
│  4×4×4 k点  │     │  si_dos.in        │     │  dos.x        │
│  确定基态   │     │  更多k点/更多能带  │     │  projwfc.x    │
└─────────────┘     └───────────────────┘     └───────────────┘
```

---

## 4.3 能带计算详解

### Step 1：SCF 自洽计算

SCF 确定基态电荷密度和费米能级，使用较少的 k 点（4×4×4）即可收敛。

### Step 2：能带计算

```fortran
&control
    calculation = 'bands'   ! 沿高对称路径计算
    prefix = 'silicon'
    ...
/
&system
    nbnd = 8   ! 计算 8 条能带（Si 有 8 个价电子）
    ...
/
K_POINTS tpiba_b
  5
  0.5  0.5  0.5   30   ! L
  0.0  0.0  0.0   30   ! Gamma
  1.0  0.0  0.0   30   ! X
  1.0  0.25 0.25  30   ! W
  0.75 0.75 0.0    1   ! K
```

> **`nbnd` 参数**：计算的能带数目。默认为价电子数/2 + 若干空带。Si 有 8 个价电子，设 `nbnd=8` 获得全部价带；设更大值（如 12）可同时获得导带信息。

> **`'nscf'` vs `'bands'` 的区别**：
> - `calculation='nscf'`：均匀 k 网格，用于 DOS/PDOS
> - `calculation='bands'`：高对称路径，用于能带图

### Step 3：bands.x 后处理

```fortran
&bands
    prefix = 'silicon', outdir = './tmp/'
    filband = 'si_bands.dat'
    lsym = .true.   ! 标注能带对称性
/
```

### Step 4：plotband.x 绘图

plotband.x 读取 `si_bands.dat`，生成 PostScript 或 xmgrace 格式的能带图。需指定费米能级（从 SCF 输出获取）。

---

## 4.4 FCC Si 高对称路径

| 高对称点 | 坐标 (tpiba_b) | 对称性 |
|---------|----------------|--------|
| L | 0.5 0.5 0.5 | C₃ᵥ |
| Γ | 0.0 0.0 0.0 | Oₕ |
| X | 1.0 0.0 0.0 | C₄ᵥ |
| W | 1.0 0.25 0.25 | C₂ᵥ |
| K | 0.75 0.75 0.0 | C₂ᵥ |

---

## 4.5 态密度（DOS）

SCF → `calculation='nscf'`（更密 k 网格，如 12×12×12） → `dos.x`：

```fortran
&dos
    prefix = 'silicon', outdir = './tmp/'
    fildos = 'si_dos.dat'
    Emin = -10.0, Emax = 15.0, DeltaE = 0.01
/
```

DOS 给出单位能量区间内的电子态数目，积分可得总电子数。

---

## 4.6 投影态密度（PDOS）

`projwfc.x` 将波函数投影到原子轨道，分析各轨道（如 Si 3s、3p）的贡献：

```fortran
&projwfc
    prefix = 'silicon', outdir = './tmp/'
    filpdos = 'si_pdos'
    ngauss = 0, degauss = 0.01
/
```

输出 `si_pdos.*.dat` 包含各原子各角动量通道的投影态密度，可分析 sp³ 杂化等成键特征。

---

## 4.7 关键概念卡片

> **费米能级**：绝对零度下电子占据态与未占据态的分界能量。SCF 输出中 `the Fermi energy is` 即为费米能级（eV），能带图中通常以其为能量零点。

> **带隙**：价带顶到导带底的能量差。Si 为间接带隙半导体（实验值 ~1.17 eV），LDA/PBE 通常低估带隙。

> **高对称点**：布里渊区中具有特殊对称性的点，能带在这些点处发生简并。FCC 标准路径 L-Γ-X-W-K 覆盖了最重要的高对称点。

---

## 4.8 输入文件一览

| 文件 | 用途 |
|------|------|
| [`inputs/si_scf.in`](inputs/si_scf.in) | SCF 自洽计算 |
| [`inputs/si_nscf.in`](inputs/si_nscf.in) | NSCF 均匀密 k 网格 |
| [`inputs/si_bands.in`](inputs/si_bands.in) | 能带计算（高对称路径） |
| [`inputs/si_bands.pp.in`](inputs/si_bands.pp.in) | bands.x 后处理 |
| [`inputs/si_dos.in`](inputs/si_dos.in) | DOS 的 NSCF 输入 |
| [`inputs/si_dos.pp.in`](inputs/si_dos.pp.in) | dos.x 态密度后处理 |
| [`inputs/si_pdos.pp.in`](inputs/si_pdos.pp.in) | projwfc.x 投影态密度 |
| [`scripts/bands_workflow.sh`](scripts/bands_workflow.sh) | 完整计算流程脚本 |

运行完整流程：`cd scripts && bash bands_workflow.sh`
