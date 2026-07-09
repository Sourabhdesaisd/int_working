#!/bin/bash

# ============================================================
# ZIC PROFESSIONAL REGRESSION SCRIPT
# ============================================================

DATE=$(date +%d_%m_%Y_%H_%M_%S)

REG_DIR="regression_${DATE}"

mkdir -p ${REG_DIR}

# ============================================================
# USER CONFIG
# ============================================================


TESTNAME="int_base_test"
RUNS=10

# ============================================================
# COMPILE STEP
# ============================================================

echo ""
echo "=================================================="
echo "                COMPILATION START"
echo "=================================================="

xrun -sv -uvm \
-access +rwc \
-f compile.f \
-l ${REG_DIR}/compile.log

if [ $? -ne 0 ]; then
    echo ""
    echo "COMPILE FAILED"
    exit 1
fi

echo ""
echo "COMPILE PASSED"
echo ""

# ============================================================
# REPORT FILES
# ============================================================

SUMMARY=${REG_DIR}/regression_summary.txt
CSV=${REG_DIR}/regression.csv

touch ${SUMMARY}

echo "RUN,SEED,STATUS,UVM_ERROR,UVM_FATAL,PASS_COUNT,FAIL_COUNT" > ${CSV}

PASS=0
FAIL=0

# ============================================================
# RUN REGRESSION
# ============================================================

for ((i=1;i<=RUNS;i++))
do

    RUN_DIR=${REG_DIR}/run_${i}

    mkdir -p ${RUN_DIR}

    SEED=$RANDOM

    echo ""
    echo "=================================================="
    echo "RUN  : $i"
    echo "SEED : $SEED"
    echo "=================================================="

    xrun -R \
    -sv -uvm \
    +svseed=${SEED} \
    +UVM_TESTNAME=${TESTNAME} \
    -access +rwc \
    -l ${RUN_DIR}/run.log \
    > ${RUN_DIR}/console.log 2>&1

    # ========================================================
    # PARSE LOG
    # ========================================================

    UVM_ERROR=$(grep "UVM_ERROR :" ${RUN_DIR}/run.log | tail -1 | awk '{print $3}')
    UVM_FATAL=$(grep "UVM_FATAL :" ${RUN_DIR}/run.log | tail -1 | awk '{print $3}')

    PASS_COUNT=$(grep "PASS_COUNT" ${RUN_DIR}/run.log | awk '{print $3}')
    FAIL_COUNT=$(grep "FAIL_COUNT" ${RUN_DIR}/run.log | awk '{print $3}')

    if [[ "${UVM_ERROR}" == "0" && \
          "${UVM_FATAL}" == "0" && \
          "${FAIL_COUNT}" == "0" ]]
    then

        STATUS="PASS"

        echo "RUN ${i} PASSED"

        PASS=$((PASS+1))

    else

        STATUS="FAIL"

        echo "RUN ${i} FAILED"

        FAIL=$((FAIL+1))

    fi

    echo "${i},${SEED},${STATUS},${UVM_ERROR},${UVM_FATAL},${PASS_COUNT},${FAIL_COUNT}" >> ${CSV}

done

# ============================================================
# FINAL SUMMARY
# ============================================================

echo ""                                              >> ${SUMMARY}
echo "==================================================" >> ${SUMMARY}
echo "              REGRESSION SUMMARY"                >> ${SUMMARY}
echo "==================================================" >> ${SUMMARY}
echo "TOTAL RUNS : ${RUNS}"                           >> ${SUMMARY}
echo "PASS COUNT : ${PASS}"                           >> ${SUMMARY}
echo "FAIL COUNT : ${FAIL}"                           >> ${SUMMARY}
echo "==================================================" >> ${SUMMARY}

cat ${SUMMARY}

echo ""
echo "Regression completed"
echo "Results : ${REG_DIR}"
