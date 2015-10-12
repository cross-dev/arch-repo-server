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

## Use

``` shell
Usage: arch-repo-server [options]
  -C string
    Change working directory before executing (default ".")
  -l string
    Interface and port to listen at (default ":41268")
```
