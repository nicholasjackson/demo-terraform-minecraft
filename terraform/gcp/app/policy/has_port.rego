package main

planned_resources = [res | 
  res := input.planned_values.root_module.resources[_]
  res.type == "null_resource"
]

num_planned_resources := count(planned_resources)

deny[msg] {
  not num_planned_resources == 2
  msg := "there should be 2 total null_resources"
}