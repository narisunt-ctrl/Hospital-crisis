extends Node2D
## A standalone delivery game. All simulation, navigation and UI run in Godot.
var REGULAR = preload("res://assets/Thai-Regular.ttf")
var BOLD = preload("res://assets/Thai-Bold.ttf")
const BACKGROUND = preload("res://assets/hospital.png")
const TEAL = Color("159c9d")
const INK = Color("203d52")
const CREAM = Color("fff9ed")
const GOLD = Color("ffce76")
const CORAL = Color("ef8270")
const STATIONS = {
 "supply": Vector2(340, 410), "lab": Vector2(1130, 410),
 "ward": Vector2(1010, 650), "lounge": Vector2(470, 650)
}
const ORDER_TYPES = ["medicine", "sample", "medicine", "medicine", "sample", "sample", "medicine", "sample"]
var player = Vector2(710, 590)
var robot = Vector2(635, 630)
var route: PackedVector2Array = []
var nav = AStarGrid2D.new()
var ui: Control
var overlay: Control
var hud: Control
var objective: Label
var clock_label: Label
var score_label: Label
var combo_label: Label
var cargo_label: Label
var notice_label: Label
var interact_button: Button
var hint_button: Button
var nurse_texture: Texture2D
var robot_texture: Texture2D
var mode = "menu"
var remaining = 180.0
var deadline = 38.0
var score = 0
var delivered = 0
var missed = 0
var combo = 0
var cargo = ""
var order_kind = "medicine"
var order_index = 0
var hint_on = false
var animation_time = 0.0
var step_phase = 0.0
var moving = false
var dash_cooldown = 0.0
var boost = 0.0
var notice_time = 0.0
var pending_station = ""
var sparks: Array[Dictionary] = []
var sound_on = true
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var saved_best = 0
var toast_text = ""
var debug_mode = false
var web_status_elapsed = 0.0

func _ready() -> void:
 REGULAR.fallbacks = [preload("res://assets/Latin-Regular.ttf"), preload("res://assets/Symbols.ttf"), preload("res://assets/Symbols-Regular.ttf")]
 BOLD.fallbacks = [preload("res://assets/Latin-Bold.ttf"), preload("res://assets/Symbols.ttf"), preload("res://assets/Symbols-Regular.ttf")]
 debug_mode = OS.get_cmdline_user_args().has("--smoke-test")
 nurse_texture = load("res://assets/nurse.png") if ResourceLoader.exists("res://assets/nurse.png") else null
 robot_texture = load("res://assets/robot.png")
 _setup_navigation()
 _setup_audio()
 _load_best()
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(ui)
 _build_hud()
 _menu()
 get_tree().auto_accept_quit = true
 if debug_mode:
  call_deferred("_smoke_test")

func _setup_navigation() -> void:
 nav.region = Rect2i(0, 0, 72, 45)
 nav.cell_size = Vector2(20, 20)
 nav.offset = Vector2(10, 10)
 nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 nav.update()
 for x in range(72):
  for y in range(45):
   var point = Vector2(x * 20 + 10, y * 20 + 10)
   nav.set_point_solid(Vector2i(x, y), not _walkable(point))

func _walkable(p: Vector2) -> bool:
 if p.x < 140 or p.x > 1300 or p.y < 375 or p.y > 760:
  return false
 if p.y > 565 and (p.x < 440 or p.x > 1050):
  return false
 return true

func _cell(p: Vector2) -> Vector2i:
 return Vector2i(clampi(int(p.x / 20), 0, 71), clampi(int(p.y / 20), 0, 44))

func _go_to(p: Vector2) -> void:
 var target = _cell(p)
 if nav.is_point_solid(target):
  return
 route = nav.get_point_path(_cell(player), target)

func _panel(parent: Node, rect: Rect2, color: Color, radius: int = 18, border: Color = Color.TRANSPARENT) -> Panel:
 var n = Panel.new()
 n.position = rect.position
 n.size = rect.size
 n.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var style = StyleBoxFlat.new()
 style.bg_color = color
 style.corner_radius_top_left = radius
 style.corner_radius_top_right = radius
 style.corner_radius_bottom_left = radius
 style.corner_radius_bottom_right = radius
 if border.a > 0:
  style.border_color = border
  style.set_border_width_all(2)
 n.add_theme_stylebox_override("panel", style)
 parent.add_child(n)
 return n

