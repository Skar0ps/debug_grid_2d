@icon("debug_grid_2d.svg")
@tool
## A tool for drawing a customizable 2D grid for debugging purposes.
##
## This node renders a configurable grid that can be used to visualize coordinate systems, align actors, or debug grid-based logic.
##[br][br]
## The grid features two sizing modes: [member grid_mode] can be set to [code]GRID_MODE.SCREEN[/code] to automatically cover the viewport,
## or [code]GRID_MODE.CUSTOM[/code] to define a fixed area.
##[br][br]
## The grid appearance is highly customizable, supporting subdivisions,
## checkerboard backgrounds, borders, origin markers, and coordinate labels.
class_name DebugGrid2D

extends Node2D

## The editor blue color (Node2D)
const FLAT_BLUE : Color = Color("#8da5f3")

## The editor red color (Spatial)
const SPATIAL_RED : Color = Color("#fc7f7f")

## The editor green color (Control)
const CONTROL_GREEN : Color =  Color("#8eef97")

@export_group("Grid","grid_")

## If [code]true[/code], the grid is drawn.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var grid_draw : bool = true:
	set(value):
		if grid_draw == value: return
		grid_draw = value
		notify_property_list_changed()
		queue_redraw()

## The mode used to determine the grid's dimensions.
enum GRID_MODE {
	INFINITE, ## The grid will only draw the cells viewable in the current viewport while seemingly not moving.
	CUSTOM ## Manually define the number of cells.
}

## The mode used to determine the grid's dimensions.
@export var grid_mode : GRID_MODE = GRID_MODE.CUSTOM:
	set(value):
		if grid_mode == value: return
		grid_mode = value
		
		notify_property_list_changed()
		queue_redraw()


## Number of cells, horizontally and vertically, using x/y values respectively
@export_custom(PROPERTY_HINT_LINK, "suffix:cell(s)") var grid_cell_count := Vector2i(2,2):
	set(value):
		grid_cell_count = value.maxi(1)
		queue_redraw()


## The size of a single cell in pixels.
@export_custom(PROPERTY_HINT_LINK, "suffix:px") var grid_cell_size := Vector2i(64, 64):
	set(value):
		grid_cell_size = value.maxi(2)
		queue_redraw()
		notify_property_list_changed()

## The total size of the grid in pixels (border excluded).
@export var grid_size : Vector2i = Vector2i.ZERO:
	get:
		return grid_cell_count * grid_cell_size

@export_subgroup("Grid Lines","grid_line")

## If [code]true[/code], the grid lines are drawn.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var grid_line_enabled : bool = true:
	set(value):
		grid_line_enabled = value

		if grid_line_enabled:
			# we cannot see the antialiasing of the filled cells if the lines are visible, so we turn it off
			fill_antialiased = false

		notify_property_list_changed()
		queue_redraw()


## The line thickness of the main grid.
@export_range(1.0, 64.0, 1.0, "suffix:px") var grid_line_thickness : float = 1.0:
	set(value):
		grid_line_thickness = value
		queue_redraw()

## If [code]true[/code], allows setting different colors for vertical and horizontal lines.
@export var grid_line_decouple_axis_colors := false:
	set(value):
		grid_line_decouple_axis_colors = value
		notify_property_list_changed()
		queue_redraw()

## The color of the grid lines. Used when [member grid_line_decouple_axis_colors] is [code]false[/code].
@export var grid_line_color := CONTROL_GREEN:
	set(value):
		grid_line_color = value
		queue_redraw()

## Color of the vertical lines.
@export var grid_line_vertical_color := CONTROL_GREEN:
	set(value):
		grid_line_vertical_color = value
		queue_redraw()

## Color of the horizontal lines.
@export var grid_line_horizontal_color := SPATIAL_RED:
	set(value):
		grid_line_horizontal_color = value
		queue_redraw()

## If [code]true[/code], grid lines are drawn with antialiasing.
@export var grid_line_antialiased : bool = false :
	set(value):
		grid_line_antialiased = value
		queue_redraw()

@export_subgroup("Grid Subdivision","subdivision_")

