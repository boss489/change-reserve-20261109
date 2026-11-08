extends Control

const Ledger = preload("res://scripts/ledger.gd")
const SAVE := "user://reserve.json"
const CREAM := Color("f8edd5")
const INK := Color("182b37")
const TEAL := Color("186763")
const GOLD := Color("d39843")
const RED := Color("ac4b48")
var state: Dictionary = Ledger.fresh()
var panel: VBoxContainer
var scroll: ScrollContainer
var sound_enabled := false
var shake_enabled := false
var resume_mode := "game"
var tutorial_step := 0
var audio := AudioStreamPlayer.new()
var font: FontFile = preload("res://assets/NanumGothic-Regular.ttf")

func _ready() -> void:
 add_child(audio)
 theme = Theme.new()
 theme.default_font = font
 theme.default_font_size = 19
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 get_viewport().size_changed.connect(_on_resize)
 _load()
 _render()

func _on_resize() -> void:
 queue_redraw()
 if panel: panel.custom_minimum_size.x = minf(760.0, maxf(300.0, size.x - 30.0))

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size), Color("12363c"))
 for i in 26:
  var x := fmod(float(i*149+39), maxf(size.x,1.0))
  var y := fmod(float(i*223+18), maxf(size.y,1.0))
  draw_circle(Vector2(x,y), float(8+i%4*6),Color(0.87,0.67,0.36,0.09))
 draw_rect(Rect2(0,0,size.x,9), GOLD)

func _style(bg: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = bg
 s.border_color = border
 s.set_border_width_all(2 if border.a > 0 else 0)
 s.set_corner_radius_all(15)
 s.set_content_margin_all(15)
 return s

func _button(text: String, action: Callable, tone: Color = TEAL) -> Button:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size = Vector2(150,54)
 b.add_theme_font_override("font",font)
 b.add_theme_font_size_override("font_size",19)
 b.add_theme_color_override("font_color",CREAM)
 b.add_theme_color_override("font_hover_color",Color.WHITE)
 b.add_theme_color_override("font_focus_color",Color.WHITE)
 b.add_theme_stylebox_override("normal",_style(tone))
 b.add_theme_stylebox_override("hover",_style(tone.lightened(0.14)))
 b.add_theme_stylebox_override("pressed",_style(tone.darkened(0.15)))
 b.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,GOLD))
 b.pressed.connect(action)
 return b

func _label(text: String, scale: int = 19, color: Color = INK) -> Label:
 var l := Label.new()
 l.text = text
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_override("font",font)
 l.add_theme_font_size_override("font_size",scale)
 l.add_theme_color_override("font_color",color)
 return l

func _card(title: String, body: String = "") -> VBoxContainer:
 var c := VBoxContainer.new()
 c.add_theme_constant_override("separation",8)
 c.add_theme_stylebox_override("panel",_style(CREAM))
 var wrapper := PanelContainer.new()
 wrapper.add_theme_stylebox_override("panel",_style(CREAM))
 wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_child(wrapper)
 wrapper.add_child(c)
 c.add_child(_label(title,23,TEAL))
 if body != "": c.add_child(_label(body))
 return c

func _row(parent: Node) -> HFlowContainer:
 var r := HFlowContainer.new()
 r.add_theme_constant_override("h_separation",9)
 r.add_theme_constant_override("v_separation",9)
 parent.add_child(r)
 return r

func _render() -> void:
 var previous_scroll := scroll.scroll_vertical if is_instance_valid(scroll) and str(state.mode)=="game" else 0
 for child in get_children():
  if child != audio: child.queue_free()
 scroll = ScrollContainer.new()
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 var center := CenterContainer.new()
 center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 center.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 scroll.add_child(center)
 panel = VBoxContainer.new()
 panel.custom_minimum_size.x = minf(760.0,maxf(300.0,size.x-30.0))
 panel.add_theme_constant_override("separation",13)
 center.add_child(panel)
 var top_spacer := Control.new()
 top_spacer.custom_minimum_size.y=14
 panel.add_child(top_spacer)
 panel.add_child(_label("  ◈  작은 가게의 일곱 날",18,GOLD))
 panel.add_child(_label("잔돈 여유분",42,CREAM))
 panel.add_child(_label("손님에게 줄 동전은 먼저 금고에 있어야 합니다.",17,CREAM))
 match str(state.mode):
  "title": _title()
  "tutorial": _tutorial()
  "game": _game()
  "review": _review()
  "won", "lost": _ending()
 var foot := _card("조작 안내", "키보드 1 / 5 / 0: 동전 추가  ·  Enter: 판매 확인  ·  Z: 되돌리기  ·  Esc: 제목\n마우스와 터치: 모든 단추 사용 가능. 저장은 이 브라우저에만 남습니다.")
 foot.add_child(_label("자작 장부·동전 도형 | Nanum Gothic (SIL OFL)",14))
 if previous_scroll > 0: _restore_scroll.call_deferred(previous_scroll)

func _restore_scroll(value: int) -> void:
 await get_tree().process_frame
 if is_instance_valid(scroll): scroll.scroll_vertical = value