func _label(parent: Node, value: String, rect: Rect2, size_px: int = 20, color: Color = CREAM, bold: bool = false) -> Label:
 var n = Label.new()
 n.position = rect.position
 n.size = rect.size
 n.text = value
 n.add_theme_font_override("font", BOLD if bold else REGULAR)
 n.add_theme_font_size_override("font_size", size_px)
 n.add_theme_color_override("font_color", color)
 n.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(n)
 return n

func _button(parent: Node, value: String, rect: Rect2, callback: Callable, color: Color = TEAL) -> Button:
 var b = Button.new()
 b.position = rect.position
 b.size = rect.size
 b.text = value
 b.add_theme_font_override("font", BOLD)
 b.add_theme_font_size_override("font_size", 20)
 b.add_theme_color_override("font_color", CREAM)
 for kind in ["normal", "hover", "pressed", "focus"]:
  var style = StyleBoxFlat.new()
  style.bg_color = color.lightened(0.12) if kind == "hover" else color
  if kind == "pressed":
   style.bg_color = color.darkened(0.12)
  style.set_corner_radius_all(14)
  style.border_color = GOLD if kind == "focus" else Color(1, 1, 1, 0.22)
  style.set_border_width_all(3 if kind == "focus" else 1)
  style.shadow_color = Color(0, 0, 0, 0.18)
  style.shadow_size = 4
  style.shadow_offset = Vector2(0, 4)
  b.add_theme_stylebox_override(kind, style)
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

func _build_hud() -> void:
 hud = Control.new()
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(hud)
 _panel(hud, Rect2(18, 16, 1404, 94), Color("173b4aee"), 22, Color("ffffff44"))
 _label(hud, "โรงพยาบาลวิกฤต", Rect2(42, 27, 340, 40), 30, CREAM, true)
 _label(hud, "เข้าเวรกับ AI  /  DELIVERY SHIFT", Rect2(44, 70, 350, 25), 12, Color("93d8d2"), true)
 _panel(hud, Rect2(420, 29, 538, 68), Color("fff8e9"), 14)
 objective = _label(hud, "", Rect2(438, 35, 505, 52), 21, INK, true)
 clock_label = _label(hud, "03:00", Rect2(993, 23, 160, 50), 37, CREAM, true)
 score_label = _label(hud, "", Rect2(1170, 28, 170, 33), 22, GOLD, true)
 combo_label = _label(hud, "", Rect2(1170, 64, 170, 26), 14, Color("b9e7df"))
 _label(hud, "เวลาที่เหลือ", Rect2(998, 77, 155, 20), 11, Color("a2bdc4"))
 _button(hud, "II", Rect2(1350, 36, 48, 48), _pause, Color("3c5c68"))
 _panel(hud, Rect2(20, 792, 1400, 88), Color("173b4af5"), 21, Color("ffffff44"))
 _label(hud, "P1", Rect2(42, 811, 45, 32), 21, GOLD, true)
 cargo_label = _label(hud, "", Rect2(93, 807, 440, 36), 22, CREAM, true)
 _label(hud, "WASD / ลูกศร เดิน   ·   คลิกพื้นเพื่อเดิน", Rect2(94, 844, 550, 24), 12, Color("b8cdd0"))
 hint_button = _button(hud, "AI ช่วยบอกทาง [H]", Rect2(716, 809, 260, 52), _toggle_hint, Color("426b78"))
 interact_button = _button(hud, "รับ / ส่งของ [E]", Rect2(997, 809, 260, 52), _interact)
 _button(hud, "วิ่ง [Shift]", Rect2(1270, 809, 132, 52), _dash, Color("bf8152"))
 notice_label = _label(hud, "", Rect2(350, 721, 740, 50), 22, CREAM, true)
 notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 notice_label.add_theme_color_override("font_shadow_color", Color("173b4a"))
 notice_label.add_theme_constant_override("shadow_outline_size", 10)
 _update_hud()

func _clear_overlay() -> void:
 if is_instance_valid(overlay):
  overlay.queue_free()
 overlay = Control.new()
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 overlay.size = Vector2(1440, 900)
 ui.add_child(overlay)

func _picture(parent: Node, texture: Texture2D, rect: Rect2) -> void:
 var n = TextureRect.new()
 n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 n.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 n.texture = texture
 n.position = rect.position
 n.size = rect.size
 n.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(n)

