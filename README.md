
# 🚀 Announcing packages.redbeardlab.com a public CVMFS repository for common software

Roughly ~10 years ago, CERN had a software problem.

How to distribute the big software stack necessary to analyze and simulate collision data to ~100 datacenter around the world?
How to do it while minimizing bandwidth? And how to do it while maximizing performance?

The standard answer to these questions today would be containers. 
However, 10 years ago containers technology was in its infancy.
Moreover, distributing containers images is rather expensive in terms of bandwidth and so in terms of startup time.

The solution to this problem for CERN was CernVM-FileSystem or CVMFS for short.

CVMFS is a FUSE filesystem, that features lazy-loading, extremely cacheable and developed to distribution of software.
The distribution happens over standard HTTP, that allow to leverage the existing infrastructure for caching.

Software is installed once on a single source of truth storage machines and it is distributed to (potentially) millions of clients who access it from a read-only filesystem.
On the client side, CVMFS exposes a read-only, POSIX, filesystem.

Up to now, CVMFS was deployed mainly in private installation inside big HPC centers.

Today we are announcing **packages.redbeardlab.com**

A public CVMFS installation that includes common Linux utilities and basic software.

We include:

1. basic linux utilities (binutils, coreutils, bash, zsh, tar)
1. a humble selection of compilers (gcc 9, clang 11, go 1.15, rustc 1.45)
1. interpreters (python 3.9, python 2.7, lua 5.3)
1. software for development (git, automake, cmake, autoconf, autogen, bison, flex) 
1. databases (postgres, mysql, redis)
1. editors (neovim, emacs)
1. common linux utilities (curl, htop, iotop, jq, lua, ripgrep, time, tmux, wget, zip)


Other software can be installed on request, over email simone@redbeardlab.com or over twitter [@redbeardlab][tw]

## CVMFS Tradeoffs

The main use case of CVMFS is for latency insensitive workload, it works out of the box for CI scripts, or for running long-lasting servers.

Running a service from CVMFS is usually faster than installing the packages from repository and the running it.

What CVMFS is not well suited for is interactive use case. If you need to invoke bash, then awk, then grep, then python, then ruby, then jq, etc, etc... waiting in front of the terminal, then CVMFS will be look slow.

Unless the data is already in the local cache, in such case the performance difference is negligible with the respect of  the local filesystem.

Good news is that CVMFS automatically manages a local LRU cache.

When a file is downloaded from the CVMFS Server, it is automatically stored in the local filesystem, when the same file is requested again, the local copy is used. 

This makes CVMFS usable for interactive use cases as well, at the cost of waiting a little the first time a new file is accessed.

## Suggested use cases

packages.redbeardlab.com targets **developers use cases**.

There are different ways in which the CVMFS repository can be used.

### Enhancing local workstations

The suggestion would be to put `/cvmfs/packages.redbeardlab.com/bin` at the end of the $PATH in local workstations.

This will not disturb the local workflow, but it will provide all the software installed on packages.redbeardlab.com on-demand.

It can be very useful when you want to try software without actually installing it.

Sometimes it is necessary to quickly run some application, either you can pull down a docker container or invoke it from /cvmfs/packages.redbeardlab.com

Very often this is the case for compilers. Need to test your software on different compilers or different compilers versions? Just invoke a different compiler.

Similarly, for different interpreters. Do you need to quickly test your application in python 3.8 and python 3.9? Just invoke the correct one.

### CI/CD

The first and time-consuming steps of most CI is about installing all the necessary dependency for building and testing your application.

If all the dependency were available on `/cvmfs/packages.redbeardlab.com` this step would be superfluous.

### Long Running Servers

It can make sense to deploy also long running services on top of CVMFS. This is especially true if it is necessary to spin up a cluster of several machines, all with the same software.

While these are all valid use cases, at the moment, we will focus on the enhancing local workstations use case.

## Installation

In order to get started, is necessary to install the CVMFS client and to setup it correctly.

The CVMFS client can be found on the official homepage: [cernvm.cern.ch/fs](https://cernvm.cern.ch/fs) 

It is possible to install it either as DEB or RPM package.

All the configuration can be found on this tarbal. And it can be installed with:

```bash
curl -o - | sudo tar -x - /
```

To check that everything works, `cvmfs_config probe` should return OK.

As an alternative it is possible to run the CVMFS client inside a docker container and expose the `/cvmfs` mount point to the host.

docker run -it


## Using the software installed

Once CVMFS is running, the last step is to actually use the software installed.

The simplest thing to set up a working system is to invoke:

```bash
$ source /cvmfs/packages.redbeardlab.com/setup.sh
```

This will append to your $PATH the location of the software installed in `/cvmfs/packages.redbeardlab.com`

## Getting help

The fastest way to get help is over twitter [@redbeardlab][tw] or via email simone@redbeardlab.com

In alternative, it is possible to open an issue with this github repo. 

## Requesting software

It is possible to add software to `/cvmfs/packages.redbeardlab.com`, this will allow everybody to use it and benefit from it.

In order to request a new software to be installed, please ask through the standard communication channels, twitter [@redbeardlab][tw] and email simone@redbeardlab.com 

## Technical Background

While we are running the infrastructure, the complexity behind this project is huge. It was possible to tame all this complexity only thanks to very solid software and with the help of very solid internet business.

Definitely a big thanks to CERN and CVMFS, that has developed software of outstanding quality.

A big thanks to the *Nix project* that allow us to simply bootstrap a complete software stack (from the compilers up to k8s) in a reasonably quick and simple way.

Then, we are using *backblaze* and their S3 API to store all the data managed by CVMFS.

Finally, we are exploiting the bandwidth, reliability and diffusion of *BunnyCDN* to quickly distribute the software around the globe.

## Business Services

DO NOT rely on this for business critical needs. Please, get in touch, if your business need a similar solution.

[tw]: https://twitter.com/redbeardlab
