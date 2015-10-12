teardown() {
    killall arch-repo-server
}

get_http_status() {
    curl -s -o /dev/null -w "%{http_code}" "$@"
}

get_content_type() {
    curl -s -o /dev/null -w "%{content_type}" "$@"
}
