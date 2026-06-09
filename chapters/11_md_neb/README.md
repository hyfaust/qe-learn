# 第十一章：分子动力学与反应路径

## 11.1 第一性原理分子动力学概述

**第一性原理分子动力学**（AIMD）将 DFT 与牛顿力学结合，每步通过求解电子结构获得原子间力。Quantum ESPRESSO 提供两种方案：

| 方法 | 程序 | 原理 | 适用场景 |
|------|------|------|----------|
| **Born-Oppenheimer MD** | `pw.x` | 每步求解电子基态 | 通用、精度高 |
| **Car-Parrinello MD** | `cp.x` | 电子与离子同时演化 | 大体系、长时间模拟 |

---

## 11.2 Born-Oppenheimer MD（pw.x）

在 `&CONTROL` 中设置 `calculation='md'`，在 `&IONS` 中控制离子运动：

```fortran
&CONTROL
  calculation = 'md'        ! 分子动力学
  dt = 20.D0                ! 时间步长 (a.u., 约 1 fs)
  nstep = 100               ! MD 步数
/
&IONS
  pot_extrapolation = 'second-order'  ! 势外推加速 SCF
  wfc_extrapolation = 'second-order'  ! 波函数外推
  ion_temperature = 'not_controlled'  ! NVE 系综
/
```

**时间步长**：`dt=20` 约 0.97 fs；含氢体系建议 `dt=10`（约 0.5 fs）。

---

## 11.3 Car-Parrinello MD（cp.x）

### 原理

**Car-Parrinello 方法**将电子波函数视为具有虚拟质量的动力学变量，与离子同时演化，无需每步求解基态。通过选择足够小的电子虚拟质量 `emass`，保证电子绝热跟随离子。

### CPMD 关键参数

| 参数 | 含义 | 建议值 |
|------|------|--------|
| `dt` | 时间步长 (a.u.) | 3.0–8.0 |
| `emass` | 电子虚拟质量 (a.u.) | 300–800 |
| `emass_cutoff` | 质量截断 (Ry) | 2.0–3.0 |
| `electron_dynamics` | 电子运动算法 | `'verlet'` |
| `ion_dynamics` | 离子运动算法 | `'verlet'` |
| `ion_temperature` | 温度控制 | `'nose'`（Nosé-Hoover） |

```fortran
&IONS
  ion_dynamics    = 'verlet'
  ion_temperature = 'nose'
  tempw = 300.          ! 目标温度 (K)
  fnosep = 6.6666       ! 热浴频率
/
```

---

## 11.4 系综与温度控制

| 系综 | 实现方式 |
|------|----------|
| **NVE** | `ion_temperature='not_controlled'` |
| **NVT** | Nosé-Hoover：`ion_temperature='nose'` + `fnosep` |

**经验法则**：`dt` 应小于最快振动模式周期的 1/10–1/20。O-H 伸缩（~3600 cm⁻¹）需 `dt` ≤ 10 a.u.

---

## 11.5 NEB 方法

**Nudged Elastic Band（NEB）** 在反应物与产物间插入一系列中间构型（**镜像 images**），用弹簧力连接，寻找**最小能量路径**（MEP）。**Climbing Image NEB（CI-NEB）** 允许最高能量镜像"爬升"到鞍点，精确确定过渡态。

NEB 输入文件结构（注意：`neb.x` 使用 `-inp` 指定输入文件）：

```fortran
BEGIN
BEGIN_PATH_INPUT
&PATH
  string_method = 'neb'
  num_of_images = 7         ! 镜像总数（含首尾）
  nstep_path    = 20        ! 路径优化步数
  opt_scheme    = 'broyden' ! 优化方案
  k_max = 0.3, k_min = 0.2  ! 弹簧常数范围
  CI_scheme = 'auto'        ! 自动爬升镜像
  path_thr = 0.05           ! 收敛阈值
/
END_PATH_INPUT
BEGIN_ENGINE_INPUT
  ! 标准 pw.x 输入内容
BEGIN_POSITIONS
FIRST_IMAGE
  ATOMIC_POSITIONS { angstrom } ...    ! 初始构型
LAST_IMAGE
  ATOMIC_POSITIONS { angstrom } ...    ! 末态构型
END_POSITIONS
END_ENGINE_INPUT
END
```

**`path_interpolation.x`** 可在首末态间样条插值生成中间镜像，为 NEB 提供合理初始路径。

---

## 11.6 计算流程

```
结构优化 → 准备首末态 → path_interpolation.x 插值 → neb.x 运行 → 分析能垒
```