func _menu() -> void:
 mode = "menu"
 hud.visible = false
 _clear_overlay()
 _panel(overlay, Rect2(0, 0, 1440, 900), Color("102e40a8"), 0)
 _picture(overlay, nurse_texture, Rect2(775, 90, 450, 565))
 _picture(overlay, robot_texture, Rect2(1130, 375, 230, 260))
 _panel(overlay, Rect2(68, 65, 640, 765), Color("163d4aed"), 34, Color("ffffff44"))
 _label(overlay, "A LITTLE TEAM. A BIG HEART.", Rect2(110, 102, 550, 28), 14, GOLD, true)
 _label(overlay, "โรงพยาบาล", Rect2(105, 140, 570, 115), 76, CREAM, true)
 _label(overlay, "วิกฤต", Rect2(105, 260, 570, 115), 76, CREAM, true)
 _label(overlay, "เข้าเวรกับ AI", Rect2(112, 400, 550, 65), 40, Color("84e3d3"), true)
 _label(overlay, "ลิฟต์เสีย คนไข้รออยู่… เวรนี้ต้องมีคุณ!\nเข็นรถ รับของ แล้วส่งให้ทันเวลา\nพร้อมผู้ช่วยตัวจิ๋วที่คอยบอกทาง", Rect2(114, 488, 550, 120), 23, Color("d9e6e5"))
 _button(overlay, "เริ่มเข้าเวร   ▶", Rect2(112, 650, 380, 68), _start, TEAL)
 _button(overlay, "วิธีเล่น", Rect2(511, 650, 150, 68), _help, Color("426475"))
 _button(overlay, "เสียง: เปิด" if sound_on else "เสียง: ปิด", Rect2(112, 745, 190, 42), _toggle_sound, Color("345666"))
 _label(overlay, "3 นาที / 1 ผู้เล่น / เมาส์ คีย์บอร์ด หรือสัมผัส", Rect2(320, 751, 360, 36), 12, Color("c2d6d4"))
 _panel(overlay, Rect2(920, 652, 430, 135), Color("fff8e9ef"), 22)
 _label(overlay, "ร่วมมือ แก้วิกฤต", Rect2(947, 669, 390, 45), 32, INK, true)
 _label(overlay, "ส่งของสำเร็จ 3 / 6 / 10 ครั้ง = 1 / 2 / 3 ดาว\nสถิติสูงสุด  %d  คะแนน" % saved_best, Rect2(947, 720, 390, 60), 16, Color("557582"))
 _label(overlay, "GODOT EDITION  /  กติกาสมมติ ไม่ใช่คำแนะนำทางการแพทย์", Rect2(80, 856, 1260, 30), 12, Color("d5e1dc"))

func _start() -> void:
 mode = "playing"
 overlay.queue_free()
 hud.visible = true
 remaining = 180.0
 score = 0
 delivered = 0
 missed = 0
 combo = 0
 cargo = ""
 order_index = 0
 dash_cooldown = 0
 boost = 0
 hint_on = false
 pending_station = ""
 sparks.clear()
 player = Vector2(710, 590)
 robot = Vector2(630, 635)
 route.clear()
 _next_order()
 _notice("คลิกป้ายคลังยา แล้วเดินไปรับของได้เลย!", 5.0)
 _sound("pickup")
 _update_hud()

func _next_order() -> void:
 order_kind = ORDER_TYPES[order_index % ORDER_TYPES.size()]
 deadline = 38.0 if order_index < 2 else 30.0
 pending_station = ""
 _update_hud()

func _notice(value: String, duration: float = 3.0) -> void:
 toast_text = value
 notice_time = duration
 notice_label.text = value

func _update_hud() -> void:
 if not is_instance_valid(objective):
  return
 var item = "ชุดยา" if order_kind == "medicine" else "ผลแล็บ"
 objective.text = ("ส่ง%sให้ผู้ป่วย" % item) if cargo == order_kind else ("รับ%sที่%s" % [item, "คลังยา" if order_kind == "medicine" else "ห้องแล็บ"])
 clock_label.text = "%02d:%02d" % [int(ceil(remaining)) / 60, int(ceil(remaining)) % 60]
 clock_label.modulate = CORAL if remaining < 30 else Color.WHITE
 score_label.text = "%04d คะแนน" % score
 combo_label.text = "ส่งแล้ว %d   พลาด %d/3" % [delivered, missed]
 if combo > 1:
  combo_label.text += "   ×%d" % combo
 cargo_label.text = "ในรถ: %s" % ("ชุดยา" if cargo == "medicine" else "ผลแล็บ" if cargo == "sample" else "ว่าง · ไปรับของกัน!")
 hint_button.text = "ซ่อนเส้นทาง [H]" if hint_on else "AI ช่วยบอกทาง [H]"
 interact_button.text = "ส่งให้ผู้ป่วย [E]" if cargo != "" else "รับของ [E]"

