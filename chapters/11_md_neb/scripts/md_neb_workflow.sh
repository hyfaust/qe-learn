#!/bin/bash
# ============================================================
#  第十一章：分子动力学与 NEB 计算工作流
#  用法: bash md_neb_workflow.sh
# ============================================================

set -e

# ---- 环境变量（根据实际安装路径修改）----
QE_DIR=${QE_DIR:-"$HOME/qe-7.0"}
BIN_DIR="$QE_DIR/bin"
PSEUDO_DIR="./pseudo"
TMP_DIR="./tmp"

PW="$BIN_DIR/pw.x"
CP="$BIN_DIR/cp.x"
NEB="$BIN_DIR/neb.x"
INTERP="$BIN_DIR/path_interpolation.x"

mkdir -p "$TMP_DIR" "$PSEUDO_DIR"

echo "============================================"
echo "  第十一章：分子动力学与 NEB 计算演示"
echo "============================================"

# ============================================================
#  第一部分：Born-Oppenheimer MD（水分子）
# ============================================================
echo ""
echo ">>> [1/4] 运行水分子 Born-Oppenheimer MD ..."
echo "    pw.x, calculation='md', dt=20, nstep=100"

"$PW" -inp ../inputs/h2o_bo_md.in > h2o_bo_md.out

echo "    完成！输出文件: h2o_bo_md.out"
echo "    提取动力学数据:"
grep -A 50 "Dynamics" h2o_bo_md.out | grep -E "(Ekin|Etot|Dynamics)" | head -20

# 清理临时文件
rm -rf "$TMP_DIR"/pwscf*

# ============================================================
#  第二部分：Car-Parrinello MD（硅晶体）
# ============================================================
echo ""
echo ">>> [2/4] 运行 Si Car-Parrinello MD ..."
echo "    cp.x, emass=400, dt=5.0, NVT (Nosé-Hoover, 300K)"

"$CP" -inp ../inputs/si_cpmd.in > si_cpmd.out

echo "    完成！输出文件: si_cpmd.out"
echo "    检查电子绝热性:"
grep -E "(ELECTRON|ION)" si_cpmd.out | tail -10

# 清理临时文件
rm -rf "$TMP_DIR"/cp*

# ============================================================
#  第三部分：NEB 过渡态搜索（水分子构型变化）
# ============================================================
echo ""
echo ">>> [3/4] 运行水分子 NEB 过渡态搜索 ..."
echo "    neb.x, 7 个镜像, CI-NEB (auto)"

# 注意：neb.x 使用 -inp 参数指定输入文件，不从标准输入读取
"$NEB" -inp ../inputs/h2o_neb.in > h2o_neb.out

echo "    完成！输出文件: h2o_neb.out"
echo "    提取路径能量:"
grep "image" h2o_neb.out | tail -10

# 清理临时文件
rm -rf "$TMP_DIR"/pwscf*

# ============================================================
#  第四部分：路径插值（可选）
# ============================================================
echo ""
echo ">>> [4/4] 路径插值生成中间镜像 ..."
echo "    path_interpolation.x: 2 个旧镜像 -> 7 个新镜像"

# 需要先有 h2o_neb.path 文件（由 NEB 计算生成）
if [ -f "h2o_neb.path" ]; then
    "$INTERP" < ../inputs/neb_path.in > path_interp.out
    echo "    完成！输出文件: path_interp.out"
    echo "    新路径文件: h2o_neb_interp.path"
else
    echo "    跳过：未找到 h2o_neb.path 文件"
    echo "    请先完成 NEB 计算（步骤 3）"
fi

# ============================================================
#  结果汇总
# ============================================================
echo ""
echo "============================================"
echo "  计算完成！输出文件一览："
echo "============================================"
echo "  h2o_bo_md.out   — BOMD 结果"
echo "  si_cpmd.out     — CPMD 结果"
echo "  h2o_neb.out     — NEB 过渡态搜索结果"
echo "  path_interp.out — 路径插值结果"
echo ""
echo "  常用分析命令："
echo "  # 提取 BOMD 温度轨迹:"
echo "  grep 'temperature' h2o_bo_md.out"
echo ""
echo "  # 提取 NEB 各镜像能量:"
echo "  grep 'e           =' h2o_neb.out"
echo ""
echo "  # 提取过渡态能垒:"
echo "  grep 'activation energy' h2o_neb.out"
echo "============================================"
