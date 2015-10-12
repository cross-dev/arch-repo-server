#!/usr/bin/env bats

load  ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/package.tar.xz"
tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)

setup() {
    mkdir -p ${tmpdir}/repo/os/arch/
    $GOPATH/bin/arch-repo-server -C ${tmpdir} &>/dev/null & 
}

@test 'Retrieve package added after server start' {
    tar cJf ${tmpdir}/repo/os/arch/package.tar.xz --files-from /dev/null
    run get_content_type ${url}
    [ "$status" -eq "0" ]
    [ "$output" == "application/x-xz-compressed-tar" ]
}