func _toggle_hint() -> void:
 if mode != "playing":
  return
 hint_on = not hint_on
 _notice("น้องเวร: ตามจุดสีฟ้ามาได้เลย!" if hint_on else "ซ่อนเส้นทางแล้ว")
 _update_hud()

func _nearest_station() -> String:
 var found = ""
 var distance = 115.0
 for key in STATIONS:
  var d = player.distance_to(STATIONS[key])
  if d < distance:
   distance = d
   found = key
 return found

func _interact() -> void:
 if mode != "playing":
  return
 var station = _nearest_station()
 if station.is_empty():
  _notice("เดินเข้าใกล้จุดรับหรือจุดส่งก่อนนะ")
  return
 if station == "ward":
  if cargo == order_kind:
   var earned = 100 + int(deadline) * 2 + mini(combo, 5) * 15
   score += earned
   delivered += 1
   combo += 1
   cargo = ""
   _burst(player, Color("ffdc80"))
   _notice("ส่งทันแล้ว! +%d   ช่วยสำเร็จ %d คน" % [earned, delivered])
   _sound("success")
   order_index += 1
   _next_order()
  elif cargo.is_empty():
   _notice("รถยังว่างอยู่ ไปรับของที่คลังยาหรือแล็บก่อน")
  else:
   _notice("คนไข้ต้องการ%s ลองเปลี่ยนของที่สถานีให้ถูกต้อง" % ("ชุดยา" if order_kind == "medicine" else "ผลแล็บ"))
 elif station == "supply" or station == "lab":
  cargo = "medicine" if station == "supply" else "sample"
  _sound("pickup")
  _burst(player, TEAL if station == "supply" else Color("c8a0f4"))
  _notice("รับ%sแล้ว! ไปที่ห้องผู้ป่วย" % ("ชุดยา" if cargo == "medicine" else "ผลแล็บ"))
 elif station == "lounge":
  _notice("คนไข้ฝากความหวังไว้กับเรา ไปส่งของให้ทันนะ!")
 _update_hud()

func _dash() -> void:
 if mode == "playing" and dash_cooldown <= 0:
  boost = 0.7
  dash_cooldown = 3.5
  _notice("ไปกันเลย!", 1)

func _pause() -> void:
 if mode != "playing":
  return
 mode = "paused"
 _clear_overlay()
 _panel(overlay, Rect2(0, 0, 1440, 900), Color("132e40ac"), 0)
 _panel(overlay, Rect2(440, 230, 560, 430), CREAM, 28)
 _label(overlay, "พักหายใจสักครู่", Rect2(485, 265, 500, 70), 40, INK, true)
 _label(overlay, "นาฬิกาหยุดแล้ว ทีมรอคุณอยู่", Rect2(485, 345, 490, 45), 22, Color("66838a"))
 _button(overlay, "กลับเข้าเวร", Rect2(485, 420, 470, 62), _resume)
 _button(overlay, "เริ่มใหม่", Rect2(485, 505, 224, 55), _start, Color("486c7c"))
 _button(overlay, "หน้าแรก", Rect2(730, 505, 225, 55), _menu, Color("486c7c"))
 _button(overlay, "ปิดเสียง" if sound_on else "เปิดเสียง", Rect2(485, 583, 470, 45), _toggle_sound, Color("768c91"))

func _resume() -> void:
 mode = "playing"
 overlay.queue_free()

func _help() -> void:
 mode = "help"
 _clear_overlay()
 _panel(overlay, Rect2(0, 0, 1440, 900), Color("102e40d5"), 0)
 _panel(overlay, Rect2(300, 145, 840, 620), CREAM, 30)
 _label(overlay, "เวรนี้เล่นอย่างไร?", Rect2(350, 180, 740, 75), 43, INK, true)
 var instructions = [
  "01  คลิกพื้น / WASD / ลูกศร เพื่อเดินเข็นรถ",
  "02  คลิกป้ายคลังยาหรือแล็บ เพื่อเดินไปรับของ",
  "03  ถึงป้ายแล้วรับส่งอัตโนมัติ หรือกด E เองได้",
  "04  ไปห้องผู้ป่วย กด E เพื่อส่งของให้ตรงคำขอ",
  "05  ส่งให้ทันแถบเวลาคนไข้ พลาดได้ไม่เกิน 3 ครั้ง",
  "H ให้หุ่นยนต์บอกทาง · Shift วิ่ง · Esc หยุดเวลา"
 ]
 for i in range(instructions.size()):
  _label(overlay, instructions[i], Rect2(355, 280 + i * 54, 740, 48), 23, INK)
 _button(overlay, "พร้อมแล้ว ไปเข้าเวรกัน!", Rect2(355, 650, 730, 64), _start)

