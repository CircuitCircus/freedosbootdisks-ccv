#!/bin/bash

#TODO: put license, desc, email, warning about osx here

DEBUG_HEXLIB="true"

SCRIPT_HOME="`dirname ${BASH_SOURCE[0]}`"

source "${SCRIPT_HOME}/hexlib.sh"

SOURCE_BOOT_DISK="${SCRIPT_HOME}/../lib/v86.freedos.boot.disk.img"
BUILD_HOME="${SCRIPT_HOME}/../build"
mkdir -p "${BUILD_HOME}"
TEST_BOOT_SECTOR="${BUILD_HOME}/test.boot.sector.img"
TEST_BOOT_DISK="${BUILD_HOME}/test.boot.disk.img"

debug_log "SOURCE_BOOT_DISK: ${SOURCE_BOOT_DISK}"
debug_log "TEST_BOOT_SECTOR: ${TEST_BOOT_SECTOR}"
debug_log "TEST_BOOT_DISK: ${TEST_BOOT_DISK}"

if [ -f "${TEST_BOOT_SECTOR}" ]; then
	rm "${TEST_BOOT_DISK}"
fi

if [ -f "${TEST_BOOT_SECTOR}" ]; then
	rm "${TEST_BOOT_SECTOR}"
fi

if [ ! -f "${SOURCE_BOOT_DISK}" ]; then
	echo "ERROR: source freedos boot disk image is missing: ${SOURCE_BOOT_DISK}"
	exit 1
fi

RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${SOURCE_BOOT_DISK}")
verify_test "Test 1.a" "512" "${RESULT}"

RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${SOURCE_BOOT_DISK}")
verify_test "Test 1.b" "1440" "${RESULT}"

# test boot sector extraction
${SCRIPT_HOME}/eddosboot.sh DEBUG COPY_BOOT_SECTOR "${SOURCE_BOOT_DISK}" "${TEST_BOOT_SECTOR}"
if [ ! -f "${TEST_BOOT_SECTOR}" ]; then
	echo "Test 2.a failure, test disk wasn't copied: ${TEST_BOOT_SECTOR}"
	exit 1
fi
echo "Test 2.a SUCCESS: test boot sector was copied."
# from: https://unix.stackexchange.com/questions/16640/how-can-i-get-the-size-of-a-file-in-a-bash-script
FILE_SIZE=$(stat -f%z "${TEST_BOOT_SECTOR}")
if [ ! "512" = "${FILE_SIZE}" ]; then
	echo "Test 2.b failure, test boot sector size isn't 512 bytes, it's: ${FILE_SIZE}"
	exit 1
fi
echo "Test 2.b SUCCESS: test boot sector is 512 bytes."
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_SECTOR}")
verify_test "Test 2.c" "512" "${RESULT}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${TEST_BOOT_SECTOR}")
verify_test "Test 2.d" "1440" "${RESULT}"

# test changing sector info on test boot sector
${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_SIZE 512 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_SECTOR}")
verify_test "Test 3.a" "512" "${RESULT}"

${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_SIZE 1024 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_SECTOR}")
verify_test "Test 3.b" "1024" "${RESULT}"

${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_SIZE 1 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_SECTOR}")
verify_test "Test 3.c" "1" "${RESULT}"

${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_SIZE 512 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_SECTOR}")
verify_test "Test 3.d" "512" "${RESULT}"

${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_SIZE 19 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_SECTOR}")
verify_test "Test 3.e" "19" "${RESULT}"

${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_COUNT 1200 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${TEST_BOOT_SECTOR}")
verify_test "Test 4.a" "1200" "${RESULT}"

${SCRIPT_HOME}/eddosboot.sh DEBUG CHANGE SECTOR_COUNT 5 "${TEST_BOOT_SECTOR}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${TEST_BOOT_SECTOR}")
verify_test "Test 4.b" "5" "${RESULT}"

# test copying boot sector
cp "${SOURCE_BOOT_DISK}" "${TEST_BOOT_DISK}"

SOURCE_FILE_SIZE=$(stat -f%z "${SOURCE_BOOT_DISK}")
TARGET_FILE_SIZE=$(stat -f%z "${TEST_BOOT_DISK}")
if [ ! "${SOURCE_FILE_SIZE}" = "${TARGET_FILE_SIZE}" ]; then
	echo "Test 5.a failure: copied file is not correct size after boot sector copy, should be: ${SOURCE_FILE_SIZE}, but is: ${TARGET_FILE_SIZE}"
	exit 1
fi
echo "Test 5.a passed: copied file is correct size."

