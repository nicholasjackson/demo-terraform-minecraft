tar_mods:
	tar -C $(shell pwd)/local_mods -czf mods.tar.gz ./

tar_world:
	tar -C $(shell pwd)/world -czf ./world.tar.gz ./

build_image:
	cd Docker && docker build -t hashicraft/minecraftservice:v0.0.2 .

run_local:
	docker run \
		--rm \
		-d \
		-it \
		--name minecraft \
		-e "MODS_BACKUP=https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"	\
		-e "GAME_MODE=creative" \
		-e "WHITELIST_ENABLED=false" \
		-e "RCON_ENABLED=true" \
		-e "RCON_PASSWORD=password" \
		-e "SPAWN_ANIMALS=true" \
		-e "SPAWN_NPCS=true" \
		-v $(shell pwd)/world:/minecraft/world \
		-v $(shell pwd)/config/banned-ips.json:/minecraft/config/banned-ips.json \
		-v $(shell pwd)/config/banned-players.json:/minecraft/config/banned-players.json \
		-v $(shell pwd)/config/bukkit.yml:/minecraft/config/bukkit.yml \
		-v $(shell pwd)/config/ops.json:/minecraft/config/ops.json \
		-v $(shell pwd)/config/usercache.json:/minecraft/config/usercache.json \
		-v $(shell pwd)/config/whitelist.json:/minecraft/config/whitelist.json \
		-v $(shell pwd)/config/core.conf:/minecraft/config/bluemap/core.conf \
		-v $(shell pwd)/config/overworld.conf:/minecraft/config/bluemap/maps/overworld.conf \
		-v $(shell pwd)/config/end.conf:/minecraft/config/bluemap/maps/end.conf \
		-v $(shell pwd)/config/nether.conf:/minecraft/config/bluemap/maps/nether.conf \
		-p 25565:25565 \
		-p 9090:9090 \
		-p 8100:8100 \
		hashicraft/minecraft:v1.20.1-fabric

stop_local:
	docker stop minecraft

run_conftest:
	cd ./terraform/gcp/app && \
	tfc-plan --out app-plan.json && \
	conftest test ./app-plan.json

terraform_app:
	cp ./config/* ./terraform/gcp/app/config/
	cd ./terraform/gcp/app && \
		terraform plan