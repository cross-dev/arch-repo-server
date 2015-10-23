#!/usr/bin/env bats

load ${BATS_TEST_DIRNAME}/lib.sh

url="http://localhost:41268/repo/os/arch/repo.db"

setup() {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    mkdir -p ${tmpdir}/repo/os/arch/
    mkdir -p ${tmpdir}/another/os/arch/
    mkdir -p ${tmpdir}/third/os/arch/
    arch-repo-server -C ${tmpdir} &>/dev/null & 
    echo $tmpdir
}

@test 'Empty database returned' {
    run get_http_status ${url}
    [ "$status" -eq "0" ]
    [ "$output" == "200" ]
    run curl -s ${url}
    [ "$status" -eq "0" ]
    [ "$output" != "" ]
}

@test 'Proper MIME returned for empty database' {
   run get_content_type ${url}
   echo $output
   [ "$status" -eq "0" ]
   [ "$output" == "application/x-gzip" ]
}

@test 'Empty database can be extracted' {
    local tmpdir=$(mktemp -d ${BATS_TMPDIR}/XXXXXXXX)
    run tar xzf <(curl -s ${url}) -C ${tmpdir}
    [ "$status" -eq "0" ]
    run find ${tmpdir} -not -path ${tmpdir}
    echo $output
    [ "$status" -eq "0" ]
    [ "$output" == "" ]
}

@test 'Database name matters' {
    run get_http_status "http://localhost:41268/repo/os/arch/repo.db"
    [ "$status" -eq "0" ]
    [ "$output" == "200" ]
    run get_http_status "http://localhost:41268/another/os/arch/another.db"
    [ "$status" -eq "0" ]
    [ "$output" == "200" ]
    run get_http_status "http://localhost:41268/third/os/arch/third.db"
    [ "$status" -eq "0" ]
    [ "$output" == "200" ]
}