## If [code]true[/code], draws subdivision lines within the grid. [br]
## Subdivision works by replacing the standard grid lines with differently sized and colored lines at regular intervals.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var subdivision_enabled : bool = true:
	set(value):
		if subdivision_enabled == value: return
		subdivision_enabled = value
		if Engine.is_editor_hint() and subdivision_enabled and subdivision_line_thickness == 1.0:
			subdivision_line_thickness = grid_line_thickness * 2.0
		notify_property_list_changed()
		queue_redraw()

## The number of cells between each subdivision line.
@export_range(2, 20, 1, "suffix:step(s)","or_greater") var subdivision_steps : int = 2:
	set(value):
		subdivision_steps = value
		queue_redraw()

## The thickness of the subdivision lines in pixels.
@export_range(1.0, 64.0, 1.0, "suffix:px") var subdivision_line_thickness : float = 1.0:
	set(value):
		subdivision_line_thickness = value
		queue_redraw()

## The color of the subdivision lines.
@export var subdivision_line_color := FLAT_BLUE:
	set(value):
		subdivision_line_color = value
		queue_redraw()

@export_group("Fill", "fill_")

## If [code]true[/code], fills the grid cells with color.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var fill_enabled : bool = false:
	set(value):
		if fill_enabled == value: return
		fill_enabled = value
		notify_property_list_changed()
		queue_redraw()

## If [code]true[/code], applies a checkerboard pattern using primary and secondary colors.
@export var fill_checkerboard : bool = false:
	set(value):
		fill_checkerboard = value
		notify_property_list_changed()
		queue_redraw()

## The color used to fill the grid when checkerboard is disabled.
@export var fill_color : Color = Color(0.0, 0.0, 0.0, 0.67):
	set(value):
		fill_color = value
		queue_redraw()

## The second color of the checkerboard pattern.
@export var fill_secondary_color : Color = Color(0.0, 0.0, 0.0, 0.34):
	set(value):
		fill_secondary_color = value
		queue_redraw()

## If [code]true[/code], the fill is drawn with antialiasing.
@export var fill_antialiased : bool = false :
	set(value):
		fill_antialiased = value
		queue_redraw()

@export_group("Border","border_")

## The positioning mode for the border relative to the grid rect.
enum BORDER_MODE {
	INBETWEEN , ## Draws the grid borders exactly on the border of the grid rect.
	INSIDE, ## Draws the grid borders inside the grid rect.
	OUTSIDE, ## Draws the grid borders outside the grid rect.
}

## Enables drawing of the border around the grid.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var border_draw : bool = true:
	set(value):
		if border_draw == value: return
		border_draw = value
		if border_draw == false and Engine.is_editor_hint():
			border_thickness = grid_line_thickness/2.0
		notify_property_list_changed()
		queue_redraw()

## Determines whether the border should be drawn behind the grid or in front.
@export var border_draw_behind : bool = false :
	set(value):
		border_draw_behind = value
		queue_redraw()
		notify_property_list_changed()

## The positioning mode for the border relative to the grid rect.
@export var border_draw_mode := BORDER_MODE.INBETWEEN:
	set(value):
		border_draw_mode = value
		queue_redraw()

## The thickness of the border in pixels.
@export_range(1.0, 32.0, 1.0, "suffix:px","or_greater") var border_thickness : float = 2.0:
	set(value):
		border_thickness = value
		queue_redraw()

## The color of the border.
@export var border_color := FLAT_BLUE:
	set(value):
		border_color = value
		queue_redraw()

## If [code]true[/code], the border is drawn with antialiasing.
@export var border_antialiased : bool = false :
	set(value):
		border_antialiased = value
		queue_redraw()

@export_group("Origin","origin_")
## If [code]true[/code], draws a marker at the origin (0,0) of the grid.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var origin_draw : bool = true:
	set(value):
		if origin_draw == value: return
		origin_draw = value
		notify_property_list_changed()
		queue_redraw()

## The shape of the origin marker.
enum ORIGIN_DRAW_MARKER_MODE {
	CROSS, ## Draws a cross.
	CIRCLE, ## Draws a circle.
	SQUARE ## Draws a square.
}

## The shape of the origin marker.
@export var origin_marker_mode : ORIGIN_DRAW_MARKER_MODE = ORIGIN_DRAW_MARKER_MODE.CROSS:
	set(value):
		origin_marker_mode = value
		notify_property_list_changed()
		queue_redraw()

