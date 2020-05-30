package main

import (
	kvm "github.com/49nord/docker-machine-kvm"
	"github.com/docker/machine/libmachine/drivers/plugin"
)

func main() {
	plugin.RegisterDriver(kvm.NewDriver("default", "path"))
}
