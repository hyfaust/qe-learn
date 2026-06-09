#!/bin/bash
# ============================================================
# phonon_workflow.sh
# 完整声子色散计算流程：Si (diamond structure)
# 用法: bash phonon_workflow.sh [pw.x] [ph.x] [q2r.x] [matdyn.x] [dynmat.x]
# ============================================================

PW_CMD="${1:-pw.x}"
PH_CMD="${2:-ph.x}"
Q2R_CMD="${3:-q2r.x}"
MATDYN_CMD="${4:-matdyn.x}"
DYNMAT_CMD="${5:-dynmat.x}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT_DIR="${SCRIPT_DIR}/../inputs"
OUTPUT_DIR="${SCRIPT_DIR}/../outputs"

mkdir -p "${OUTPUT_DIR}/tmp"

echo "============================================"
echo " 声子计算流程: Si (diamond)"
echo "============================================"
echo ""

# ----------------------------------------------------------
# Step 1: SCF 自洽计算
# ----------------------------------------------------------
echo ">>> Step 1: SCF 自洽计算 (pw.x) ..."
"${PW_CMD}" < "${INPUT_DIR}/si_scf.in" > "${OUTPUT_DIR}/si_scf.out" 2>&1
if [ $? -ne 0 ]; then
    echo "错误: SCF 计算失败，请查看 ${OUTPUT_DIR}/si_scf.out"
    exit 1
fi
# 提取总能量
ENERGY=$(grep "^!" "${OUTPUT_DIR}/si_scf.out" | tail -1 | awk '{print $5}')
echo "    SCF 总能量: ${ENERGY} Ry"
echo ""

# ----------------------------------------------------------
# Step 2a: Gamma 点声子计算
# ----------------------------------------------------------
echo ">>> Step 2a: Gamma 点声子计算 (ph.x) ..."
cp -r "${OUTPUT_DIR}/tmp" "${OUTPUT_DIR}/tmp_backup_gamma"
"${PH_CMD}" < "${INPUT_DIR}/si_ph_gamma.in" > "${OUTPUT_DIR}/si_ph_gamma.out" 2>&1
if [ $? -ne 0 ]; then
    echo "错误: Gamma 点声子计算失败，请查看 ${OUTPUT_DIR}/si_ph_gamma.out"
    exit 1
fi
# 提取 Gamma 点声子频率
echo "    Gamma 点声子频率:"
grep "freq" "${OUTPUT_DIR}/si_ph_gamma.out" | grep -v "THz" | head -6
echo ""

# ----------------------------------------------------------
# Step 2b: X 点声子计算
#   注意: ph.x 会覆盖波函数，需要重新进行 SCF 或使用备份
# ----------------------------------------------------------
echo ">>> Step 2b: 重新进行 SCF (恢复波函数) ..."
rm -rf "${OUTPUT_DIR}/tmp"
cp -r "${OUTPUT_DIR}/tmp_backup_gamma" "${OUTPUT_DIR}/tmp"
"${PW_CMD}" < "${INPUT_DIR}/si_scf.in" > "${OUTPUT_DIR}/si_scf_restart.out" 2>&1
if [ $? -ne 0 ]; then
    echo "错误: SCF 重启失败"
    exit 1
fi

echo ">>> Step 2b: X 点声子计算 (ph.x) ..."
"${PH_CMD}" < "${INPUT_DIR}/si_ph_x.in" > "${OUTPUT_DIR}/si_ph_x.out" 2>&1
if [ $? -ne 0 ]; then
    echo "错误: X 点声子计算失败，请查看 ${OUTPUT_DIR}/si_ph_x.out"
    exit 1
fi
echo "    X 点声子频率:"
grep "freq" "${OUTPUT_DIR}/si_ph_x.out" | grep -v "THz" | head -6
echo ""

# ----------------------------------------------------------
# Step 3: q2r.x — 傅里叶逆变换得到实空间力常数
# ----------------------------------------------------------
echo ">>> Step 3: q2r.x 傅里叶逆变换 ..."
cd "${OUTPUT_DIR}"
# 生成 q2r.x 所需的文件列表（需根据实际 fildyn 命名调整）
# 对于完整色散计算，需要在 ldisp=.true. 模式下运行 ph.x，
# 这里演示单 q 点计算，q2r 需要所有 q 点的动力学矩阵文件。
# 实际使用中建议用 ldisp=.true. 一次性计算所有 q 点。
if [ -f "si.dynG" ] && [ -f "si.dynX" ]; then
    cat > si_q2r_input.in << EOF
&input
    fildyn = 'si.dyn',
    flfrc = 'si.fc',
    zasr = 'simple',
/
EOF
    echo "    (注意: 完整色散计算需使用 ldisp=.true. 模式)"
    echo "    (此处为演示目的，实际运行可能需要更多 q 点)"
    # "${Q2R_CMD}" < si_q2r_input.in > si_q2r.out 2>&1
    echo "    q2r.x 输入已生成: ${OUTPUT_DIR}/si_q2r_input.in"
else
    echo "    警告: 未找到所有动力学矩阵文件，跳过 q2r.x"
fi
echo ""

# ----------------------------------------------------------
# Step 4: matdyn.x — 计算声子色散曲线
# ----------------------------------------------------------
echo ">>> Step 4: matdyn.x 色散曲线计算 ..."
if [ -f "${OUTPUT_DIR}/si.fc" ]; then
    "${MATDYN_CMD}" < "${INPUT_DIR}/si_matdyn.in" > "${OUTPUT_DIR}/si_matdyn.out" 2>&1
    if [ $? -ne 0 ]; then
        echo "错误: matdyn.x 计算失败"
        exit 1
    fi
    echo "    色散数据已保存: ${OUTPUT_DIR}/si.freq"
else
    echo "    跳过: 需要先完成 q2r.x 得到力常数文件"
fi
echo ""

# ----------------------------------------------------------
# Step 5: dynmat.x — Gamma 点振动模式分析
# ----------------------------------------------------------
echo ">>> Step 5: dynmat.x Gamma 点模式分析 ..."
if [ -f "${OUTPUT_DIR}/si.dynG" ]; then
    cp "${OUTPUT_DIR}/si.dynG" "${OUTPUT_DIR}/"
    "${DYNMAT_CMD}" < "${INPUT_DIR}/si_dynmat.in" > "${OUTPUT_DIR}/si_dynmat.out" 2>&1
    if [ $? -ne 0 ]; then
        echo "警告: dynmat.x 分析失败"
    else
        echo "    Gamma 点模式分析完成"
        echo "    振动模式可视化文件: ${OUTPUT_DIR}/dynmat.axsf"
    fi
else
    echo "    跳过: 未找到 si.dynG 文件"
fi
echo ""

# ----------------------------------------------------------
# 清理临时文件
# ----------------------------------------------------------
echo ">>> 清理临时文件 ..."
rm -rf "${OUTPUT_DIR}/tmp" "${OUTPUT_DIR}/tmp_backup_gamma"

echo "============================================"
echo " 声子计算流程完成！"
echo "============================================"
echo ""
echo "输出文件列表:"
ls -la "${OUTPUT_DIR}"/*.out 2>/dev/null
echo ""
echo "提示: 完整的声子色散计算建议使用 ldisp=.true. 模式，"
echo "      在 &INPUTPH 中设置 nq1, nq2, nq3 指定 q 点网格，"
echo "      一次性计算所有不等价 q 点的动力学矩阵。"
