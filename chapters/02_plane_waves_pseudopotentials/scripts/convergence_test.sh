#!/bin/bash
# ============================================================
# convergence_test.sh
# 截断能 (ecutwfc) 收敛性测试脚本
# 用法: bash convergence_test.sh [pw.x 路径]
# ============================================================

PW_CMD="${1:-pw.x}"
INPUT_DIR="$(dirname "$0")/../inputs"
OUTPUT_DIR="$(dirname "$0")/../outputs"
RESULT_FILE="${OUTPUT_DIR}/convergence.dat"

mkdir -p "${OUTPUT_DIR}"

# 定义要测试的截断能 (Ry)
ECUTS=(10 15 20 25 30)

echo "# ecutwfc (Ry)    Total Energy (Ry)" > "${RESULT_FILE}"
echo "# ----------------------------------------" >> "${RESULT_FILE}"

for ecut in "${ECUTS[@]}"; do
    INPUT_FILE="${INPUT_DIR}/si_ecut_${ecut}.in"
    OUTPUT_FILE="${OUTPUT_DIR}/si_ecut_${ecut}.out"

    if [ ! -f "${INPUT_FILE}" ]; then
        echo "警告: 找不到输入文件 ${INPUT_FILE}，跳过 ecutwfc=${ecut}"
        continue
    fi

    echo ">>> 运行 ecutwfc = ${ecut} Ry ..."
    "${PW_CMD}" < "${INPUT_FILE}" > "${OUTPUT_FILE}" 2>&1

    # 从输出中提取总能量
    ENERGY=$(grep "^!" "${OUTPUT_FILE}" | tail -1 | awk '{print $5}')

    if [ -n "${ENERGY}" ]; then
        printf "  ecutwfc = %4.1f Ry  ->  E = %s Ry\n" "${ecut}" "${ENERGY}"
        printf "  %8.1f          %s\n" "${ecut}" "${ENERGY}" >> "${RESULT_FILE}"
    else
        echo "  警告: ecutwfc=${ecut} 计算可能失败，请检查 ${OUTPUT_FILE}"
        printf "  %8.1f          FAILED\n" "${ecut}" >> "${RESULT_FILE}"
    fi
done

echo ""
echo "========================================"
echo "收敛性测试完成！结果保存在: ${RESULT_FILE}"
echo "========================================"
echo ""
cat "${RESULT_FILE}"