${SCRIPT_HOME}/eddosboot.sh DEBUG COPY_BOOT_SECTOR "${TEST_BOOT_SECTOR}" "${TEST_BOOT_DISK}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_DISK}")
verify_test "Test 5.b" "19" "${RESULT}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${TEST_BOOT_DISK}")
verify_test "Test 5.c" "5" "${RESULT}"
TARGET_FILE_SIZE=$(stat -f%z "${TEST_BOOT_DISK}")
if [ ! "${SOURCE_FILE_SIZE}" = "${TARGET_FILE_SIZE}" ]; then
	echo "Test 5.d failure: copied file is not correct size after boot sector copy, should be: ${SOURCE_FILE_SIZE}, but is: ${TARGET_FILE_SIZE}"
	exit 1
fi
echo "Test 5.d passed: copied file is correct size after boot sector copy"

${SCRIPT_HOME}/eddosboot.sh DEBUG COPY_BOOT_SECTOR "${SOURCE_BOOT_DISK}" "${TEST_BOOT_DISK}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_DISK}")
verify_test "Test 6.a" "512" "${RESULT}"
RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${TEST_BOOT_DISK}")
verify_test "Test 6.b" "1440" "${RESULT}"
TARGET_FILE_SIZE=$(stat -f%z "${TEST_BOOT_DISK}")
if [ ! "${SOURCE_FILE_SIZE}" = "${TARGET_FILE_SIZE}" ]; then
	echo "Test 6.c failure: copied file is not correct size after boot sector copy, should be: ${SOURCE_FILE_SIZE}, but is: ${TARGET_FILE_SIZE}"
	exit 1
fi
echo "Test 5.a passed: copied file is correct size after boot sector copy"

# arg 1: test number
# arg 2: expected sector size
# arg 3: expected sector count
# arg 4: expected file size
check_boot_sector() {
	TEST_NUMBER="${1}"
	EXPECTED_SECTOR_SIZE="${2}"
	EXPECTED_SECTOR_COUNT="${3}"
	EXPECTED_DISK_SIZE="${4}"
	TARGET_FILE_SIZE=$(stat -f%z "${TEST_BOOT_DISK}")
	if [ ! "${EXPECTED_DISK_SIZE}" = "${TARGET_FILE_SIZE}" ]; then
		echo "Test ${TEST_NUMBER}.a failure: created file is not correct size after creation, should be: ${EXPECTED_DISK_SIZE}, but is: ${TARGET_FILE_SIZE}"
		exit 1
	fi
	echo "Test ${TEST_NUMBER}.a passed, disk is expected size: ${EXPECTED_DISK_SIZE}"
	RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_SIZE "${TEST_BOOT_DISK}")
	verify_test "Test ${TEST_NUMBER}.b" "${EXPECTED_SECTOR_SIZE}" "${RESULT}"
	RESULT=$(${SCRIPT_HOME}/eddosboot.sh DEBUG SHOW SECTOR_COUNT "${TEST_BOOT_DISK}")
	verify_test "Test ${TEST_NUMBER}.c" "${EXPECTED_SECTOR_COUNT}" "${RESULT}"
}

# arg 1: test number
# arg 2: expected sector size
# arg 3: expected sector count
check_boot_disk() { 
	check_boot_sector "${1}" "${2}" "${3}" "$(($2 * $3))"
}

# test boot disk creation

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS "${TEST_BOOT_DISK}"
check_boot_disk 7 512 2880

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS 1024 200 "${TEST_BOOT_DISK}"
check_boot_disk 8 1024 200

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS "2.8MB" "${TEST_BOOT_DISK}"
check_boot_disk 9 512 $((2880 * 2))

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS "1.4MB" "${TEST_BOOT_DISK}"
check_boot_disk 10 512 2880

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS "720K" "${TEST_BOOT_DISK}"
check_boot_disk 11 512 1440

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS "360K" "${TEST_BOOT_DISK}"
check_boot_disk 12 512 640

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_DISK FREEDOS "160K" "${TEST_BOOT_DISK}"
check_boot_disk 13 512 320

# test boot sector creation

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS "${TEST_BOOT_DISK}"
check_boot_sector 7 512 2880 512

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS 1024 200 "${TEST_BOOT_DISK}"
check_boot_sector 8 1024 200 512

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS "2.8MB" "${TEST_BOOT_DISK}"
check_boot_sector 9 512 $((2880 * 2)) 512

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS "1.4MB" "${TEST_BOOT_DISK}"
check_boot_sector 10 512 2880 512

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS "720K" "${TEST_BOOT_DISK}"
check_boot_sector 11 512 1440 512

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS "360K" "${TEST_BOOT_DISK}"
check_boot_sector 12 512 640 512

rm "${TEST_BOOT_DISK}"
${SCRIPT_HOME}/eddosboot.sh DEBUG CREATE BOOT_SECTOR FREEDOS "160K" "${TEST_BOOT_DISK}"
check_boot_sector 13 512 320 512


rm "${TEST_BOOT_SECTOR}"
rm "${TEST_BOOT_DISK}"

echo ""
echo "All Tests Passed!"

exit 0