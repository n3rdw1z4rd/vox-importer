tool
extends EditorImportPlugin

func _init():
	print('Vox Importer: ready')

func get_importer_name():
	return 'Vox.Importer'

func get_visible_name():
	return 'Vox Importer'

func get_recognized_extensions():
	return [ 'vox' ]

func get_resource_type():
	return 'Mesh'

func get_save_extension():
	return 'mesh'

func get_preset_count():
	return 0

func get_preset_name(preset):
	return 'Default'
	
func get_import_options(preset):
	return [
		{
			'name': 'Scale',
			'default_value': 0.1
		}
	]

func get_option_visibility(option, options):
	return true

func import(source_path, destination_path, options, platforms, gen_files):
	print('Vox Importer: importing ', source_path)

	var scale = 0.1
	if options.Scale:
		scale = float(options.Scale)
	print('Vox Importer: scale: ', scale)
	
	var file = File.new()
	var err = file.open(source_path, File.READ)

	if err != OK:
		if file.is_open(): file.close()
		return err
	
	var identifier = PoolByteArray([ file.get_8(), file.get_8(), file.get_8(), file.get_8() ]).get_string_from_ascii()
	var version = file.get_32()
	var voxels = {}
	var colors = null
	var sizeX = 0
	var sizeY = 0
	var sizeZ = 0

	if identifier == 'VOX ':
		while file.get_position() < file.get_len():
			var chunkId = PoolByteArray([ file.get_8(), file.get_8(), file.get_8(), file.get_8() ]).get_string_from_ascii()
			var chunkSize = file.get_32()
			var childChunks = file.get_32()

			match chunkId:
				'SIZE':
					sizeX = file.get_32()
					sizeY = file.get_32()
					sizeZ = file.get_32()
					print('size: ', sizeX, ', ', sizeY, ', ', sizeZ)
					file.get_buffer(chunkSize - 4 * 3)
				'XYZI':
					for i in range(file.get_32()):
						var x = file.get_8()
						var z = file.get_8()
						var y = file.get_8()
						var c = file.get_8()
						var voxel = Vector3(x, y, z)
						voxels[voxel] = c - 1
				'RGBA':
					colors = []
					for i in range(256):
						var r = float(file.get_8() / 255.0)
						var g = float(file.get_8() / 255.0)
						var b = float(file.get_8() / 255.0)
						var a = float(file.get_8() / 255.0)
						colors.append(Color(r, g, b, a))
				_:
						file.get_buffer(chunkSize)
		
		if voxels.size() == 0: return voxels
	file.close()

	var diffVector = Vector3(sizeX / 2, -0.5, sizeY / 2)
	print('diffVector: ', diffVector)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for voxel in voxels:
		var voxelSides = []
		if not voxels.has(Vector3(voxel.x, voxel.y + 1, voxel.z)): voxelSides += top
		if not voxels.has(Vector3(voxel.x, voxel.y - 1, voxel.z)): voxelSides += bottom
		if not voxels.has(Vector3(voxel.x - 1, voxel.y, voxel.z)): voxelSides += left
		if not voxels.has(Vector3(voxel.x + 1, voxel.y, voxel.z)): voxelSides += right
		if not voxels.has(Vector3(voxel.x, voxel.y, voxel.z + 1)): voxelSides += front
		if not voxels.has(Vector3(voxel.x, voxel.y, voxel.z - 1)): voxelSides += back
		
		st.add_color(colors[voxels[voxel]])

		for t in voxelSides:
			st.add_vertex(((t * 0.5) + voxel - diffVector) * scale)
		
	st.generate_normals()
	
	var material = SpatialMaterial.new()
	material.vertex_color_is_srgb = true
	material.vertex_color_use_as_albedo = true
	material.roughness = 1
	st.set_material(material)

	var mesh

	if file.file_exists(destination_path) and false:
		var old_mesh = ResourceLoader.load(destination_path)
		old_mesh.surface_remove(0)
		mesh = st.commit(old_mesh)
	else:
		mesh = st.commit()
	
	var full_path = "%s.%s" % [ destination_path, get_save_extension() ]
	return ResourceSaver.save(full_path, mesh)

var top = [
	Vector3( 1.0000, 1.0000, 1.0000),
	Vector3(-1.0000, 1.0000, 1.0000),
	Vector3(-1.0000, 1.0000,-1.0000),
	
	Vector3(-1.0000, 1.0000,-1.0000),
	Vector3( 1.0000, 1.0000,-1.0000),
	Vector3( 1.0000, 1.0000, 1.0000),
]

var bottom = [
	Vector3(-1.0000,-1.0000,-1.0000),
	Vector3(-1.0000,-1.0000, 1.0000),
	Vector3( 1.0000,-1.0000, 1.0000),
	
	Vector3( 1.0000, -1.0000, 1.0000),
	Vector3( 1.0000, -1.0000,-1.0000),
	Vector3(-1.0000, -1.0000,-1.0000),
]

var front = [
	Vector3(-1.0000, 1.0000, 1.0000),
	Vector3( 1.0000, 1.0000, 1.0000),
	Vector3( 1.0000,-1.0000, 1.0000),
	
	Vector3( 1.0000,-1.0000, 1.0000),
	Vector3(-1.0000,-1.0000, 1.0000),
	Vector3(-1.0000, 1.0000, 1.0000),
]

var back = [
	Vector3( 1.0000,-1.0000,-1.0000),
	Vector3( 1.0000, 1.0000,-1.0000),
	Vector3(-1.0000, 1.0000,-1.0000),
	
	Vector3(-1.0000, 1.0000,-1.0000),
	Vector3(-1.0000,-1.0000,-1.0000),
	Vector3( 1.0000,-1.0000,-1.0000)
]

var left = [
	Vector3(-1.0000, 1.0000, 1.0000),
	Vector3(-1.0000,-1.0000, 1.0000),
	Vector3(-1.0000,-1.0000,-1.0000),
	
	Vector3(-1.0000,-1.0000,-1.0000),
	Vector3(-1.0000, 1.0000,-1.0000),
	Vector3(-1.0000, 1.0000, 1.0000),
]

var right = [
	Vector3( 1.0000, 1.0000, 1.0000),
	Vector3( 1.0000, 1.0000,-1.0000),
	Vector3( 1.0000,-1.0000,-1.0000),
	
	Vector3( 1.0000,-1.0000,-1.0000),
	Vector3( 1.0000,-1.0000, 1.0000),
	Vector3( 1.0000, 1.0000, 1.0000),
]