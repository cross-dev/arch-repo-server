#!/usr/bin/env bats

load ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/db.db"
tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)

setup() {
    mkdir -p ${tmpdir}/repo/os/arch/package-1.0.0-1
    echo "package-depends" >${tmpdir}/repo/os/arch/package-1.0.0-1/depends
    echo "package-desc" >${tmpdir}/repo/os/arch/package-1.0.0-1/desc
    mkdir -p ${tmpdir}/repo/os/arch/game-1.0.0-1
    echo "game-depends" >${tmpdir}/repo/os/arch/game-1.0.0-1/depends
    echo "game-desc" >${tmpdir}/repo/os/arch/game-1.0.0-1/desc
    arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test 'Include to .db files added after server start' {
    mkdir -p ${tmpdir}/repo/os/arch/package-1.0.0-1
    echo "package-depends" >${tmpdir}/repo/os/arch/package-1.0.0-1/depends
    echo "package-desc" >${tmpdir}/repo/os/arch/package-1.0.0-1/desc
    local destdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    run tar xzf <(curl -s ${url}) -C ${destdir}
    [ "$status" -eq "0" ]
    run cat ${destdir}/package-1.0.0-1/depends
    [ "$output" == "package-depends" ]
    run cat ${destdir}/package-1.0.0-1/desc
    [ "$output" == "package-desc" ]
}
