[![Build Status](http://52.19.90.102/api/badges/cross-dev/arch-repo-server/status.svg)](http://52.19.90.102/cross-dev/arch-repo-server)

This project is a part of ArchLinux package CI/CD solution.

It is assumed that package builders are concurrent and simply publish the binary
packages wherever is configured. A package builder owns its package and there is
no need for resource locking. However, the `.db` file (which `pacman` reads for
available package metadata) is shared and has to be remade every time a binary
package is pushed.

We wanted to avoid complicated architecture, achieve the best decoupling and
abstraction. The following components are distinguished in the design:

* *Package builders* - dedicated sandboxes, which create ArchLinux packages
* *Storage backend* - builders upload packages there and server downloads for clients
* *Database server* - downloads binary packages for clients and generates the database

And these are the challenges:

1. Package builders are concurrent and there is no exclusive access for `.db`
implemented
2. `repo-add` is easier to use under ArchLinux
3. Database server should not depend on the backend storage technology

To tackle (1) there will be no persistent `.db` file and the database server will
generate it on the fly whenever it is requested. To overcome (2) the inputs for
`.db` file should be built, when the package is built and uploaded. For (3) we
hide backend access behind FUSE mount, so the database server thinks it reads from
a local filesystem (which it might very well be).

## Install

Have a working Go environment and:

``` shell
$ go get github.com/cross-dev/arch-repo-server
```

Otherwise, you can simply pull [crossdev/arch-repo-server](https://hub.docker.com/r/crossdev/arch-repo-server/)

## Use

Docker image and either run the application containerized or download statically linked executable or install it
under the host path. Lets get started..

### Get the image

Aside of [numerous](https://docs.docker.com/linux/step_one/) Docker installation instructions for all your Linux
flavours, this is what you do:

```
$ docker pull crossdev/arch-repo-server
```

### Run the application

```
$ docker run --rm crossdev/arch-repo-server -h
Usage: arch-repo-server [options]
  -C string
        Change working directory before executing (default ".")
  -l string
        Interface and port to listen at (default ":41268")
```

### Download the application

```
$ docker run --rm crossdev/arch-repo-server download >arch-repo-server
$ chmod +x arch-repo-server
$ ./arch-repo-server -h
Usage: arch-repo-server [options]
  -C string
        Change working directory before executing (default ".")
  -l string
        Interface and port to listen at (default ":41268")
```

### Install under the host path

```
$ docker run --rm -v /usr/local/bin:/host crossdev/arch-repo-server install
$ which arch-repo-server
/usr/local/bin/arch-repo-server
```

### Run dockerized application

```
docker run -d \
    -v /opt/arch-repos:/var/lib/repos:ro \
    --restart=always \
    -p 8000:41268 \
    crossdev/arch-repo-server
```

In this example all the repositories the application will serve are under `/var/lib/repos`. This
is a host-side mounted volume and the possibilities how they can be made visible there are endless.
These are just few options:

* Use [S3 storage driver](https://docs.docker.com/registry/storage-drivers/s3/)
* Map it from the host file system and populate it through FTP, rsync, SSH, btsync etc. from another container
* Use [S3 FUSE module](https://github.com/s3fs-fuse/s3fs-fuse) and manage security credentials and mounting in
the host

### Command line interface

The server is configured for base folder and for listening `interface:port`. For dockerized usecase you stick
with defaults and configure the container itself. For standalone usage you pass it some flags:

```
Usage: arch-repo-server [options]
  -C string
        Change working directory before executing (default ".")
  -l string
        Interface and port to listen at (default ":41268")
```

## Development

There is a CI pipeline triggered for every commit. If the CI build (and test) is OK, then image build is triggered in
the Docker Hub. So, by pulling the `crossdev/arch-repo-server` image from the public registry, you can be confident
the embedded executable has passed the tests.

The CI system employed, [drone](https://github.com/drone/drone), is currently in its infancy. So, this project.
