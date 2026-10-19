extends SceneTree

func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/manifest.json"))
	var textures := {}
	for id: String in manifest.assets:
		if id == "font":
			continue # BMFont importer embeds this mask and marks its PNG as skipped.
		textures[id] = load("res://assets/generated/" + manifest.assets[id].file)
		if textures[id] == null:
			push_error("Import required before assembling: " + id)
			quit(1)
			return
	for group in ["player", "brindlewick", "effects"]:
		var animations := SpriteFrames.new()
		animations.remove_animation("default")
		for id: String in manifest.animations:
			var spec: Dictionary = manifest.animations[id]
			if spec.asset != group:
				continue
			animations.add_animation(id)
			animations.set_animation_speed(id, spec.fps)
			animations.set_animation_loop(id, not id.ends_with("react"))
			for rect: Array in spec.rects:
				var texture := AtlasTexture.new()
				texture.atlas = textures[group]
				texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
				animations.add_frame(id, texture)
		if save_stable(animations, "res://assets/generated/" + group + "_frames.tres") != OK:
			quit(1)
			return
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	tileset.add_physics_layer()
	for name: String in ["terrain_id", "encounter", "exposed_edges_nesw"]:
		tileset.add_custom_data_layer()
		var layer := tileset.get_custom_data_layers_count() - 1
		tileset.set_custom_data_layer_name(layer, name)
		tileset.set_custom_data_layer_type(layer, TYPE_STRING if name == "terrain_id" else (TYPE_BOOL if name == "encounter" else TYPE_INT))
	var source := TileSetAtlasSource.new()
	source.texture = textures.terrain
	source.texture_region_size = Vector2i(16, 16)
	tileset.add_source(source, 0)
	for tile: Dictionary in manifest.tiles:
		var coords := Vector2i(int(tile.id) % 8, int(tile.id) / 8)
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.set_custom_data("terrain_id", tile.terrain)
		data.set_custom_data("encounter", tile.encounter)
		data.set_custom_data("exposed_edges_nesw", tile.exposed_edges_nesw)
		if tile.collision:
			data.set_collision_polygons_count(0, 1)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	if save_stable(tileset, "res://assets/generated/woodland_tileset.tres") != OK:
		quit(1)
		return
	var panel_texture := AtlasTexture.new()
	panel_texture.atlas = textures.ui
	panel_texture.region = Rect2(0, 0, 12, 12)
	var panel := StyleBoxTexture.new()
	panel.texture = panel_texture
	for side in range(4):
		panel.set_texture_margin(side, 4)
		panel.set_content_margin(side, 6)
	var theme := Theme.new()
	theme.default_font = load("res://assets/generated/lanternwild.fnt")
	theme.default_font_size = 8
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_color("font_color", "Label", Color.html("edf0d5"))
	if save_stable(theme, "res://assets/generated/woodland_theme.tres") != OK:
		quit(1)
		return
	print("ASSEMBLED: SpriteFrames x3, TileSet with 32 collision/terrain records, bitmap-font Theme")
	quit()

func save_stable(resource: Resource, path: String) -> Error:
	var result := ResourceSaver.save(resource, path)
	if result != OK:
		return result
	# Godot assigns random serialized IDs. Canonicalize definitions AND references.
	var content := FileAccess.get_file_as_string(path)
	var regex := RegEx.new()
	regex.compile(' id="([^"]+)"')
	var matches := regex.search_all(content)
	for index in range(matches.size()):
		var old_id := matches[index].get_string(1)
		content = content.replace('"' + old_id + '"', '"@m1_temporary_%s"' % index)
	for index in range(matches.size()):
		content = content.replace('"@m1_temporary_%s"' % index, '"stable_%s"' % index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK