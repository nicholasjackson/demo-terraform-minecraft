tar_mods:
	tar -C $(shell pwd)/local_mods -czf mods.tar.gz ./

tar_world:
	tar -C $(shell pwd)/world -czf ./terraform/gcp/app/world.tar.gz ./

run_local:
	docker run \
		--rm \
		-it \
		-e "MODS_BACKUP=https://github.com/nicholasjackson/demo-terraform-minecraft/releases/download/mods/mods.tar.gz"	\
		-e "GAME_MODE=creative" \
		-e "WHITELIST_ENABLED=false" \
		-v $(shell pwd)/world:/minecraft/world \
		-p 25565:25565 \
		hashicraft/minecraft:v1.20.1-fabric
