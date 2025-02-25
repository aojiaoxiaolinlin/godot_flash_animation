# 添加@tool可以在编辑器中运行
@tool
extends Node2D

class_name FlashAnimatiion

signal play_end

# Flash动画文件名
var file_name: String
# 用于展示的动画
var animations: Dictionary
# 所有用于展示的动画的名字
var animation_names:Array
# 所有子动画
var base_animations: Dictionary
var frame_rate: float
# 图形定位偏移变换
var shape_offset: Dictionary
var shape_texture: Dictionary

# 当前运行的MC实例
var current_movie_clip: MovieClip

# 所有子MC动画实例
var movie_clip_pool: Dictionary
# 保存已经生成的子节点，
var node_cache: Dictionary
# 记录当前帧可视节点
var visiable_node: Array

# JSON格式的动画数据
@export var animation_data: JSON:
	set(data):
		if data == null:
			for i in get_child_count():
				get_child(i).queue_free()
				node_cache.clear()
		animation_data = data
		if animation_data != null:
			parse_json()
		notify_property_list_changed()
		

@export var preview: bool
@export var use_root_transform: bool

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if animation_data == null:
		return properties

	if animation_names.size() > 0:
		properties.append({
			"name": "swf_current_animation",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(animation_names),
		})

	return properties
	
var internal_data: Dictionary = {}
func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("swf_"):
		internal_data[property] = value
		if property == "swf_current_animation" && animation_names.size() > 0:
			current_movie_clip = MovieClip.new(animations[animation_names[value]].total_frames, animations[animation_names[value]]["timelines"])
		return true
	return false

func _get(property: StringName) -> Variant:
	if(property.begins_with("swf_current")):
		return internal_data.get_or_add(property, 0)
	return null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if animation_data != null:
		parse_json()

var elapsed_time: float = 0
var current_frame: int = 0
var total_frames: int = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	if !preview:
		return
	if animations == null || current_movie_clip == null:
		return
	# 总帧数
	total_frames = current_movie_clip["total_frames"]
	## 按照帧率播放
	elapsed_time += delta
	if elapsed_time >= 1.0 / frame_rate:
		elapsed_time -= 1.0 / frame_rate
		current_frame += 1
		if current_frame >= total_frames:
			current_frame = 0
			play_end.emit()
		visiable_node.clear()
		run_frame(current_movie_clip, "Normal")
		for child in node_cache.values():
			# 全部隐藏
			if child is CanvasItem:
				child.visible = false
		var i = 0;
		for node_name in visiable_node:
			# 设置当前帧可视
			node_cache[node_name].visible = true
			# 设置z_index，重新排序
			node_cache[node_name].z_index = i
			i += 1


func parse_json():
	file_name = animation_data.data["name"]
	frame_rate = animation_data.data["frame_rate"]
	base_animations = animation_data.data["base_animations"]
	shape_offset = animation_data.data["shape_transform"]
	animations = animation_data.data["animations"]
	
	for id in shape_offset:
		var path = "res://%s.sprites/%s.tres" % [file_name, str(id)]
		shape_texture[id] = load(path)
	
	animation_names = animations.keys()
	for child in base_animations:
		var movie_clip = MovieClip.new(base_animations[child].total_frames, base_animations[child].timelines)
		movie_clip_pool[child] = movie_clip