func _finish() -> void:
 mode = "results"
 saved_best = maxi(saved_best, score)
 _save_best()
 _sound("success")
 _clear_overlay()
 _panel(overlay, Rect2(0, 0, 1440, 900), Color("102e40c8"), 0)
 _panel(overlay, Rect2(370, 130, 700, 640), CREAM, 34)
 _label(overlay, "SHIFT COMPLETE", Rect2(430, 164, 580, 35), 15, TEAL, true)
 _label(overlay, "ทีมเล็ก หัวใจใหญ่!", Rect2(427, 215, 600, 75), 46, INK, true)
 var stars = int(delivered >= 3) + int(delivered >= 6) + int(delivered >= 10)
 _label(overlay, "★".repeat(stars) + "☆".repeat(3 - stars), Rect2(430, 309, 580, 90), 66, Color("e9aa3d"), true)
 _label(overlay, "%d คะแนน" % score, Rect2(430, 425, 580, 70), 48, TEAL, true)
 _label(overlay, "ส่งสำเร็จ %d ครั้ง   ·   พลาด %d ครั้ง\nสถิติสูงสุด %d คะแนน" % [delivered, missed, saved_best], Rect2(430, 520, 590, 90), 23, INK)
 _button(overlay, "เข้าเวรอีกครั้ง", Rect2(430, 650, 355, 64), _start)
 _button(overlay, "หน้าแรก", Rect2(810, 650, 200, 64), _menu, Color("577484"))

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE:
   if mode == "playing":
    _pause()
   elif mode == "paused":
    _resume()
  if mode != "playing":
   return
  if event.keycode == KEY_E or event.keycode == KEY_SPACE:
   _interact()
  if event.keycode == KEY_H:
   _toggle_hint()
  if event.keycode == KEY_SHIFT:
   _dash()

func _unhandled_input(event: InputEvent) -> void:
 if mode != "playing":
  return
 var point = Vector2.ZERO
 var clicked = false
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  point = get_global_mouse_position()
  clicked = true
 elif event is InputEventScreenTouch and event.pressed:
  point = event.position
  clicked = true
 if not clicked:
  return
 pending_station = ""
 for key in STATIONS:
  if point.distance_to(STATIONS[key] + Vector2(0, -80)) < 77 or point.distance_to(STATIONS[key]) < 65:
   _go_to(STATIONS[key])
   pending_station = key
   return
 _go_to(point)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "playing" and not debug_mode:
  _pause()

func _process(delta: float) -> void:
 animation_time += delta
 web_status_elapsed += delta
 if OS.has_feature("web") and web_status_elapsed > 0.25:
  web_status_elapsed = 0.0
  _web_status()
 if mode == "playing":
  remaining = maxf(0, remaining - delta)
  deadline -= delta
  dash_cooldown = maxf(0, dash_cooldown - delta)
  boost = maxf(0, boost - delta)
  notice_time = maxf(0, notice_time - delta)
  notice_label.visible = notice_time > 0
  var movement = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
  if movement.length_squared() > 0:
   route.clear()
   pending_station = ""
   movement = movement.normalized()
  elif not route.is_empty():
   if player.distance_to(route[0]) < 12:
    route.remove_at(0)
   if not route.is_empty():
    movement = player.direction_to(route[0])
  moving = movement.length_squared() > 0.01
  var next = player + movement * (400 if boost > 0 else 245) * delta
  if _walkable(Vector2(next.x, player.y)):
   player.x = next.x
  if _walkable(Vector2(player.x, next.y)):
   player.y = next.y
  if moving:
   step_phase += delta * 13
  robot = robot.lerp(player + Vector2(-70, 28), 1 - exp(-delta * 3))
  if route.is_empty() and pending_station != "" and player.distance_to(STATIONS[pending_station]) < 40:
   pending_station = ""
   _interact()
  if deadline <= 0:
   missed += 1
   combo = 0
   cargo = ""
   order_index += 1
   _notice("ช้าไปนิด! คนไข้รายใหม่ต้องการคุณ ไปต่อกันนะ")
   _sound("miss")
   _next_order()
  if remaining <= 0 or missed >= 3:
   _finish()
  _update_hud()
 for particle in sparks:
  particle["position"] += particle["velocity"] * delta
  particle["velocity"].y += 170 * delta
  particle["life"] -= delta
 sparks = sparks.filter(func(p): return p["life"] > 0)
 queue_redraw()

