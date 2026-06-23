@tool
extends Resource


class_name CellProperties

enum CellRenderMode {
	FILL,
	BORDER,
	BOTH
}

@export var render_mode : CellRenderMode = CellRenderMode.FILL :
	set(value):
		render_mode = value
		notify_property_list_changed()
		if _source_node:
			_source_node.queue_redraw()


@export_color_no_alpha var color : Color = Color.DARK_RED :
	set(value):
		color = value
		if _source_node:
			_source_node.queue_redraw()

@export var border_color : Color = Color.WHITE :
	set(value):
		border_color = value
		if _source_node:
			_source_node.queue_redraw()

@export_range(1.0, 64.0, 1.0, "suffix:px", "or_greater") var border_width : float = 2.0 :
	set(value):
		border_width = value
		if _source_node:
			_source_node.queue_redraw()

@export_group("Label", "label_")

@export var label_text : String = "" :
	set(value):
		label_text = value
		if _source_node:
			_source_node.queue_redraw()

@export var label_show : bool = true :
	set(value):
		label_show = value
		if _source_node:
			_source_node.queue_redraw()

## The font used to render the labels.
@export var label_font_file: Font = preload("fonts/Inconsolata/static/Inconsolata_SemiCondensed-Medium.ttf"):
	set(value):
		label_font_file = value
		if _source_node:
			_source_node.queue_redraw()

## The color of the label_text text.
## Also acts as the primary color when [member fill_checkerboard] is [code]true[/code].
@export var label_font_color := Color(1,1,1,0.75):
	set(value):
		label_font_color = value
		if _source_node:
			_source_node.queue_redraw()

## The font size of the labels.
@export_range(1.0, 128.0, 1.0, "suffix:px") var label_font_size: float = 16.0:
	set(value):
		label_font_size = value
		if _source_node:
			_source_node.queue_redraw()


var _source_node : Node2D = null

func _validate_property(property: Dictionary) -> void:
	match property.name:
		"color":
			if render_mode == CellRenderMode.BORDER:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"border_width","border_color":
			if render_mode == CellRenderMode.FILL:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		

func draw_cell(position: Vector2i, size: Vector2i, source: Node2D) -> void:
	_source_node = source
	match render_mode:
		CellRenderMode.FILL:
			source.draw_rect(Rect2(position,size),color,true,-1.0,false)
		CellRenderMode.BORDER:
			source.draw_rect(Rect2(position,size),border_color,false,border_width,false)
		CellRenderMode.BOTH:
			source.draw_rect(Rect2(position,size),color,true,-1.0,false)
			source.draw_rect(Rect2(position,size),border_color,false,border_width,false)
	if label_show and not label_text.is_empty():
		var ascent : float = label_font_file.get_ascent(label_font_size)
		var descent : float = label_font_file.get_descent(label_font_size)

		var half_cell_size : Vector2i = size / 2.0
		
		var cell_center_local_position : Vector2 = position + half_cell_size
		
		var label_size_combined : Vector2 = label_font_file.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size)
		
		var center_x_pos : float = cell_center_local_position.x - label_size_combined.x / 2.0
		var baseline_y : float = cell_center_local_position.y + (ascent - descent) / 2.0

		var text_position := Vector2(center_x_pos, baseline_y)


		source.draw_string(label_font_file, text_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size, label_font_color)
