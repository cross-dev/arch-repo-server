#!/usr/bin/env bats

load  ${BATS_TEST_DIRNAME}/lib.sh

setup() {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    mkdir -p ${tmpdir}/repo/os/arch/
    arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test '404 to just repo name' {
    run get_http_status "http://localhost:41268/repo"
    [ "$status" -eq "0" ]
    [ "$output" == "404" ]
}

@test '404 to just repo/os name' {
    run get_http_status "http://localhost:41268/repo/os"
    [ "$status" -eq "0" ]
    [ "$output" == "404" ]
}

@test '404 to just repo/os/arch name' {
    run get_http_status "http://localhost:41268/repo/os/arch"
    [ "$status" -eq "0" ]
    [ "$output" == "404" ]
}