## The size (radius or half-extent) of the origin marker in pixels.
@export_range(2.0, 128.0, 1.0, "suffix:px") var origin_extents : float = 8.0:
	set(value):
		origin_extents = value
		queue_redraw()

## The color of the origin marker.
@export var origin_color : Color = Color.FUCHSIA :
	set(value):
		origin_color = value
		queue_redraw()

## The thickness of the origin marker lines in pixels.
@export_range(1.0, 64.0, 1.0, "suffix:px","or_greater") var origin_line_thickness : float = 1.0:
	set(value):
		origin_line_thickness = value
		queue_redraw()

## If [code]true[/code], the origin marker is drawn with antialiasing.
@export var origin_antialiased : bool = false :
	set(value):
		origin_antialiased = value
		queue_redraw()

@export_group("Coordinates Labels","labels_")

## If [code]true[/code], draws coordinate labels at the center of each cell.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var labels_draw : bool = false:
	set(value):
		if labels_draw == value: return
		labels_draw = value
		notify_property_list_changed()
		queue_redraw()

## The space in which the coordinates will be displayed.
enum CoordinatesSpace {
	CELL, ## Cell coordinates.
	GLOBAL, ## Global coordinates.
	LOCAL, ## Local coordinates.
}

## Determines the space in which the coordinates will be displayed.[br]
@export var labels_space : CoordinatesSpace = CoordinatesSpace.CELL:
	set(value):
		labels_space = value
		queue_redraw()
		notify_property_list_changed()

## If [code]true[/code], allows setting different colors for X and Y coordinates.
@export var labels_decouple_coordinates : bool = true:
	set(value):
		labels_decouple_coordinates = value
		notify_property_list_changed()
		queue_redraw()

## Format in which the coordinates will be displayed.[br][br]
## [b]Note :[/b] The commas in the [code]@export_enum[/code] are actually [i]"Single Low-9 Quotation Mark"[/i] because commas throw an error, so i just replaced commas by that character.
@export_enum("xy","x‚y","(x‚y)","X:x‚Y:y") var labels_format: String = "x‚y":
	set(value):
		labels_format = value
		queue_redraw()

## Format in which the X coordinates will be displayed.
@export_enum("x","X:x") var labels_x_format: String = "x":
	set(value):
		labels_x_format = value
		queue_redraw()

## Format in which the Y coordinates will be displayed.
@export_enum("y","Y:y") var labels_y_format: String = "y":
	set(value):
		labels_y_format = value
		queue_redraw()

@export_subgroup("Font", "labels_font_")

## The font used to render the labels.
@export var labels_font_file: Font = preload("fonts/Inconsolata/static/Inconsolata_SemiCondensed-Medium.ttf"):
	set(value):
		labels_font_file = value
		queue_redraw()

## The color of the label text.
## Also acts as the primary color when [member fill_checkerboard] is [code]true[/code].
@export var labels_font_color := Color(1,1,1,0.75):
	set(value):
		labels_font_color = value
		queue_redraw()

## The color of the label text when checkerboard is enabled.
@export var labels_font_secondary_color := Color.WHITE:
	set(value):
		labels_font_secondary_color = value
		queue_redraw()

## The color of the X coordinates text.
@export var labels_font_x_color : Color = SPATIAL_RED:
	set(value):
		labels_font_x_color = value
		queue_redraw()

## The color of the X coordinates text when checkerboard is enabled.
@export var labels_font_x_secondary_color : Color = Color("eb6fff"):
	set(value):
		labels_font_x_secondary_color = value
		queue_redraw()

## The color of the Y coordinates text.
@export var labels_font_y_color : Color = CONTROL_GREEN:
	set(value):
		labels_font_y_color = value
		queue_redraw()

## The color of the Y coordinates text when checkerboard is enabled.
@export var labels_font_y_secondary_color : Color =  Color("42f7ed"):
	set(value):
		labels_font_y_secondary_color = value
		queue_redraw()

## The font size of the labels.
@export_range(1.0, 128.0, 1.0, "suffix:px") var labels_font_size: float = 16.0:
	set(value):
		labels_font_size = value
		queue_redraw()

@export_group("Cells Properties","cells_properties_")

