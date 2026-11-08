extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var scene: PackedScene = load("res://main.tscn")
 var game: Control = scene.instantiate()
 root.add_child(game)
 await process_frame
 await process_frame
 print("UI bounds: ",game.size," panel=",game.panel.get_global_rect()," scroll=",game.scroll.get_global_rect())
 var buttons := game.find_children("*","Button",true,false)
 for button in buttons:
  print("BUTTON: ",button.text," rect=",button.get_global_rect()," visible=",button.is_visible_in_tree())
 var chosen: Button = null
 for button in buttons:
  if button.text=="학습하고 새로 시작": chosen=button
 assert(chosen != null)
 var motion := InputEventMouseMotion.new()
 motion.position=chosen.get_global_rect().get_center()
 motion.global_position=motion.position
 Input.parse_input_event(motion)
 await process_frame
 print("HOVER: ",root.get_viewport().gui_get_hovered_control())
 var press := InputEventMouseButton.new()
 press.button_index=MOUSE_BUTTON_LEFT
 press.position=motion.position
 press.global_position=motion.position
 press.pressed=true
 game.get_viewport().push_input(press,true)
 press.pressed=false
 game.get_viewport().push_input(press,true)
 await process_frame
 print("AFTER INPUT: ",game.state.mode)
 assert(game.state.mode=="tutorial", "mouse button must open tutorial")
 await process_frame
 await process_frame
 assert(game.state.mode=="tutorial")
 print("PASS: title-to-tutorial button and UI tree")
 quit()
