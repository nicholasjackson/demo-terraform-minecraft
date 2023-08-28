tar_mods:
	tar -C $(shell pwd)/local_mods -czf mods.tar.gz ./

tar_world:
	tar -C $(shell pwd)/world -czf ./world.tar.gz ./

run_local:
	docker run \
		--rm \
		-d \
		-it \
		-e "MODS_BACKUP=https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"	\
		-e "GAME_MODE=creative" \
		-e "WHITELIST_ENABLED=false" \
		-e "RCON_ENABLED=true" \
		-e "RCON_PASSWORD=password" \
		-v $(shell pwd)/world:/minecraft/world \
		-p 25565:25565 \
		-p 9090:9090 \
		hashicraft/minecraft:v1.20.1-fabric
