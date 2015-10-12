#!/usr/bin/env bats

load ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/db.db"

setup() {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    mkdir -p ${tmpdir}/repo/os/arch/package-1.0.0-1
    echo "skip" >${tmpdir}/repo/os/arch/package-1.0.0-1/depends
    echo "skip" >${tmpdir}/repo/os/arch/package-1.0.0-1/dezc
    mkdir -p ${tmpdir}/repo/os/arch/game-1.0.0-1
    echo "include" >${tmpdir}/repo/os/arch/game-1.0.0-1/depends
    echo "include" >${tmpdir}/repo/os/arch/game-1.0.0-1/desc
    arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test 'Does not include to .db, if no depends file' {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    run tar xzf <(curl -s ${url}) -C ${tmpdir}
    [ ! -e ${tmpdir}/package-1.0.0-1 ]
    run cat ${tmpdir}/game-1.0.0-1/depends
    [ "$output" == "include" ]
    run cat ${tmpdir}/game-1.0.0-1/desc
    [ "$output" == "include" ]
}

