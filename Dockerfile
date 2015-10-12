FROM golang
MAINTAINER Roman Saveljev <roman.saveljev@haltian.com>

COPY . /go/src/github.com/cross-dev/arch-repo-server

RUN CGO_ENABLED=0 go install -a -v github.com/cross-dev/arch-repo-server

RUN mkdir -p /var/lib/repos

USER nobody
WORKDIR /var/lib/repos

ENTRYPOINT ["/go/src/github.com/cross-dev/arch-repo-server/bin/entrypoint"]
