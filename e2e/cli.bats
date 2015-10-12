#!/usr/bin/env bats

@test 'Understands -h' {
    run $GOPATH/bin/arch-repo-server -h
    [ "$status" -ne "0" ]
    [ "$output" != "" ]
}

@test 'Understands -C and errors on wrong destination folder' {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXX)
    rmdir ${tmpdir}
    run $GOPATH/bin/arch-repo-server -C ${tmpdir}
    [ "$status" -ne "0" ]
}

@test 'Understands -l and errors on wrong port' {
    run $GOPATH/bin/arch-repo-server -l ':80'
    [ "$status" -ne "0" ]
}
