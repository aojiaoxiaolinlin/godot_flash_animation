@tool
extends Node2D

class_name SwfAnimation

signal play_end

@export var animation_data: JSON:
	set(data):
		animation_data = data
		notify_property_list_changed()
		

@export var preview: bool

var current_movie_clip: MovieClip
var animations: Dictionary
var base_animations: Dictionary
var shape_transform: Dictionary
var shape_texture: Dictionary
var animation_name: String
var animation_names: Array = []
var frame_rate: float
# 所有子MC动画实例
var movie_clip_pool: Dictionary


const base_transform: Vector2 = Vector2(685.5, 255)

func _ready() -> void:
	if animation_data != null:
		parse()


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if animation_data == null:
		return properties
	else:
		parse()

	if animation_names.size() > 0:
		#pass
		properties.append({
			"name": "swf_current_animation",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(animation_names),
		})

	return properties

var elapsed_time: float = 0
var current_frame: int = 0
var total_frames: int = 0
var internal_data: Dictionary = {}


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("swf_"):
		internal_data[property] = value
		if property == "swf_current_animation" && animation_names.size() > 0:
			current_movie_clip = MovieClip.new(animations[animation_names[value]].total_frames, animations[animation_names[value]]["timelines"])
		return true
	return false

func _get(property: StringName) -> Variant:
	if property.begins_with("swf_"):
		return internal_data.get_or_add(property, 0)
	return null

func _process(delta: float) -> void:
	# TODO: 动画播放
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
		# 删除所有子节点 TODO: 优化 用可见性控制
		for child in get_children():
			child.queue_free()
		run_frame(current_movie_clip, "Normal")


func run_frame(movie_clip: MovieClip, blend_mode: String, filters: Array = [], parent_transform: Transform3D = Transform3D.IDENTITY, parent_mult_color: Vector4 = Vector4(1, 1, 1, 1), parent_add_color: Vector4 = Vector4(0, 0, 0, 0)) -> void:
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
		var current_transform
		# 不应用根的变换，TODO:是否有其他更好的方法
		if (current_movie_clip == movie_clip):
			current_transform = parent_transform * Transform3D(Vector3(matrix.a, matrix.b, 0), Vector3(matrix.c, matrix.d, 0), Vector3(0, 0, 1), Vector3(0, 0, 0))
		else:
			current_transform = parent_transform * Transform3D(Vector3(matrix.a, matrix.b, 0), Vector3(matrix.c, matrix.d, 0), Vector3(0, 0, 1), Vector3(matrix.tx, matrix.ty, 0))
		var color_transform = frame.transform.color_transform
		var mult_color = Vector4(color_transform.mult_color[0], color_transform.mult_color[1], color_transform.mult_color[2], color_transform.mult_color[3])
		var current_add_color = Vector4(color_transform.add_color[0], color_transform.add_color[1], color_transform.add_color[2], color_transform.add_color[3]) + mult_color * parent_add_color
		var current_mult_color = parent_mult_color * mult_color
		
		var child_clip = movie_clip_pool.get(str(frame.id))
		# 如果子动画存在，则递归调用
		if child_clip != null:
			run_frame(child_clip, frame.blend_mode, frame.filters, current_transform, current_mult_color, current_add_color)
		else:
			# 加载纹理资源
			var shader_material = ShaderMaterial.new()
			# 设置混合着色器
			shader_material.shader = get_blend_mode(blend_mode)
			
			# 设置滤镜
			var filter_mode = 0; # 1:无滤镜 2:发光滤镜
			# 跳过目前未处理标签（DefineMorphShape）
			var texture: Texture2D = shape_texture.get(str(frame.id))
			if texture == null:
				return
			var res_sprite = Sprite2D.new()
			for filter: Dictionary in filters:
				var glow = filter.get("GlowFilter")
				if glow != null:
					filter_mode = 1 << 1
					var color = glow.color
					var blur_x = glow.blur_x
					var blur_y = glow.blur_y
					var strength = glow.strength
					var flags: int = glow.flags
					shader_material.set_shader_parameter("glow_color", Color(color[0], color[1], color[2], color[3]))
					shader_material.set_shader_parameter("glow_strength", strength)
					shader_material.set_shader_parameter("glow_inner", 1 if flags & (1 << 7) != 0 else 0)
					shader_material.set_shader_parameter("glow_knockout", 1 if flags & (1 << 6) != 0 else 0)
					shader_material.set_shader_parameter("glow_composite_source", 1 if flags & (1 << 5) != 0 else 0)

					# 模糊
					filter_mode = (1 << 0) + filter_mode
					var blur_flags = (flags & 0b11111) << 3
					shader_material.set_shader_parameter("blur_x", blur_x);
					shader_material.set_shader_parameter("blur_y", blur_y);
			
			shader_material.set_shader_parameter("filter_mode", filter_mode)

			var shape_translate = shape_transform[str(frame.id)]
			shader_material.set_shader_parameter("world_matrix", current_transform.translated_local(Vector3(shape_translate[0], shape_translate[1], 0)))
			shader_material.set_shader_parameter("mult_color", current_mult_color)
			shader_material.set_shader_parameter("add_color", current_add_color)
			res_sprite.texture = texture
			res_sprite.material = shader_material
			add_child(res_sprite)

func get_blend_mode(blend_mode: String) -> Shader:
	if blend_mode == "Add":
		return preload("res://addons/swf/shaders/blend/add.gdshader")
	elif blend_mode == "Lighten":
		return preload("res://addons/swf/shaders/blend/lighten.gdshader")
	elif blend_mode == "Multiplay":
		return preload("res://addons/swf/shaders/blend/multiply.gdshader")
	elif blend_mode == "Darken":
		return preload("res://addons/swf/shaders/blend/darken.gdshader")
	elif blend_mode == "Overlay":
		return preload("res://addons/swf/shaders/blend/overlay.gdshader")
	elif blend_mode == "HardLight":
		return preload("res://addons/swf/shaders/blend/hardlight.gdshader")
	elif blend_mode == "Difference":
		return preload("res://addons/swf/shaders/blend/difference.gdshader")
	elif blend_mode == "Alpha":
		return preload("res://addons/swf/shaders/blend/alpha.gdshader")
	elif blend_mode == "Invert":
		return preload("res://addons/swf/shaders/blend/invert.gdshader")
	elif blend_mode == "Erase":
		return preload("res://addons/swf/shaders/blend/erase.gdshader")
	elif blend_mode == "Subtract":
		return preload("res://addons/swf/shaders/blend/subtract.gdshader")
	elif blend_mode == "Screen":
		return preload("res://addons/swf/shaders/blend/screen.gdshader")
	else:
		return preload("res://addons/swf/shaders/blend/normal.gdshader")

func parse():
	animation_name = animation_data.data["name"]
	frame_rate = animation_data.data["frame_rate"]
	base_animations = animation_data.data["base_animations"]
	shape_transform = animation_data.data["shape_transform"]
	animations = animation_data.data["animations"]
	
	for id in shape_transform:
		var path = "res://%s.sprites/%s.tres" % [animation_name, str(id)]
		shape_texture[id] = load(path)
	animation_names = animation_data.data["animations"].keys()
	for child in base_animations:
		var movie_clip = MovieClip.new(base_animations[child].total_frames, base_animations[child].timelines)
		movie_clip_pool[child] = movie_clip


func set_animation(name: String):
	preview = true
	current_movie_clip = MovieClip.new(animations[name].total_frames, animations[name].timelines)
