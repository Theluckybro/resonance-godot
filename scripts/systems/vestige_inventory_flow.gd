extends Node

const INVENTORY_PANEL_SCENE: PackedScene = preload("res://scenes/ui/vestige_inventory_panel.tscn")

@export var debug_inventory_flow: bool = true

var _panel: VestigeInventoryPanel
var _block_toggle_until_release: bool = false
var _boot_log_emitted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	_debug_log("ready | input=%s unhandled=%s process=%s" % [str(is_processing_input()), str(is_processing_unhandled_input()), str(is_processing())])


func _process(_delta: float) -> void:
	# One-time heartbeat so developer can confirm singleton is alive.
	if not _boot_log_emitted:
		_boot_log_emitted = true
		_debug_log("heartbeat")

	# Fallback path: polling input ensures inventory flow still works
	# even when event-based callbacks are consumed by other UI nodes.
	if _block_toggle_until_release:
		if not Input.is_action_pressed("action_vestige_inventory"):
			_block_toggle_until_release = false
			_debug_log("toggle block released (process)")
		return

	if Input.is_action_just_pressed("action_vestige_inventory"):
		_debug_log("inventory action detected from _process fallback")
		toggle_panel()
		return

	if Input.is_action_just_pressed("ui_cancel") and is_open():
		_debug_log("ui_cancel detected from _process fallback while panel open")
		close_panel()


func _input(event: InputEvent) -> void:
	_handle_action_event(event, "_input")


func _unhandled_input(event: InputEvent) -> void:
	_handle_action_event(event, "_unhandled_input")


func _handle_action_event(event: InputEvent, source: String) -> void:
	if _block_toggle_until_release:
		if not Input.is_action_pressed("action_vestige_inventory"):
			_block_toggle_until_release = false
			_debug_log("toggle block released")
		return

	if not (event is InputEventAction):
		return
	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("action_vestige_inventory"):
		_debug_log("inventory action received from %s" % source)
		toggle_panel()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel") and is_open():
		_debug_log("ui_cancel received from %s while panel open" % source)
		close_panel()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _panel != null and is_instance_valid(_panel) and _panel.is_open()


func toggle_panel() -> void:
	if is_open():
		_debug_log("toggle -> close")
		close_panel()
		# Prevent immediate reopen from same key press.
		_block_toggle_until_release = true
		return
	_debug_log("toggle -> open")
	open_panel()


func open_panel() -> void:
	_debug_log("open_panel requested")
	_ensure_panel_instance()
	if _panel == null or not is_instance_valid(_panel):
		_debug_log("open_panel aborted: panel instance unavailable")
		return

	if not PauseManager.pause_for_inventory():
		var is_paused := bool(PauseManager.get("_is_paused"))
		var context := String(PauseManager.get("_pause_context"))
		_debug_log("open_panel blocked by pause manager | paused=%s context=%s" % [str(is_paused), context])
		return

	if not _panel.is_inside_tree():
		_debug_log("panel not in tree yet, deferring open_panel")
		_panel.call_deferred("open_panel")
		return
	_debug_log("panel opened")
	_panel.open_panel()


func close_panel() -> void:
	if _panel == null or not is_instance_valid(_panel):
		var resumed_without_panel := PauseManager.resume_from_inventory()
		_debug_log("close_panel without panel | resume_from_inventory=%s" % str(resumed_without_panel))
		return

	_panel.close_panel()
	var resumed := PauseManager.resume_from_inventory()
	_debug_log("panel closed | resume_from_inventory=%s" % str(resumed))


func _ensure_panel_instance() -> void:
	if _panel != null and is_instance_valid(_panel):
		return
	if INVENTORY_PANEL_SCENE == null:
		_debug_log("cannot instantiate panel: scene is null")
		return

	var panel_variant: Variant = INVENTORY_PANEL_SCENE.instantiate()
	if not (panel_variant is VestigeInventoryPanel):
		_debug_log("cannot instantiate panel: scene root is not VestigeInventoryPanel")
		return

	_panel = panel_variant as VestigeInventoryPanel
	_panel.name = "VestigeInventoryPanelRuntime"

	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	if host == null:
		_debug_log("cannot attach panel: no valid host node")
		_panel = null
		return

	host.add_child.call_deferred(_panel)
	_panel.close_panel()
	_debug_log("panel instantiated and deferred to host: %s" % host.name)

func _debug_log(message: String) -> void:
	if not debug_inventory_flow:
		return
	var composed := "[VestigeInventoryFlow] %s" % message
	print(composed)
	if message.begins_with("ERROR:"):
		push_warning(composed)