## If [code]true[/code], draws properties on cells.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "checkbox_only") var cells_properties_draw : bool = false:
	set(value):
		if cells_properties_draw == value: return
		cells_properties_draw = value
		notify_property_list_changed()
		queue_redraw()

## Per-cell properties overrides.[br]
## Use cell coordinates to assign a [CellProperties] resource to a specific cell.
@export var cells_properties : Dictionary[Vector2i,CellProperties] = {} :
	set(value):
		cells_properties = value
		queue_redraw()

## Validates properties to hide/show them in the editor.
## [b]Warning:[/b] This relies on property names starting with specific prefixes (e.g. "grid_", "grid_line_").
## When refactoring or adding new properties, ensure they follow these naming conventions or update this method.
func _validate_property(property: Dictionary) -> void:
	# Mapping des préfixes aux variables d'activation
	var prefix_toggles : Dictionary[String,Dictionary] = {
		"grid": {"toggle": grid_draw, "exclude": "grid_draw"},
		"grid_line": {"toggle": grid_line_enabled, "exclude": "grid_line_enabled"},
		"border": {"toggle": border_draw, "exclude": "border_draw"},
		"subdivision": {"toggle": subdivision_enabled, "exclude": "subdivision_enabled"},
		"fill": {"toggle": fill_enabled, "exclude": "fill_enabled"},
		"origin": {"toggle": origin_draw, "exclude": "origin_draw"},
		"labels": {"toggle": labels_draw, "exclude": "labels_draw"},
		"cells_properties": {"toggle": cells_properties_draw, "exclude": "cells_properties_draw"}
	}

	# Vérification des préfixes
	for prefix in prefix_toggles:
		if property.name.begins_with(prefix):
			var data = prefix_toggles[prefix]
			if not data.toggle and property.name != data.exclude:
				property.usage = PROPERTY_USAGE_NO_EDITOR
				return

	if grid_mode == GRID_MODE.INFINITE:
		if property.name.begins_with("border_"):
			property.usage = PROPERTY_USAGE_NO_EDITOR
			return

	match property.name:
		"fill_secondary_color":
			if not fill_checkerboard:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"grid_line_horizontal_color","grid_line_vertical_color":
			if not grid_line_decouple_axis_colors:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"grid_line_color":
			if grid_line_decouple_axis_colors:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"grid_cell_count":
			if grid_mode == GRID_MODE.INFINITE:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"grid_size":
			if grid_mode == GRID_MODE.INFINITE:
				property.usage = PROPERTY_USAGE_NO_EDITOR
			else:
				property.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		"labels_format","labels_font_color":
			if labels_decouple_coordinates:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"labels_font_x_color", "labels_font_y_color", "labels_x_format", "labels_y_format":
			if not labels_decouple_coordinates:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"labels_font_x_secondary_color", "labels_font_y_secondary_color":
			if not labels_decouple_coordinates or not fill_checkerboard:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"labels_font_secondary_color":
			if labels_decouple_coordinates or not fill_checkerboard:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"fill_antialiased":
			if grid_line_enabled:
				property.usage = PROPERTY_USAGE_NO_EDITOR


var _last_canvas_transform : Transform2D
var _last_global_transform : Transform2D
var _last_viewport_size : Vector2

func _process(_delta: float) -> void:
	if grid_mode == GRID_MODE.INFINITE:
		var current_canvas_transform := get_canvas_transform()
		var current_global_transform := get_global_transform()
		var current_viewport_size := get_viewport_rect().size
		
		if _last_canvas_transform != current_canvas_transform or \
		   _last_global_transform != current_global_transform or \
		   _last_viewport_size != current_viewport_size:
			
			_last_canvas_transform = current_canvas_transform
			_last_global_transform = current_global_transform
			_last_viewport_size = current_viewport_size
			queue_redraw()

func _get_visible_rect_in_local_space() -> Rect2:
	var viewport_rect := get_viewport().get_visible_rect()
	var canvas_transform := get_canvas_transform()
	var global_transform := get_global_transform()
	
	# Transform viewport rect (screen space) to local space
	# Local -> Global -> Viewport
	# Viewport -> Global -> Local
	var transform := (canvas_transform * global_transform).affine_inverse()
	return transform * viewport_rect