func _title() -> void:
 var c := _card("오늘의 규칙", "7일 동안 매일 4명의 손님 중 최소 3명에게 판매하세요. 총 25건을 달성하면 승리!\n현재 금고에서만 거스름돈을 골라 지불합니다. 손님 동전은 판매 후에 들어옵니다. 가격과 손님의 지불 동전, 다음 손님을 모두 볼 수 있습니다.")
 var r := _row(c)
 r.add_child(_button("학습하고 새로 시작",func(): state=Ledger.fresh(); state.mode="tutorial"; tutorial_step=0; _save(); _render()))
 if FileAccess.file_exists(SAVE):
  r.add_child(_button("저장된 영업 계속",func(): state.mode=resume_mode; _save(); _render(),GOLD))
 var settings := _card("접근성 설정", "소리는 기본 꺼짐이며 효과음과 화면 흔들림을 따로 켤 수 있습니다. 색뿐 아니라 숫자와 도형으로 동전을 구분합니다.")
 _settings(settings)

func _settings(c: VBoxContainer) -> void:
 var r := _row(c)
 r.add_child(_button("효과음: " + ("켬" if sound_enabled else "끔"),func(): sound_enabled = not sound_enabled; _save(); _render(),GOLD))
 r.add_child(_button("화면 흔들림: " + ("켬" if shake_enabled else "끔"),func(): shake_enabled = not shake_enabled; _save(); _render(),GOLD))

func _tutorial() -> void:
 var txt := "첫 손님: 물건 7원 · 지불 10원 동전 1개. 거스름 3원이 필요해요.\n금고에 1원 동전 8개가 있습니다. 1원 세 개를 골라 확인하세요. 받은 10원은 그때 금고에 추가됩니다." if tutorial_step==0 else "1원 버튼을 세 번 눌러 3원을 만드세요. 판매 후 금고 1원은 8→5개, 10원은 1→2개. 잘못 골랐다면 ‘선택 지우기’를 누르세요.\n지금부터 이 거래를 직접 해 보세요!"
 var c := _card("짧은 거래 학습 · %d / 2" % (tutorial_step+1),txt)
 if tutorial_step == 0:
  c.add_child(_button("다음: 직접 거래하기",func(): tutorial_step=1; _render()))
 else:
  state.mode="game"
  _game()
  c.add_child(_button("설명 다시 보기",func(): state.mode="tutorial"; tutorial_step=0; _render(),GOLD))

func _game() -> void:
 var d := int(state.day)
 var header := _card("영업 %d일차 / 7일" % (d+1),"오늘 %d / %d건 · 전체 %d / %d건 · 남은 손님 %d명" % [int(state.daily),Ledger.DAILY_GOAL,int(state.sold),Ledger.TOTAL_GOAL,Ledger.remaining(state)])
 header.add_child(_label("금고 잔액 %d원  |  1원 ◯ ×%d   5원 ◇ ×%d   10원 ■ ×%d" % [Ledger.amount(state.vault),int(state.vault[0]),int(state.vault[1]),int(state.vault[2])],19))
 var queue := _card("공개된 다음 손님", "가격 / 지불 동전 → 필요한 거스름")
 for i in range(int(state.cursor),Ledger.DAYS[d].size()):
  var c: Array = Ledger.DAYS[d][i]
  var pay: Array = c[1]
  queue.add_child(_label(("▶ " if i==int(state.cursor) else "   ")+"%d번 · %d원 / ◯%d ◇%d ■%d → %d원" % [i+1,int(c[0]),int(pay[0]),int(pay[1]),int(pay[2]),Ledger.amount(pay)-int(c[0])],17))
 var due := Ledger.change_due(state)
 var p: Dictionary = Ledger.preview(state)
 var receipt := _card("영수증 · %d번 손님" % (int(state.cursor)+1),"가격 %d원  ·  받은 돈 %d원  ·  거스름 %d원" % [int(Ledger.customer(state)[0]),Ledger.amount(Ledger.customer(state)[1]),due])
 receipt.add_child(_label("지급 선택: ◯ 1원 ×%d  ◇ 5원 ×%d  ■ 10원 ×%d" % [int(state.selection[0]),int(state.selection[1]),int(state.selection[2])]))
 var r := _row(receipt)
 var symbols := ["◯ 1원 [1]","◇ 5원 [5]","■ 10원 [0]"]
 for i in 3:
  var index := i
  var b := _button(symbols[i],func(): _add_coin(index),GOLD)
  b.disabled = int(state.selection[i]) >= int(state.vault[i])
  r.add_child(b)
 r.add_child(_button("선택 지우기",func(): state.selection=[0,0,0]; _save(); _render(),RED))
 receipt.add_child(_label("미리보기: 선택 %d / 필요 %d원  ·  지급 뒤 금고 ◯%d ◇%d ■%d" % [int(p.given),int(p.due),int(p.after[0]),int(p.after[1]),int(p.after[2])],18,TEAL if p.valid else RED))
 receipt.add_child(_label("※ 받은 동전은 확인 후에만 더해집니다. 다음 거래 전에 보충됩니다.",15))
 var actions := _row(receipt)
 var confirm := _button("판매 확인 [Enter]",func(): _trade(true))
 confirm.disabled = not bool(p.valid)
 actions.add_child(confirm)
 actions.add_child(_button("손님 거절",func(): _trade(false),RED))
 actions.add_child(_button("되돌리기 [Z]",func(): state=Ledger.undo(state); _save(); _render(),GOLD))
 if str(state.notice)!="": receipt.add_child(_label(str(state.notice),17,RED))
 var bottom := _row(panel)
 bottom.add_child(_button("제목으로 [Esc]",func(): state.mode="title"; _save(); _render(),GOLD))

