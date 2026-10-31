class_name BattleWarmup
extends CanvasLayer
## Does a fight's first-time graphics work behind the title screen: loads every ship's hull art onto the
## graphics card, works out each ship's shield bubble, and builds the shield shader, one ship a frame. Without
## it the first fight against a new ship stalls while the driver does this work.

var _designs: Array = []
var _shield := ColorRect.new()


func _ready() -> void:
	layer = -100   # drawn under everything, so nothing here is ever seen
	_designs = Library.ships.keys()
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/shield.gdshader")
	_shield.material = material
	_shield.size = Vector2(64, 64)
	add_child(_shield)


func _process(_delta: float) -> void:
	if _designs.is_empty():
		queue_free()
		return
	var design: ShipDesign = Library.ship(_designs.pop_back())
	Formation.shield_shape(design)
	var texture := Library.texture(design.art_path)
	if texture:
		var sprite := Sprite2D.new()   # drawn once so the texture is uploaded now, then dropped
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE * 0.05
		add_child(sprite)
		get_tree().create_timer(0.2).timeout.connect(sprite.queue_free)