func _get_visible_cell_range() -> Rect2i:
	var local_visible_rect : Rect2 = _get_visible_rect_in_local_space()
	var cell_size_vector : Vector2 = Vector2(grid_cell_size)
	
	var start_cell := Vector2i((local_visible_rect.position / cell_size_vector).floor())
	var end_cell := Vector2i((local_visible_rect.end / cell_size_vector).ceil())
	
	return Rect2i(start_cell, end_cell - start_cell)

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	if what == NOTIFICATION_EXIT_TREE:
		if get_viewport():
			get_viewport().size_changed.disconnect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	prints("Viewport size changed", get_viewport().size)
	queue_redraw()

func _draw() -> void:
	if grid_mode == GRID_MODE.CUSTOM:
		if border_draw and border_draw_behind: _draw_rect()
	
	if fill_enabled:
		_draw_fill()
	if grid_draw:
		_draw_grid()
		
	if grid_mode == GRID_MODE.CUSTOM:
		if border_draw and not border_draw_behind: _draw_rect()

	if labels_draw:
		_draw_labels()
	
	if cells_properties_draw:
		_draw_cells_properties()
	
	if origin_draw:
		_draw_origin()

func _draw_fill() -> void:
	if grid_mode == GRID_MODE.INFINITE:
		if not fill_checkerboard: return
		
		var visible_range := _get_visible_cell_range()
		var start_cell := visible_range.position
		var end_cell := visible_range.end
		var cell_size_vector := Vector2(grid_cell_size)
		
		for x in range(start_cell.x, end_cell.x):
			for y in range(start_cell.y, end_cell.y):
				var pos := Vector2(x, y) * cell_size_vector
				var color := fill_color if (x + y) % 2 == 0 else fill_secondary_color
				draw_rect(Rect2(pos, cell_size_vector), color, true, -1.0, fill_antialiased)
		return

	if not fill_checkerboard:
		var rect_size := Vector2(grid_cell_count * grid_cell_size)
		draw_rect(Rect2(Vector2.ZERO, rect_size), fill_color)
	else:
		var cell_size := Vector2(grid_cell_size)
		for x in grid_cell_count.x:
			for y in grid_cell_count.y:
				var pos := Vector2(x, y) * cell_size
				var color := fill_color if (x + y) % 2 == 0 else fill_secondary_color
				draw_rect(Rect2(pos, cell_size), color, true, -1.0, fill_antialiased)


func _draw_origin() -> void:
	var line_margin : float = origin_line_thickness/2.0
	match origin_marker_mode:
		ORIGIN_DRAW_MARKER_MODE.CROSS:
			var first_line_start := Vector2(-origin_extents, -origin_extents)
			var first_line_end := Vector2(origin_extents, origin_extents)
			var second_line_start := Vector2(origin_extents, -origin_extents)
			var second_line_end := Vector2(-origin_extents, origin_extents)
			
			var points := PackedVector2Array([first_line_start, first_line_end, second_line_start, second_line_end])
			draw_multiline(points, origin_color, origin_line_thickness, origin_antialiased)
		ORIGIN_DRAW_MARKER_MODE.CIRCLE:
			draw_circle(Vector2.ZERO, origin_extents - line_margin, origin_color, false, origin_line_thickness, origin_antialiased)
		ORIGIN_DRAW_MARKER_MODE.SQUARE:
			var top_left_corner := Vector2(-origin_extents + line_margin,-origin_extents + line_margin)
			var square_size := Vector2(origin_extents - line_margin,origin_extents - line_margin) * 2.0
			draw_rect(Rect2(top_left_corner, square_size), origin_color, false, origin_line_thickness, origin_antialiased)



func _draw_rect() -> void:
	if grid_mode == GRID_MODE.INFINITE: return
	var rect : Rect2

	match border_draw_mode:
		BORDER_MODE.INBETWEEN:
			rect = Rect2(0, 0, grid_cell_count.x * grid_cell_size.x, grid_cell_count.y * grid_cell_size.y)
		BORDER_MODE.INSIDE:
			var half_thickness = border_thickness/2.0
			rect = Rect2(half_thickness, half_thickness, grid_cell_count.x * grid_cell_size.x - border_thickness, grid_cell_count.y * grid_cell_size.y - border_thickness)
		BORDER_MODE.OUTSIDE:
			var half_thickness = border_thickness/2.0
			rect = Rect2(-half_thickness, -half_thickness, grid_cell_count.x * grid_cell_size.x + border_thickness, grid_cell_count.y * grid_cell_size.y + border_thickness)

	draw_rect(rect, border_color, false, border_thickness, border_antialiased)