func run_frame(movie_clip: MovieClip, blend_mode: String, filters: Array = [], parent_transform: Transform3D = Transform3D.IDENTITY, parent_mult_color: Vector4 = Vector4(1, 1, 1, 1), parent_add_color: Vector4 = Vector4(0, 0, 0, 0), parent_depth: String = "0") -> void:
	match movie_clip._deterimine_current_frame():
		MovieClip.NextFrame.Next:
			movie_clip.current_frame += 1
		MovieClip.NextFrame.First:
			movie_clip.current_frame = 1
			for key in movie_clip.depth_frame:
				movie_clip.depth_frame[key].index = 0
				movie_clip.depth_frame[key].duration = 1

	for depth in movie_clip.timelines:
		var frames: Array = movie_clip.timelines[depth]
		var depth_frame = movie_clip.depth_frame[depth]
		# 表示该时间轴已经用完
		if depth_frame.index >= frames.size():
			continue
		var frame = frames[depth_frame.index]
		if frame.place_frame > movie_clip.current_frame || (frame.place_frame + depth_frame.duration) > movie_clip.current_frame:
			continue
		if depth_frame.duration < movie_clip.total_frames:
			depth_frame.duration += 1
		if depth_frame.duration > frame.duration:
			depth_frame.index += 1
			depth_frame.duration = 1

		var matrix = frame.transform.matrix
		var current_transform: Transform3D

		# 不应用根动画的位置
		if ((current_movie_clip == movie_clip) && !use_root_transform):
			current_transform = parent_transform * Transform3D(Vector3(matrix.a, matrix.b, 0), Vector3(matrix.c, matrix.d, 0), Vector3(0, 0, 1), Vector3(0, 0, 0))
		else:
			current_transform = parent_transform * Transform3D(Vector3(matrix.a, matrix.b, 0), Vector3(matrix.c, matrix.d, 0), Vector3(0, 0, 1), Vector3(matrix.tx, matrix.ty, 0))
		var color_transform = frame.transform.color_transform
		var mult_color = Vector4(color_transform.mult_color[0], color_transform.mult_color[1], color_transform.mult_color[2], color_transform.mult_color[3])
		var current_add_color = Vector4(color_transform.add_color[0], color_transform.add_color[1], color_transform.add_color[2], color_transform.add_color[3]) + mult_color * parent_add_color
		var current_mult_color = parent_mult_color * mult_color
		
		var child_clip = movie_clip_pool.get(str(frame.id))
		var current_depth_layer = parent_depth + depth
		# 如果子动画存在，则递归调用
		if child_clip != null:
			run_frame(child_clip, frame.blend_mode, frame.filters, current_transform, current_mult_color, current_add_color)
		else:
			# 加载纹理资源
			var shader_material = ShaderMaterial.new()
			# 设置混合着色器
			shader_material.shader = get_blend_mode(blend_mode)
			# 用于抵消shape定义的偏移
			var shape_translate = shape_offset[str(frame.id)]
			if shape_translate == null:
				continue
			# 设置动画变换
			shader_material.set_shader_parameter("world_matrix", current_transform.translated_local(Vector3(shape_translate[0], shape_translate[1], 0)))
			shader_material.set_shader_parameter("mult_color", current_mult_color)
			shader_material.set_shader_parameter("add_color", current_add_color)
			
			# 设置滤镜
			var filter_mode = 0; # 1:无滤镜 2:发光滤镜 4: 模糊滤镜 8：颜色滤镜
			# 跳过目前未处理标签（DefineMorphShape）
			var texture: Texture2D = shape_texture.get(str(frame.id))
			if texture == null:
				return

			var is_processed: bool = false
			
			# 为了性能是否考虑缓存滤镜渲染结果
			for filter: Dictionary in filters:
				# TODO: 没做的滤镜都是能力有限。不会做
				# 颜色滤镜
				var color_matrix_filter = filter.get("ColorMatrixFilter")
				if color_matrix_filter != null:
					filter_mode = filter_mode + 1 << 3
					set_color_matrix(shader_material, color_matrix_filter.matrix)

			if !is_processed:
				visiable_node.append(current_depth_layer + "-" + str(frame.id))

				shader_material.set_shader_parameter("filter_mode", filter_mode)
				var res_sprite
				if node_cache.get(current_depth_layer + "-" + str(frame.id)) != null:
					res_sprite = node_cache.get(current_depth_layer + "-" + str(frame.id))
					res_sprite.material = shader_material
				else:
					res_sprite = Sprite2D.new()
					node_cache[current_depth_layer + "-" + str(frame.id)] = res_sprite
					res_sprite.texture = texture
					node_cache[current_depth_layer + "-" + str(frame.id)] = res_sprite
					add_child(res_sprite)
					res_sprite.material = shader_material


func get_blend_mode(blend_mode: String) -> Shader:
	if blend_mode == "Add":
		return preload("res://addons/flash_animation/shaders/blend/add.gdshader")
	elif blend_mode == "Lighten":
		return preload("res://addons/flash_animation/shaders/blend/lighten.gdshader")
	elif blend_mode == "Multiplay":
		return preload("res://addons/flash_animation/shaders/blend/multiply.gdshader")
	elif blend_mode == "Darken":
		return preload("res://addons/flash_animation/shaders/blend/darken.gdshader")
	elif blend_mode == "Overlay":
		return preload("res://addons/flash_animation/shaders/blend/overlay.gdshader")
	elif blend_mode == "HardLight":
		return preload("res://addons/flash_animation/shaders/blend/hardlight.gdshader")
	elif blend_mode == "Difference":
		return preload("res://addons/flash_animation/shaders/blend/difference.gdshader")
	elif blend_mode == "Alpha":
		return preload("res://addons/flash_animation/shaders/blend/alpha.gdshader")
	elif blend_mode == "Invert":
		return preload("res://addons/flash_animation/shaders/blend/invert.gdshader")
	elif blend_mode == "Erase":
		return preload("res://addons/flash_animation/shaders/blend/erase.gdshader")
	elif blend_mode == "Subtract":
		return preload("res://addons/flash_animation/shaders/blend/subtract.gdshader")
	elif blend_mode == "Screen":
		return preload("res://addons/flash_animation/shaders/blend/screen.gdshader")
	else:
		return preload("res://addons/flash_animation/shaders/blend/normal.gdshader")

func set_color_matrix(shader_material: ShaderMaterial, matrix: Array):
	shader_material.set_shader_parameter("r_to_r", matrix[0])
	shader_material.set_shader_parameter("g_to_r", matrix[1])
	shader_material.set_shader_parameter("b_to_r", matrix[2])
	shader_material.set_shader_parameter("a_to_r", matrix[3])
	shader_material.set_shader_parameter("r_extra", matrix[4])
	shader_material.set_shader_parameter("r_to_g", matrix[5])
	shader_material.set_shader_parameter("g_to_g", matrix[6])
	shader_material.set_shader_parameter("b_to_g", matrix[7])
	shader_material.set_shader_parameter("a_to_g", matrix[8])
	shader_material.set_shader_parameter("g_extra", matrix[9])
	shader_material.set_shader_parameter("r_to_b", matrix[10])
	shader_material.set_shader_parameter("g_to_b", matrix[11])
	shader_material.set_shader_parameter("b_to_b", matrix[12])
	shader_material.set_shader_parameter("a_to_b", matrix[13])
	shader_material.set_shader_parameter("b_extra", matrix[14])
	shader_material.set_shader_parameter("r_to_a", matrix[15])
	shader_material.set_shader_parameter("g_to_a", matrix[16])
	shader_material.set_shader_parameter("b_to_a", matrix[17])
	shader_material.set_shader_parameter("a_to_a", matrix[18])
	shader_material.set_shader_parameter("a_extra", matrix[19])
	
