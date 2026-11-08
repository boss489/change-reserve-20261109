extends RefCounted
class_name Ledger

const DENOMS := [1, 5, 10]
const DAILY_GOAL := 3
const TOTAL_GOAL := 25
const START := [8, 2, 1]
# Each customer: price and the exact coins tendered [1, 5, 10].
const DAYS := [
 [[7,[0,0,1]],[6,[0,0,1]],[5,[10,0,0]],[9,[0,0,1]]],
 [[8,[0,0,1]],[12,[0,1,1]],[5,[10,0,0]],[14,[0,1,1]]],
 [[13,[0,1,1]],[7,[0,0,1]],[5,[10,0,0]],[9,[0,0,1]]],
 [[6,[0,0,1]],[11,[0,1,1]],[5,[10,0,0]],[8,[0,0,1]]],
 [[14,[0,1,1]],[8,[0,0,1]],[5,[10,0,0]],[7,[0,0,1]]],
 [[9,[0,0,1]],[12,[0,1,1]],[5,[10,0,0]],[6,[0,0,1]]],
 [[7,[0,0,1]],[13,[0,1,1]],[5,[10,0,0]],[8,[0,0,1]]]
]

static func amount(coins: Array) -> int:
 return int(coins[0]) + 5 * int(coins[1]) + 10 * int(coins[2])

static func fresh() -> Dictionary:
 return {"day":0,"cursor":0,"vault":START.duplicate(),"sold":0,"daily":0,"rejected":0,"reasons":[],"history":[],"records":[],"mode":"title","selection":[0,0,0],"notice":""}

static func customer(state: Dictionary) -> Array:
 return DAYS[int(state.day)][int(state.cursor)]

static func change_due(state: Dictionary) -> int:
 var c := customer(state)
 return amount(c[1]) - int(c[0])

static func remaining(state: Dictionary) -> int:
 return DAYS[int(state.day)].size() - int(state.cursor)

static func preview(state: Dictionary) -> Dictionary:
 var choice: Array = state.selection
 var after: Array = state.vault.duplicate()
 for i in 3:
  after[i] -= int(choice[i])
 return {"given":amount(choice),"due":change_due(state),"after":after,"valid":amount(choice)==change_due(state) and after.min()>=0}

static func snapshot(state: Dictionary) -> Dictionary:
 var copy := state.duplicate(true)
 copy.history = []
 return copy

static func apply(state: Dictionary, accept: bool) -> Dictionary:
 var next := state.duplicate(true)
 if str(next.mode) != "game":
  return next
 if accept and not preview(next).valid:
  next.notice = "거스름 구성이 정확하지 않아요. 금고 동전만 사용하세요."
  return next
 var prior := snapshot(next)
 next.history.append(prior)
 var c := customer(next)
 if accept:
  for i in 3:
   next.vault[i] = int(next.vault[i]) - int(next.selection[i]) + int(c[1][i])
  next.sold += 1
  next.daily += 1
  next.notice = "판매 완료 · 받은 동전은 지금부터 금고에 들어옵니다."
 else:
  next.rejected += 1
  var why := "잔돈을 남기기 위해 거절" if preview(next).valid else "현재 거스름 구성 부족으로 거절"
  next.reasons.append("%d번째 손님: %s" % [int(next.cursor)+1,why])
  next.notice = why
 next.cursor += 1
 next.selection = [0,0,0]
 if int(next.daily) + remaining(next) < DAILY_GOAL:
  next.mode = "lost"
  next.notice = "오늘 목표 불가능 · 남은 손님을 모두 받아도 %d건 미만" % DAILY_GOAL
 elif int(next.sold) + remaining(next) + future_customers(int(next.day)) < TOTAL_GOAL:
  next.mode = "lost"
  next.notice = "7일 목표 불가능 · 남은 손님을 모두 받아도 %d건 미만" % TOTAL_GOAL
 elif int(next.cursor) >= DAYS[int(next.day)].size():
  next.mode = "review"
 return next

static func future_customers(day: int) -> int:
 var count := 0
 for d in range(day+1,DAYS.size()):
  count += DAYS[d].size()
 return count

static func next_day(state: Dictionary) -> Dictionary:
 var next := state.duplicate(true)
 if str(next.mode) != "review":
  return next
 next.records.append({"day":int(next.day)+1,"sold":int(next.daily),"rejected":int(next.rejected),"reasons":next.reasons.duplicate()})
 next.day += 1
 next.cursor = 0
 next.daily = 0
 next.rejected = 0
 next.reasons = []
 next.history = []
 next.selection = [0,0,0]
 if int(next.day) == DAYS.size():
  next.mode = "won" if int(next.sold) >= TOTAL_GOAL else "lost"
  next.notice = "7일 영업 완료 · 총 %d건 / 목표 %d건" % [int(next.sold),TOTAL_GOAL]
 else:
  next.mode = "game"
  next.notice = "동전은 그대로 이월되었습니다."
 return next

static func undo(state: Dictionary) -> Dictionary:
 if state.history.is_empty():
  return state.duplicate(true)
 var copy := state.duplicate(true)
 var previous: Dictionary = copy.history.pop_back()
 previous.history = copy.history
 previous.notice = "직전 거래를 되돌렸습니다."
 return previous

static func valid_state(s: Dictionary) -> bool:
 for field in ["vault","day","mode","selection","cursor","sold","daily","rejected","reasons","history","records","notice"]:
  if not s.has(field): return false
 if typeof(s.vault)!=TYPE_ARRAY or typeof(s.selection)!=TYPE_ARRAY:
  return false
 if s.vault.size()!=3 or s.selection.size()!=3 or int(s.day)<0 or int(s.day)>7:
  return false
 if not str(s.mode) in ["title","tutorial","game","review","won","lost"]: return false
 if int(s.day)==7 and str(s.mode) in ["game","review","tutorial"]: return false
 if int(s.day)<7 and (int(s.cursor)<0 or int(s.cursor)>DAYS[int(s.day)].size()): return false
 for x in s.vault:
  if int(x)<0:
   return false
 for x in s.selection:
  if int(x)<0: return false
 return true
