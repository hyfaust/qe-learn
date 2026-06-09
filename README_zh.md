# Quantum ESPRESSO DFT 教程

[English](README.md) | [简体中文](README_zh.md)

---

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Quantum ESPRESSO](https://img.shields.io/badge/Quantum%20ESPRESSO-v7.0-brightgreen.svg)](https://www.quantum-espresso.org/)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-%E5%9C%A8%E7%BA%BF%E6%BC%94%E7%A4%BA-orange.svg)](https://hyfaust.xyz/qe-learn/)

> 一套渐进式、动手实践的教程系列，帮助你使用 Quantum ESPRESSO 学习密度泛函理论（DFT）——从第一次 SCF 计算到高级的声子、光谱和分子动力学模拟。

**🌐 在线站点：** [https://hyfaust.xyz/qe-learn/](https://hyfaust.xyz/qe-learn/)

## 目录

- [简介](#简介)
- [章节内容](#章节内容)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [构建网站](#构建网站)
- [参与贡献](#参与贡献)
- [许可证](#许可证)
- [致谢](#致谢)

## 简介

本项目提供了一套结构化的 12 章教程，用于使用 **Quantum ESPRESSO** 学习计算材料科学。Quantum ESPRESSO 是最广泛使用的开源平面波 DFT 代码之一。每一章包括：

- **详细的 Markdown 文档**，解释关键概念、输入参数和物理原理
- **经过测试的输入文件**（`.in`），可直接使用 `pw.x`、`ph.x`、`bands.x`、`dos.x`、`projwfc.x`、`dynmat.x`、`q2r.x`、`matdyn.x`、`epsilon.x`、`hp.x`、`cp.x` 和 `neb.x` 运行
- **自动化脚本**（`.sh`、`.py`），用于收敛性测试和工作流执行

所有 59 个输入文件均已通过本地 Quantum ESPRESSO v7.0 安装验证。

## 章节内容

| # | 章节 | 主题 | 难度 |
|---|------|------|:----:|
| 01 | [QE 基础与 DFT 理论](chapters/01_qe_basics/) | Hohenberg-Kohn、Kohn-Sham 方程、输入文件结构、第一次 SCF | ⭐ |
| 02 | [平面波与赝势](chapters/02_plane_waves_pseudopotentials/) | 平面波基组、ecutwfc 收敛性、NC/USPP/PAW | ⭐ |
| 03 | [k 点采样](chapters/03_k_sampling/) | 布里渊区、Monkhorst-Pack 网格、k 点收敛性 | ⭐ |
| 04 | [能带结构与态密度](chapters/04_bands_and_dos/) | NSCF、高对称路径、态密度、投影态密度 | ⭐⭐ |
| 05 | [金属体系](chapters/05_metallic_systems/) | 展宽方法、费米面、Al 和 Cu | ⭐⭐ |
| 06 | [结构优化](chapters/06_structural_optimization/) | Hellmann-Feynman 力、BFGS、变胞弛豫 | ⭐⭐⭐ |
| 07 | [磁性](chapters/07_magnetism/) | 自旋极化 DFT、铁磁/反铁磁 NiO、Fe | ⭐⭐⭐ |
| 08 | [声子基础](chapters/08_phonon_basics/) | DFPT、ph.x、声子色散、动力学矩阵 | ⭐⭐⭐⭐ |
| 09 | [介电性质与光谱](chapters/09_dielectric_spectroscopy/) | 介电常数、Born 有效电荷、IR/Raman、epsilon.x | ⭐⭐⭐⭐ |
| 10 | [高级泛函](chapters/10_advanced_functionals/) | DFT+U、van der Waals（DFT-D3）、杂化泛函 HSE06 | ⭐⭐⭐⭐ |
| 11 | [分子动力学与反应路径](chapters/11_md_neb/) | Born-Oppenheimer MD、Car-Parrinello MD、NEB | ⭐⭐⭐⭐⭐ |
| 12 | [自动化综合实战](chapters/12_automation_capstone/) | 完整的 SiC 表征工作流、Python 自动化 | ⭐⭐⭐⭐⭐ |

## 前置要求

| 依赖项 | 版本 | 说明 |
|--------|------|------|
| [Quantum ESPRESSO](https://www.quantum-espresso.org/) | >= 7.0 | 核心 DFT 引擎（`pw.x`、`ph.x` 等） |
| Python | >= 3.8 | 用于 `build_web.py` 和自动化脚本 |
| Bash | >= 4.0 | 用于工作流脚本 |
| [matplotlib](https://matplotlib.org/) | >= 3.5 | 可选 — 用于绘制收敛性图 |

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/hyfaust/qe-learn.git
cd qe-learn

# 运行第一个示例（需要将 QE 添加到 PATH）
cd chapters/01_qe_basics
mkdir -p tmp
pw.x -in inputs/si_scf.in > si_scf.out

# 检查结果
grep "JOB DONE" si_scf.out
grep "total energy" si_scf.out
```

## 项目结构

```
qe-learn/
├── index.html              # 网站入口
├── styles.css              # 网站样式
├── app.js                  # 网站客户端逻辑
├── build_web.py            # Markdown → HTML 构建脚本
├── site/                   # 预构建的 HTML 页面（12 章）
│   ├── 01.html … 12.html
├── chapters/               # 教程源码（Markdown + 示例）
│   ├── 01_qe_basics/
│   │   ├── README.md       # 章节文档
│   │   ├── inputs/         # QE 输入文件（.in）
│   │   └── scripts/        # 自动化脚本
│   ├── 02_plane_waves_pseudopotentials/
│   │   └── ...
│   └── ...（共 12 章）
├── .gitignore
└── LICENSE
```

## 构建网站

交互式网站由各章 Markdown 文件构建而成：

```bash
# 安装 markdown 库（可选 — 内置备用转换器）
pip install markdown

# 生成 HTML 页面
python3 build_web.py

# 本地启动服务
python3 -m http.server 8888 --bind 0.0.0.0
# 打开 http://localhost:8888
```

网站功能包括：
- 深色/浅色主题切换
- 章节导航与进度跟踪
- 语法高亮代码块
- KaTeX 数学公式渲染（支持 LaTeX 公式）
- 所有输入文件和脚本的直接下载链接

## 参与贡献

欢迎贡献！请按以下步骤操作：

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/my-addition`）
3. 使用本地 QE 安装测试所有新增输入文件
4. 确保 `python3 build_web.py` 运行无误
5. 提交 Pull Request

## 许可证

本项目基于 **GNU 通用公共许可证 v3.0** 发布 — 详见 [LICENSE](LICENSE) 文件。

## 致谢

- [Quantum ESPRESSO](https://www.quantum-espresso.org/) — 本教程所基于的开源 DFT 套件
- P. Giannozzi et al., *J. Phys.: Condens. Matter* **21**, 395502 (2009); **29**, 465901 (2017)
- [赝势下载页面](https://www.quantum-espresso.org/pseudopotentials/)
