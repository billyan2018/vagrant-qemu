# Vagrant Qemu Provider

This is a [Vagrant](http://www.vagrantup.com) 2.5+ plugin that adds a
qemu provider to Vagrant, allowing Vagrant to control and provision
machines using qemu.

## Install
First make sure `qemu` works in your environment.
If qemu is not installed yet,
```
brew install qemu
```

It is optional, but we strongly suggest installing [qemu-virgl](https://github.com/knazarov/homebrew-qemu-virgl)
to enable graphical acceleration:
```
brew install knazarov/qemu-virgl/qemu-virgl
```

## Demo

### Run a sample
Only tested on m1 macbook:
```shell
vagrant init billyan2018/devbox \
  --box-version 0.1.0
vagrant up --provider="qemu"
```

