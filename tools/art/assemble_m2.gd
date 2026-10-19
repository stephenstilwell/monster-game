extends SceneTree
const Stable = preload("res://tools/art/stable_resource.gd")
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/m2/manifest.json"))
	for id in ["mara", "ivo"]:
		var texture: Texture2D = load("res://assets/generated/m2/" + id + ".png")
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for name: String in manifest.animations:
			var spec: Dictionary = manifest.animations[name]
			if spec.asset != id:
				continue
			frames.add_animation(name)
			frames.set_animation_speed(name, spec.fps)
			for rect: Array in spec.rects:
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
				frames.add_frame(name, atlas)
		if Stable.save(frames, "res://assets/generated/m2/" + id + "_frames.tres") != OK:
			quit(1)
			return
	var tiles: TileSet = load("res://assets/generated/woodland_tileset.tres").duplicate(true)
	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/generated/m2/route_tiles.png")
	source.texture_region_size = Vector2i(16, 16)
	tiles.add_source(source, 1)
	for index in range(2):
		source.create_tile(Vector2i(index, 0))
		source.get_tile_data(Vector2i(index, 0), 0).set_custom_data("terrain_id", "bridge")
	if Stable.save(tiles, "res://assets/generated/m2/exploration_tileset.tres") != OK:
		quit(1)
		return
	print("M2 ASSEMBLED: 2 NPC SpriteFrames, 34-tile exploration TileSet")
	quit()
