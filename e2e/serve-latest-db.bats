#!/usr/bin/env bats

load ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/db.db"

setup() {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    mkdir -p ${tmpdir}/repo/os/arch/package-1.0.2-1
    echo "old" >${tmpdir}/repo/os/arch/package-1.0.2-1/depends
    echo "old" >${tmpdir}/repo/os/arch/package-1.0.2-1/desc
    sleep 0.5
    mkdir -p ${tmpdir}/repo/os/arch/package-1.0.0-1
    echo "new" >${tmpdir}/repo/os/arch/package-1.0.0-1/depends
    echo "new" >${tmpdir}/repo/os/arch/package-1.0.0-1/desc
    mkdir -p ${tmpdir}/repo/os/arch/package-a-1.0.0-1
    echo "new" >${tmpdir}/repo/os/arch/package-a-1.0.0-1/depends
    echo "new" >${tmpdir}/repo/os/arch/package-a-1.0.0-1/desc
    arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test 'Packages included to .db by age' {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    echo $tmpdir
    run tar xzf <(curl -s ${url}) -C ${tmpdir}
    [ "$status" -eq "0" ]
    [ -d "${tmpdir}/package-1.0.0-1" ]
    [ ! -d "${tmpdir}/package-1.0.2-1" ]
    [ -d "${tmpdir}/package-a-1.0.0-1" ]
}