func _text(value: String, p: Vector2, font_size: int = 20, color: Color = CREAM) -> void:
 draw_string(BOLD, p, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _rounded(rect: Rect2, color: Color, radius: int = 14, border: Color = Color.TRANSPARENT) -> void:
 var style = StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(radius)
 if border.a > 0:
  style.border_color = border
  style.set_border_width_all(2)
 draw_style_box(style, rect)

func _draw() -> void:
 draw_texture_rect(BACKGROUND, Rect2(0, 80, 1440, 810), false)
 # Edge shading keeps the playfield readable under the HUD.
 draw_rect(Rect2(0, 80, 1440, 30), Color(0.05, 0.15, 0.17, 0.15))
 if mode == "menu" or mode == "help":
  return
 # Walkable hint never teleports the player: it uses the same navigation graph.
 if hint_on and mode == "playing":
  var goal = STATIONS["ward"] if cargo == order_kind else STATIONS["supply"] if order_kind == "medicine" else STATIONS["lab"]
  var path = nav.get_point_path(_cell(player), _cell(goal))
  for i in range(0, path.size(), 3):
   draw_circle(path[i], 5 + sin(animation_time * 4 + i) * 1.5, Color("7effe0aa"))
 if not route.is_empty():
  for i in range(0, route.size(), 3):
   draw_circle(route[i], 3, Color("ffffff77"))
  draw_arc(route[-1], 16, 0, TAU, 24, Color("fff6db"), 2, true)
 _station_marker("supply", "คลังยา", "+", Color("359ee0"))
 _station_marker("lab", "ห้องแล็บ", "⚗", Color("a274e0"))
 _station_marker("ward", "ส่งให้ผู้ป่วย", "♡", CORAL)
 # A synthetic patient waiting at the ward door, with a readable deadline bar.
 _draw_patient(Vector2(1060, 602))
 _rounded(Rect2(1066, 530, 160, 35), CREAM, 10)
 _text(("ชุดยา" if order_kind == "medicine" else "ผลแล็บ") + "  %d วิ" % maxi(0, int(deadline)), Vector2(1078, 554), 16, INK)
 _rounded(Rect2(1068, 565, 154, 6), Color("3c666988"), 3)
 _rounded(Rect2(1068, 565, 154 * clampf(deadline / (38.0 if order_index < 2 else 30.0), 0, 1), 6), CORAL if deadline < 10 else TEAL, 3)
 _draw_robot(robot, 0.9)
 _draw_nurse(player, 1.0, sin(step_phase) * 2 if moving else sin(animation_time * 2) * 1.2)
 for particle in sparks:
  var col: Color = particle["color"]
  col.a = clampf(particle["life"], 0, 1)
  draw_circle(particle["position"], 4, col)
 # Small scenic elevator sign: the broken lift is a fixed part of this level.
 _rounded(Rect2(596, 189, 248, 40), Color("733c32e8"), 10, Color("ffc89588"))
 _text("ลิฟต์เสีย! ใช้ทางเดิน", Vector2(612, 216), 18, Color("ffd5a4"))

func _station_marker(key: String, title: String, symbol: String, color: Color) -> void:
 var p: Vector2 = STATIONS[key]
 var near = player.distance_to(p) < 115
 var active = (key == "ward" and cargo == order_kind) or (cargo != order_kind and ((key == "supply" and order_kind == "medicine") or (key == "lab" and order_kind == "sample")))
 var pulse = 1 + sin(animation_time * 3) * 0.06
 draw_arc(p, 32 * pulse if active else 28, 0, TAU, 48, Color(color, 0.6), 3, true)
 draw_circle(p, 24, Color(color, 0.12))
 var center = p + Vector2(0, -83)
 draw_circle(center + Vector2(0, 5), 31, Color("153b4d44"))
 draw_circle(center, 30, color)
 draw_arc(center, 30, 0, TAU, 40, CREAM, 3, true)
 if key == "lab":
  var shape = PackedVector2Array([center + Vector2(-7, -16), center + Vector2(-7, -5), center + Vector2(-17, 13), center + Vector2(-14, 17), center + Vector2(14, 17), center + Vector2(17, 13), center + Vector2(7, -5), center + Vector2(7, -16)])
  draw_polyline(shape, CREAM, 3, true)
  draw_line(center + Vector2(-10, -17), center + Vector2(10, -17), CREAM, 3, true)
  draw_line(center + Vector2(-11, 7), center + Vector2(11, 7), CREAM, 3, true)
 elif key == "ward":
  draw_line(center + Vector2(-17, -8), center + Vector2(-17, 17), CREAM, 3, true)
  draw_line(center + Vector2(-17, 9), center + Vector2(17, 9), CREAM, 3, true)
  draw_line(center + Vector2(17, 3), center + Vector2(17, 17), CREAM, 3, true)
  _rounded(Rect2(center + Vector2(-11, -7), Vector2(25, 13)), CREAM, 3)
 else:
  _text(symbol, center + Vector2(-13, 11), 32, CREAM)
 _rounded(Rect2(p.x - 83, p.y - 47, 166, 30), Color("fff9efef"), 9)
 _text(title, Vector2(p.x - 71, p.y - 26), 16, INK)
 if near:
  _rounded(Rect2(p.x - 70, p.y + 35, 140, 29), TEAL, 9)
  _text("[E] รับ / ส่ง", p + Vector2(-56, 56), 15, CREAM)

func _draw_nurse(p: Vector2, scale_value: float, bob: float) -> void:
 draw_set_transform(p, 0, Vector2.ONE * scale_value)
 draw_set_transform(p, 0, Vector2(scale_value, scale_value * 0.36))
 draw_circle(Vector2(4, 6), 54, Color("1e3e4e35"))
 draw_set_transform(p + Vector2(0, bob), 0, Vector2.ONE * scale_value)
 if nurse_texture:
  draw_texture_rect(nurse_texture, Rect2(-77, -168, 154, 193), false)
 else:
  _rounded(Rect2(-28, -52, 47, 58), Color("298bc0"), 13)
  draw_circle(Vector2(-5, -79), 29, Color("f0c199"))
  draw_circle(Vector2(-7, -96), 24, Color("513d35"))
  draw_circle(Vector2(-15, -79), 3, INK)
  draw_circle(Vector2(6, -79), 3, INK)
  _rounded(Rect2(10, -20, 66, 44), Color("d6e6dc"), 8)
  draw_circle(Vector2(22, 29), 9, INK)
  draw_circle(Vector2(64, 29), 9, INK)
 if mode != "menu" and mode != "help":
  _rounded(Rect2(-29, -167, 58, 27), Color("278ac1"), 9, CREAM)
  _text("P1", Vector2(-15, -146), 17, CREAM)
  if cargo != "":
   _rounded(Rect2(23, -53, 44, 35), TEAL if cargo == "medicine" else Color("a274e0"), 8, CREAM)
   _text("+" if cargo == "medicine" else "L", Vector2(35, -27), 26)
 draw_set_transform(Vector2.ZERO)

func _draw_robot(p: Vector2, size_value: float) -> void:
 var bob = sin(animation_time * 3) * 4
 draw_set_transform(p, 0, Vector2(size_value, size_value * 0.36))
 draw_circle(Vector2.ZERO, 30, Color("1e3e4e30"))
 draw_set_transform(p + Vector2(0, bob), 0, Vector2.ONE * size_value)
 if robot_texture:
  draw_texture_rect(robot_texture, Rect2(-55, -100, 110, 110), false)
  draw_set_transform(Vector2.ZERO)
  return
 _rounded(Rect2(-22, -32, 44, 42), Color("dbece3"), 14, Color("9ac7bc"))
 _rounded(Rect2(-32, -76, 64, 51), Color("f6fff4"), 20, Color("a6cfc0"))
 _rounded(Rect2(-25, -68, 50, 31), Color("163e4c"), 12)
 draw_arc(Vector2(-10, -50), 6, PI, TAU, 12, Color("7cffe0"), 3, true)
 draw_arc(Vector2(10, -50), 6, PI, TAU, 12, Color("7cffe0"), 3, true)
 draw_circle(Vector2(0, -12), 7, TEAL)
 _rounded(Rect2(-32, -25, 10, 26), TEAL, 5)
 _rounded(Rect2(22, -25, 10, 26), TEAL, 5)
 _rounded(Rect2(-18, 5, 12, 10), INK, 4)
 _rounded(Rect2(6, 5, 12, 10), INK, 4)
 draw_set_transform(Vector2.ZERO)

func _draw_patient(p: Vector2) -> void:
 draw_set_transform(p)
 draw_circle(Vector2(0, -42), 18, Color("f0c4a0"))
 draw_circle(Vector2(-2, -54), 17, Color("6f5142"))
 _rounded(Rect2(-19, -26, 38, 41), CORAL, 11)
 _rounded(Rect2(-17, 9, 13, 24), Color("566f7d"), 5)
 _rounded(Rect2(4, 9, 13, 24), Color("566f7d"), 5)
 draw_set_transform(Vector2.ZERO)

func _burst(p: Vector2, color: Color) -> void:
 for i in range(20):
  var angle = float(i) / 20 * TAU
  sparks.append({"position": p + Vector2(0, -45), "velocity": Vector2(cos(angle), sin(angle)) * (65 + i * 4), "life": 1.2, "color": color})

func _setup_audio() -> void:
 music = AudioStreamPlayer.new()
 music.stream = load("res://assets/shift_music.wav")
 music.volume_db = -22
 add_child(music)
 music.finished.connect(func():
  if sound_on:
   music.play()
 )
 sfx = AudioStreamPlayer.new()
 sfx.volume_db = -11
 add_child(sfx)

func _sound(kind: String) -> void:
 if not sound_on:
  return
 if not music.playing:
  music.play()
 sfx.stream = load("res://assets/%s.wav" % kind)
 sfx.play()

func _toggle_sound() -> void:
 sound_on = not sound_on
 if not sound_on:
  music.stop()
  sfx.stop()
 else:
  music.play()
 if mode == "menu":
  _menu()
 elif mode == "paused":
  mode = "playing"
  _pause()

func _load_best() -> void:
 var config = ConfigFile.new()
 if config.load("user://hospital.cfg") == OK:
  saved_best = int(config.get_value("records", "best", 0))

func _save_best() -> void:
 var config = ConfigFile.new()
 config.set_value("records", "best", saved_best)
 config.save("user://hospital.cfg")

func _web_status() -> void:
 # A read-only snapshot and accessible canvas description for the web host.
 var snapshot = JSON.stringify({"mode": mode, "score": score, "delivered": delivered, "missed": missed, "cargo": cargo, "order": order_kind, "remaining": int(ceil(remaining)), "x": int(player.x), "y": int(player.y)})
 var description = "โรงพยาบาลวิกฤต ส่งสำเร็จ %d ครั้ง คะแนน %d. ใช้ WASD หรือลูกศรเดิน E รับส่งของ H บอกทาง Esc หยุดเกม" % [delivered, score]
 JavaScriptBridge.eval("document.getElementById('canvas').dataset.gameState = %s; document.getElementById('canvas').setAttribute('aria-label', %s);" % [JSON.stringify(snapshot), JSON.stringify(description)])

func _smoke_test() -> void:
 # Exercise real gameplay rules and navigation in headless Godot.
 # The headless audio driver is silent; browser input tests cover audio startup.
 sound_on = false
 assert(BOLD.has_char(0x30) and BOLD.has_char(0x2605) and BOLD.has_char(0x0E01), "Thai, digits and stars must have glyphs")
 _start()
 assert(mode == "playing" and remaining == 180.0)
 assert(not _walkable(Vector2(200, 650)))
 _go_to(STATIONS["supply"])
 assert(not route.is_empty(), "Supply route must be reachable")
 for point in route:
  assert(_walkable(point), "Route must not pass through furniture")
 player = STATIONS["supply"]
 _interact()
 assert(cargo == "medicine")
 player = STATIONS["ward"]
 _interact()
 assert(delivered == 1 and score > 100 and cargo.is_empty())
 assert(order_kind == "sample")
 player = STATIONS["supply"]
 _interact()
 player = STATIONS["ward"]
 _interact()
 assert(delivered == 1, "Wrong item must not count")
 player = STATIONS["lab"]
 _interact()
 player = STATIONS["ward"]
 _interact()
 assert(delivered == 2)
 _pause()
 var before = remaining
 _process(1)
 assert(remaining == before, "Pause must freeze the clock")
 _resume()
 _dash()
 assert(boost > 0 and dash_cooldown > 0)
 deadline = 0.01
 _process(0.1)
 assert(missed == 1 and combo == 0)
 remaining = 0.01
 _process(0.1)
 assert(mode == "results")
 _start()
 assert(delivered == 0 and missed == 0 and score == 0 and cargo.is_empty())
 print("GODOT SMOKE PASS: navigation, pickup, delivery, wrong cargo, lab, pause, dash, deadline, results, replay")
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().quit(0)
