#!/usr/bin/env bats

load  ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/package.tar.xz"

setup() {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    mkdir -p ${tmpdir}/repo/os/arch/
    tar cJf ${tmpdir}/repo/os/arch/package.tar.xz --files-from /dev/null
    arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test 'Correct MIME type in the XZ response' {
    run get_http_status ${url}
    [ "$status" -eq "0" ]
    [ "$output" == "200" ]
    run get_content_type ${url}
    [ "$status" -eq "0" ]
    [ "$output" == "application/x-xz-compressed-tar" ]
}

@test 'Archive is extractable' {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXX)
    run tar xJf <(curl -s ${url}) -C ${tmpdir}
    echo $output
    [ "$status" -eq "0" ]
}
