# 잔돈 여유분

Godot 4.7.2로 만든 독립 웹 퍼즐 게임. 작은 가게의 7일 영업에서 오늘 금고 동전으로만 잔돈을 내고, 매일 3건 이상·총 25건 이상 판매하세요. 받은 동전은 거래가 끝난 뒤에 들어옵니다.

## 실행 및 검증

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/ledger_test.gd
godot --headless --path . --script res://tests/ui_test.gd
godot --headless --path . --script res://tests/glyph_test.gd
godot --headless --path . --quit-after 4
godot --headless --path . --export-release Web docs/index.html
```

데스크톱 키보드: 1·5·0 동전 선택, Enter 판매, Z 되돌리기, Esc 제목. 버튼은 마우스·터치 공용이며 작은 화면에서는 카드가 세로 스크롤됩니다. 진행은 해당 브라우저의 Godot `user://reserve.json`에 저장됩니다.

## 웹 브라우저 검증

`evidence/`에는 공개 GitHub Pages에서 캡처한 데스크톱 제목·학습·첫 거래·저장 후 재개, 390×844 모바일의 영업 진행·7일 성공(28건)·영업 실패·재시작 화면이 있습니다. `tests/ledger_test.gd`는 7일 성공 입력 경로를 출력합니다.

## 아트 및 라이선스

짙은 청록 바탕, 종이 장부 카드와 동전 기호·동적 장식은 이 프로젝트에서 직접 그린 Godot Control/CanvasItem 도형입니다. Nanum Gothic 글꼴은 SIL Open Font License 1.1로 배포되며 원문은 `assets/OFL.txt`에 있습니다. 나머지 소스·자작 아트는 MIT 라이선스입니다.
