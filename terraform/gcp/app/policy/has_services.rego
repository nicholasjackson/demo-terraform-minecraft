package main

import future.keywords.if


environment := input.variables.environment.value

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
  count(minecraft_port) != 1
  msg := sprintf("there should be a public service for minecraft with a port 25565: %v",[minecraft_port])
}

deny[msg] {
  minecraft_port[0].protocol != "TCP"
  msg := sprintf("the minecraft protocol should be set to TCP: %v",[minecraft_port])
}

# if the environment is production there should be no bluemap service
# this will effectively skip the test when the environment is production
fail_bluemap_port := true if {
  environment != "prod"
  count(bluemap_port) != 1
}

deny[msg] {
  #print("environment:", check_bluemap_port)
  fail_bluemap_port
  msg := sprintf("there should be a public service for the bluemap server with a port 80 when the environment '%s' is not 'prod': %v %s",[environment, bluemap_port])
}

fail_bluemap_protocol := true if {
  environment != "prod"
  bluemap_port[0].protocol != "TCP"
}

deny[msg] {
  fail_bluemap_protocol
  msg := sprintf("the bluemap protocol should be set to TCP when the environment '%s' is not 'prod': %v",[environment, bluemap_port])
}