#!/bin/bash

DATE=$(date +%d_%m_%Y_%H_%M_%S)
REG_DIR="regression_${DATE}"

TESTNAME="int_base_test"
RUNS=3000

COV_WORK="cov_work"
MERGED_COV="${REG_DIR}/coverage/merged/merged_cov"

mkdir -p ${REG_DIR}/compile
mkdir -p ${REG_DIR}/logs
mkdir -p ${REG_DIR}/reports
mkdir -p ${REG_DIR}/coverage/merged
mkdir -p ${REG_DIR}/coverage/text

SUMMARY=${REG_DIR}/reports/regression_summary.txt
CSV=${REG_DIR}/reports/regression.csv

PASS=0
FAIL=0

echo "RUN,SEED,STATUS,UVM_ERROR,UVM_FATAL,PASS_COUNT,FAIL_COUNT" > ${CSV}

rm -rf xcelium.d
rm -rf ${COV_WORK}

echo "=================================================="
echo "              COMPILATION START"
echo "=================================================="

xrun -sv -uvm \
    -access +rwc \
    -f compile.f \
    -coverage all \
    -covwork ${COV_WORK} \
    -elaborate \
    -l ${REG_DIR}/compile/compile.log

if [ $? -ne 0 ]; then
    echo "COMPILE FAILED"
    exit 1
fi

echo "COMPILE PASSED"

for ((i=1;i<=RUNS;i++))
do
    RUN_DIR=${REG_DIR}/logs/run_${i}
    mkdir -p ${RUN_DIR}

    SEED=$RANDOM

    echo "=================================================="
    echo "RUN  : ${i}"
    echo "SEED : ${SEED}"
    echo "=================================================="

    xrun -R \
        +svseed=${SEED} \
        +UVM_TESTNAME=${TESTNAME} \
        -coverage all \
        -covwork ${COV_WORK} \
        -covtest run_${i}_seed_${SEED} \
        -l ${RUN_DIR}/run.log \
        > ${RUN_DIR}/console.log 2>&1

    UVM_ERROR=$(grep "UVM_ERROR :" ${RUN_DIR}/run.log | tail -1 | awk '{print $3}')
    UVM_FATAL=$(grep "UVM_FATAL :" ${RUN_DIR}/run.log | tail -1 | awk '{print $3}')
    PASS_COUNT=$(grep "PASS_COUNT" ${RUN_DIR}/run.log | tail -1 | awk '{print $3}')
    FAIL_COUNT=$(grep "FAIL_COUNT" ${RUN_DIR}/run.log | tail -1 | awk '{print $3}')

    UVM_ERROR=${UVM_ERROR:-999}
    UVM_FATAL=${UVM_FATAL:-999}
    PASS_COUNT=${PASS_COUNT:-0}
    FAIL_COUNT=${FAIL_COUNT:-999}

    if [[ "${UVM_ERROR}" == "0" && "${UVM_FATAL}" == "0" && "${FAIL_COUNT}" == "0" ]]
    then
        STATUS="PASS"
        PASS=$((PASS+1))
        echo "RUN ${i} PASSED"
    else
        STATUS="FAIL"
        FAIL=$((FAIL+1))
        echo "RUN ${i} FAILED"
    fi

    echo "${i},${SEED},${STATUS},${UVM_ERROR},${UVM_FATAL},${PASS_COUNT},${FAIL_COUNT}" >> ${CSV}
done

echo "=================================================="
echo "              COVERAGE MERGE START"
echo "=================================================="

imc -execcmd "merge -overwrite -out ${MERGED_COV} ${COV_WORK}/scope/run_*; load ${MERGED_COV}; exit"

if [ ! -d "${MERGED_COV}" ]; then
    echo "COVERAGE MERGE FAILED"
    exit 1
fi

echo "COVERAGE MERGE PASSED"

echo "=================================================="
echo "              COVERAGE REPORT START"
echo "=================================================="

imc -execcmd "load ${MERGED_COV}; report_metrics -out ${REG_DIR}/coverage/html_report -overwrite; exit"

if [ -f "${REG_DIR}/coverage/text/coverage_metrics.txt" ]; then
    echo "TEXT COVERAGE REPORT GENERATED"
else
    echo "TEXT COVERAGE REPORT NOT GENERATED"
fi

{
echo ""
echo "=================================================="
echo "              REGRESSION SUMMARY"
echo "=================================================="
echo "TESTNAME        : ${TESTNAME}"
echo "TOTAL RUNS      : ${RUNS}"
echo "PASS COUNT      : ${PASS}"
echo "FAIL COUNT      : ${FAIL}"
echo ""
echo "CSV REPORT      : ${CSV}"
echo "SUMMARY REPORT  : ${SUMMARY}"
echo "MERGED COVERAGE : ${MERGED_COV}"
echo "TEXT COVERAGE   : ${REG_DIR}/coverage/text/coverage_metrics.txt"
echo "=================================================="
} | tee ${SUMMARY}

echo ""
echo "Regression completed"
echo "Results directory: ${REG_DIR}"
echo ""
echo "Open coverage GUI:"
echo "imc -load ${MERGED_COV} &"

echo ""
echo "Opening Coverage Report..."

firefox ${REG_DIR}/coverage/html_report/index.html &