func _add_coin(index: int) -> void:
 if int(state.selection[index]) < int(state.vault[index]):
  state.selection[index] += 1
  _save()
  _render()

func _trade(accept: bool) -> void:
 var old_cursor := int(state.cursor)
 state = Ledger.apply(state,accept)
 _save()
 _render()
 if int(state.cursor)!=old_cursor:
  _feedback(accept)

func _review() -> void:
 var c := _card("%d일차 마감 · 오늘 %d건 판매" % [int(state.day)+1,int(state.daily)],"총 %d건 판매 · 거절 %d건 · 금고 %d원\n오늘 받은 동전은 내일 그대로 이월됩니다." % [int(state.sold),int(state.rejected),Ledger.amount(state.vault)])
 for reason in state.reasons: c.add_child(_label("• "+str(reason),17))
 c.add_child(_button("다음 날 / 최종 판정",func(): state=Ledger.next_day(state); _save(); _render()))
 c.add_child(_button("직전 거래 되돌리기",func(): state=Ledger.undo(state); _save(); _render(),GOLD))

func _ending() -> void:
 var c := _card("7일 성공!" if str(state.mode)=="won" else "영업 실패",str(state.notice)+"\n일별 판매 기록과 거절 사유를 확인하세요. 언제든 다시 시작할 수 있습니다.")
 for record in state.records:
  c.add_child(_label("%d일 · 판매 %d건 / 4명 · 거절 %d건" % [int(record.day),int(record.sold),int(record.rejected)],17))
  for reason in record.reasons: c.add_child(_label("  • "+str(reason),15))
 if str(state.mode)=="lost" and int(state.day)<7:
  c.add_child(_label("실패 지점: %d일 %d번째 손님 이후 · 오늘 %d건" % [int(state.day)+1,int(state.cursor),int(state.daily)],17,RED))
 var r := _row(c)
 r.add_child(_button("처음부터 재도전",func(): state=Ledger.fresh(); state.mode="tutorial"; _save(); _render()))
 r.add_child(_button("제목으로",func(): state.mode="title"; _save(); _render(),GOLD))

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if str(state.mode)=="game":
  match event.keycode:
   KEY_1: _add_coin(0)
   KEY_5: _add_coin(1)
   KEY_0: _add_coin(2)
   KEY_ENTER, KEY_KP_ENTER: _trade(true)
   KEY_Z: state=Ledger.undo(state); _save(); _render()
   KEY_ESCAPE: state.mode="title"; _save(); _render()
 elif event.keycode==KEY_ESCAPE and str(state.mode)=="tutorial":
  state.mode="title"; _save(); _render()

func _save() -> void:
 if str(state.mode)!="title": resume_mode=str(state.mode)
 var file := FileAccess.open(SAVE,FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify({"state":state,"sound":sound_enabled,"shake":shake_enabled,"resume":resume_mode}))

func _load() -> void:
 if not FileAccess.file_exists(SAVE): return
 var file := FileAccess.open(SAVE,FileAccess.READ)
 if not file: return
 var parsed = JSON.parse_string(file.get_as_text())
 if typeof(parsed)!=TYPE_DICTIONARY: return
 sound_enabled = bool(parsed.get("sound",false))
 shake_enabled = bool(parsed.get("shake",false))
 var loaded = parsed.get("state",{})
 if typeof(loaded)==TYPE_DICTIONARY and Ledger.valid_state(loaded):
  state=loaded
  resume_mode=str(parsed.get("resume",state.mode))
  if resume_mode=="title": resume_mode="game" if int(state.day)<7 else "won"
  state.mode="title"

func _feedback(success: bool) -> void:
 if sound_enabled:
  var wave := AudioStreamWAV.new()
  wave.mix_rate = 22050
  wave.format = AudioStreamWAV.FORMAT_16_BITS
  var bytes := PackedByteArray()
  bytes.resize(4410)
  for i in 2205:
   var envelope := 1.0-float(i)/2205.0
   bytes.encode_s16(i*2,int(7500.0*envelope*sin(TAU*float(i)*(660.0 if success else 240.0)/22050.0)))
  wave.data=bytes
  audio.stream=wave
  audio.play()
 if shake_enabled and not success:
  var tween := create_tween()
  tween.tween_property(panel,"position:x",8.0,0.06)
  tween.tween_property(panel,"position:x",0.0,0.1)
