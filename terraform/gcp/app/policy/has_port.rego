package main

services := [serv |
  serv := input.planned_values.root_module.resources[_]
  serv.type == "kubernetes_service"
]

minecraft_port := [port |
    port := services[_].values.spec[_].port[_]
    port.port == 25565
]

deny[msg] {
  count(minecraft_port) != 1
  msg := sprintf("there should be a public service with a port 25565: %v",[minecraft_port])
}

deny[msg] {
  minecraft_port[0].protocol != "TCP"
  msg := sprintf("the protocol should be set to TCP: %v",[minecraft_port])
}