func _draw_grid() -> void:
	var use_subdivision : bool = subdivision_enabled and subdivision_steps > 0

	if !grid_line_enabled and !use_subdivision:
		return

	var start_cell := Vector2i(0,0)
	var end_cell := grid_cell_count

	if grid_mode == GRID_MODE.INFINITE:
		var visible_range := _get_visible_cell_range()
		start_cell = visible_range.position
		end_cell = visible_range.end
	
	var minor_horizontal_points := PackedVector2Array()
	var minor_vertical_points := PackedVector2Array()
	var major_points := PackedVector2Array()
	
	var steps : int = subdivision_steps

	# Vertical lines
	
	for x in range(start_cell.x, end_cell.x):
		var x_position : int = x * grid_cell_size.x
		
		var start := Vector2(x_position, start_cell.y * grid_cell_size.y)
		var end := Vector2(x_position, end_cell.y * grid_cell_size.y)
		
		# Check if this line is a "Major" line based on steps
		if use_subdivision and (x % steps == 0):
			major_points.append(start)
			major_points.append(end)
		else:
			if grid_line_enabled:
				minor_vertical_points.append(start)
				minor_vertical_points.append(end)

	# Horizontal lines 
	
	for y in range(start_cell.y, end_cell.y):
		var y_position : int = y * grid_cell_size.y
		var start := Vector2(start_cell.x * grid_cell_size.x, y_position)
		var end := Vector2(end_cell.x * grid_cell_size.x, y_position)
		
		if use_subdivision and (y % steps == 0):
			major_points.append(start)
			major_points.append(end)
		else:
			if grid_line_enabled:
				minor_horizontal_points.append(start)
				minor_horizontal_points.append(end)
		
	# Draw Standard (Minor) Lines
	if grid_line_decouple_axis_colors:
		if not minor_horizontal_points.is_empty():
			draw_multiline(minor_horizontal_points, grid_line_horizontal_color, grid_line_thickness, grid_line_antialiased)
		if not minor_vertical_points.is_empty():
			draw_multiline(minor_vertical_points, grid_line_vertical_color, grid_line_thickness, grid_line_antialiased)
	else:
		# Merge arrays for a single draw call if colors are unified
		minor_vertical_points.append_array(minor_horizontal_points)
		if not minor_vertical_points.is_empty():
			draw_multiline(minor_vertical_points, grid_line_color, grid_line_thickness, grid_line_antialiased)

	# 2. Draw Subdivision (Major) Lines ON TOP
	if not major_points.is_empty():
		draw_multiline(major_points, subdivision_line_color, subdivision_line_thickness, grid_line_antialiased)

