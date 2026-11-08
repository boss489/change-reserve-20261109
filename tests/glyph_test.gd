extends SceneTree

func _initialize() -> void:
 var font: FontFile=load("res://assets/NanumGothic-Regular.ttf")
 var seen: Dictionary={}
 var missing: Array=[]
 for file_name in ["res://scripts/main.gd","res://scripts/ledger.gd"]:
  var source:=FileAccess.get_file_as_string(file_name)
  for i in source.length():
   var c:=source.substr(i,1)
   var code:=c.unicode_at(0)
   if code<128 or seen.has(code): continue
   seen[code]=true
   if not font.has_char(code): missing.append("%s U+%04X" % [c,code])
 print("Glyph coverage: %d non-ASCII codepoints, %d missing: %s" % [seen.size(),missing.size(),str(missing)])
 if not missing.is_empty(): quit(1)
 else: quit(0)
