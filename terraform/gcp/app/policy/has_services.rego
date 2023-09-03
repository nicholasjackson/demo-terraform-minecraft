package main

environment := input.planned_values.variables.environment.value

services := [serv |
  serv := input.planned_values.root_module.resources[_]
  serv.type == "kubernetes_service"
]

minecraft_port := [port |
    port := services[_].values.spec[_].port[_]
    port.port == 25565
]

bluemap_port := [port |
    port := services[_].values.spec[_].port[_]
    port.port == 80
]

deny[msg] {
  msg := sprintf("there should be a public service for minecraft with a port 25565: %v",[minecraft_port])
}

deny[msg] {
  minecraft_port[0].protocol != "TCP"
  msg := sprintf("the minecraft protocol should be set to TCP: %v",[minecraft_port])
}

# bluemap should only be created when not production
deny[msg] {
  # if there are not exactly 1 bluemap services and the environment is not production, fail
  # this test will be skipped when the environment is production
  count(minecraft_port) != 1 and environment == "production"
  msg := sprintf("there should be a public service for the bluemap server with a port 80: %v",[bluemap_port])
}

deny[msg] {
  count(minecraft_port) != 1 and environment == "production"

  bluemap_port[0].protocol != "TCP"
  msg := sprintf("the bluemap protocol should be set to TCP: %v",[bluemap_port_port])
}