func _draw_labels() -> void:
	var cell_size := Vector2(grid_cell_size)
	var half_cell_size : Vector2 = cell_size / 2.0
	
	var ascent : float = labels_font_file.get_ascent(labels_font_size)
	var descent : float = labels_font_file.get_descent(labels_font_size)
	var line_height : float = ascent + descent
	
	var format_x_processed : String = ""
	var format_y_processed : String = ""
	var format_combined_processed : String = ""

	var start_cell := Vector2i(0,0)
	var end_cell : Vector2i = grid_cell_count

	if grid_mode == GRID_MODE.INFINITE:
		var visible_range := _get_visible_cell_range()
		start_cell = visible_range.position
		end_cell = visible_range.end
	
	if labels_decouple_coordinates:
		format_x_processed = labels_x_format.replace("‚", ",").replace("x", "%02d")
		format_y_processed = labels_y_format.replace("‚", ",").replace("y", "%02d")
	else:
		format_combined_processed = labels_format.replace("‚", ",").replace("x", "%02d").replace("y", "%02d")
	
	for x in range(start_cell.x, end_cell.x):
		for y in range(start_cell.y, end_cell.y):
			var cell_center_local_position := Vector2(x, y) * cell_size + half_cell_size
			
			var coordinates_value := Vector2i(x, y)
			
			match labels_space:
				CoordinatesSpace.LOCAL:
					coordinates_value = Vector2i(cell_center_local_position)
				CoordinatesSpace.GLOBAL:
					coordinates_value = Vector2i(global_position + cell_center_local_position)
			
			if labels_decouple_coordinates:
				var label_x_text : String = format_x_processed % coordinates_value.x
				var label_y_text : String = format_y_processed % coordinates_value.y
				
				var label_x_size : Vector2 = labels_font_file.get_string_size(label_x_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, labels_font_size)
				var label_y_size : Vector2 = labels_font_file.get_string_size(label_y_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, labels_font_size)
				
				var total_height : float = line_height * 2.0
				var start_y_pos : float = cell_center_local_position.y - (total_height / 2.0)
				var x_baseline : float = start_y_pos + ascent
				var y_baseline : float = start_y_pos + line_height + ascent
				var center_x_pos : float = cell_center_local_position.x - label_x_size.x / 2.0
				var center_y_pos : float = cell_center_local_position.x - label_y_size.x / 2.0
				
				var label_x_color : Color = labels_font_x_color
				var label_y_color : Color = labels_font_y_color

				if fill_checkerboard and fill_enabled:
					if (x + y) % 2 == 1:
						label_x_color = labels_font_x_secondary_color
						label_y_color = labels_font_y_secondary_color
				
				draw_string(labels_font_file, Vector2(center_x_pos, x_baseline), label_x_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, labels_font_size, label_x_color)
				draw_string(labels_font_file, Vector2(center_y_pos, y_baseline), label_y_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, labels_font_size, label_y_color)
				
			else:
				var label_text_combined : String = format_combined_processed % [coordinates_value.x, coordinates_value.y]
				var label_size_combined : Vector2 = labels_font_file.get_string_size(label_text_combined, HORIZONTAL_ALIGNMENT_LEFT, -1.0, labels_font_size)
				
				var center_x_pos_combined : float = cell_center_local_position.x - label_size_combined.x / 2.0
				var baseline_y : float = cell_center_local_position.y + (ascent - descent) / 2.0

				var text_position := Vector2(center_x_pos_combined, baseline_y)

				var label_color : Color = labels_font_color

				if fill_checkerboard and fill_enabled:
					if (x + y) % 2 == 1:
						label_color = labels_font_secondary_color

				draw_string(labels_font_file, text_position, label_text_combined, HORIZONTAL_ALIGNMENT_LEFT, -1.0, labels_font_size, label_color)

func _draw_cells_properties() -> void:
	if cells_properties.is_empty(): return
	
	var visible_range := Rect2i()
	if grid_mode == GRID_MODE.INFINITE:
		visible_range = _get_visible_cell_range()
		
	for cell_coord in cells_properties:
		# Ensure coordinates are within the grid bounds
		if grid_mode == GRID_MODE.CUSTOM:
			if cell_coord.x < 0 or cell_coord.x >= grid_cell_count.x or cell_coord.y < 0 or cell_coord.y >= grid_cell_count.y:
				continue
		elif grid_mode == GRID_MODE.INFINITE:
			if not visible_range.has_point(cell_coord):
				continue

		var rect_start : Vector2i = cell_coord * grid_cell_size
		var cell_props : CellProperties = cells_properties[cell_coord]
		
		if cell_props:
			cell_props.draw_cell(rect_start, grid_cell_size, self)


## Sets the properties for a cell.
## Pass a [CellProperties] resource to customize a cell's appearance.
## If [param properties] is null, it clears the properties for that cell.
func set_cell_properties(cell_position: Vector2i, properties: CellProperties) -> void:
	if properties == null:
		if cells_properties.has(cell_position):
			cells_properties.erase(cell_position)
			queue_redraw()
	else:
		cells_properties[cell_position] = properties
		queue_redraw()

## Returns the [CellProperties] for a given cell.
## Returns null if no properties are set for that cell.
func get_cell_properties(cell_position: Vector2i) -> CellProperties:
	if cells_properties.has(cell_position):
		return cells_properties[cell_position]
	return null

## Clears any custom properties from a cell.
func clear_cell_properties(cell_position : Vector2i) -> void:
	if cells_properties.has(cell_position):
		cells_properties.erase(cell_position)
		queue_redraw()

## Clears all custom properties from all cells.
func clear_all_cell_properties() -> void:
	cells_properties.clear()
	queue_redraw()
