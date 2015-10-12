#!/usr/bin/env bats

load ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/db.db"

setup() {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    mkdir -p ${tmpdir}/repo/os/arch/package-1.0.0-1
    echo "package-depends" >${tmpdir}/repo/os/arch/package-1.0.0-1/depends
    echo "package-desc" >${tmpdir}/repo/os/arch/package-1.0.0-1/desc
    mkdir -p ${tmpdir}/repo/os/arch/game-1.0.0-1
    echo "game-depends" >${tmpdir}/repo/os/arch/game-1.0.0-1/depends
    echo "game-desc" >${tmpdir}/repo/os/arch/game-1.0.0-1/desc
    arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test 'Good .db with few packages' {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    run tar xzf <(curl -s ${url}) -C ${tmpdir}
    [ "$status" -eq "0" ]
    run cat ${tmpdir}/package-1.0.0-1/depends
    [ "$output" == "package-depends" ]
    run cat ${tmpdir}/package-1.0.0-1/desc
    [ "$output" == "package-desc" ]
    run cat ${tmpdir}/game-1.0.0-1/depends
    [ "$output" == "game-depends" ]
    run cat ${tmpdir}/game-1.0.0-1/desc
    [ "$output" == "game-desc" ]
}
