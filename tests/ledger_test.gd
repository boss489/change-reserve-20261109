extends SceneTree
const L = preload("res://scripts/ledger.gd")
var visits := 0
var failures := 0
var memo := {}

func _initialize() -> void:
 run_tests()
 quit(1 if failures else 0)

func assert_true(value: bool, why: String) -> void:
 if not value:
  failures += 1
  push_error("FAIL: " + why)

func choices(vault: Array, due: int) -> Array:
 var found := []
 for tens in range(mini(vault[2],due/10)+1):
  for fives in range(mini(vault[1],due/5)+1):
   var ones := due - 10*tens - 5*fives
   if ones>=0 and ones<=int(vault[0]): found.append([ones,fives,tens])
 return found

func win_path(s: Dictionary) -> bool:
 if str(s.mode)=="won": return true
 if str(s.mode)=="lost": return false
 if str(s.mode)=="review": return win_path(L.next_day(s))
 var key := "%d,%d,%d,%d,%d,%d,%d" % [int(s.day),int(s.cursor),int(s.vault[0]),int(s.vault[1]),int(s.vault[2]),int(s.daily),int(s.sold)]
 if memo.has(key): return false
 memo[key]=true
 visits += 1
 for x in choices(s.vault,L.change_due(s)):
  s.selection=x
  if win_path(L.apply(s,true)): return true
 if win_path(L.apply(s,false)): return true
 return false

func run_tests() -> void:
 var s := L.fresh()
 s.mode="game"
 assert_true(L.amount(s.vault)==28,"initial balance")
 assert_true(L.change_due(s)==3,"first change")
 assert_true(not L.preview(s).valid,"empty selection invalid")
 s.selection=[3,0,0]
 var p: Dictionary = L.preview(s)
 assert_true(p.valid and p.after==[5,2,1],"preview excludes tender")
 var first := L.apply(s,true)
 assert_true(first.vault==[5,2,2] and L.amount(first.vault)==35,"first trade + price")
 assert_true(L.undo(first).vault==s.vault,"undo vault")
 assert_true(L.undo(first).cursor==0,"undo position")
 var reject := L.apply(s,false)
 assert_true(reject.vault==s.vault and reject.rejected==1,"reject conserves")
 for d in L.DAYS:
  assert_true(d.size()>=4 and d.size()<=6,"daily queue length")
  for c in d:
   assert_true(L.amount(c[1])>=int(c[0]),"legal tender")
 var start := L.fresh()
 start.mode="game"
 assert_true(win_path(start),"7-day winning path exists")
 print("PASS: 7-day reachable victory, ",visits," explored states; preview/undo/reject/amount/queue")
