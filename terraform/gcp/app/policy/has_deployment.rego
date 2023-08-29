package main

deployments := [deploy |
  deploy := input.planned_values.root_module.resources[_]
  deploy.type == "kubernetes_deployment"
  deploy.name == "minecraft"
]
  

deny[msg] {
  count(deployments) != 1
  msg := sprintf("there should be a deployment called minecraft: %v",[deployments])
}

deny[msg] {
  images := [image | 
    image := deployments[_].values.spec[_].template[_].spec[_].container[_]
    image.image == "hashicraft/minecraft:v1.20.1-fabric"
  ]

  count(images) != 1

  msg := sprintf("the deployment should have a container using the minecraft image: %v",[images])
}