#!/usr/bin/env python3
"""한밭대 학식(백반)·기숙사 식단을 모아 assets/data/meals.json 으로 저장한다.

사용법 (레포 최상위 폴더에서):
    python3 tools/crawl_meals.py            # meals.json 갱신
    python3 tools/crawl_meals.py --dry-run  # 파일은 그대로 두고 결과만 출력

- 파이썬 기본 라이브러리만 써서 따로 설치할 패키지가 없습니다.
- 학식: '금주의식단' 페이지가 내부적으로 부르는 JSON(getCalendar.do)을
  이번 주·다음 주 두 번 요청합니다. (학생식당 백반 = 교직원식당 메뉴와 동일)
- 기숙사: 생활관 '식단표' 페이지의 표를 읽습니다. (이번 주만 공개됨)
- 기존 meals.json과 합치고, 14일보다 오래된 날짜는 지웁니다.
- 학교 서버에 부담이 가지 않도록 일주일에 한 번(월요일 오전 추천)만 실행해 주세요.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

CAFETERIA_PAGE = "https://www.hanbat.ac.kr/prog/carteGuidance/kor/sub06_030301/C1/calendar.do"
CAFETERIA_API = "https://www.hanbat.ac.kr/prog/carteGuidance/kor/sub06_030301/C1/getCalendar.do"
DORM_PAGE = "https://dorm.hanbat.ac.kr/life-meal"

OUTPUT = Path(__file__).resolve().parent.parent / "assets" / "data" / "meals.json"
KEEP_DAYS = 14
USER_AGENT = "Mozilla/5.0 (hanbat_campus_app meal crawler; student project)"

# getCalendar.do 의 type 값 → 끼니
CAFETERIA_TYPES = {"A": "breakfast", "B": "lunch", "C": "dinner"}
# 기숙사 표의 열(data-content) → 끼니
DORM_COLUMNS = {"아침": "breakfast", "점심": "lunch", "저녁": "dinner"}


# ---------------------------------------------------------------------------
# 공통
# ---------------------------------------------------------------------------
def http(url: str, form: dict | None = None) -> str:
    body = urllib.parse.urlencode(form).encode() if form else None
    req = urllib.request.Request(url, data=body, headers={"User-Agent": USER_AGENT})
    if body:
        req.add_header("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
    with urllib.request.urlopen(req, timeout=15) as res:
        return res.read().decode("utf-8")


def clean_items(lines) -> list[str]:
    """빈 줄, 외국인 대체메뉴 안내, '<Plus Menu>' 표시를 빼고
    '&계란후라이'처럼 &로 시작하는 줄은 앞 메뉴에 붙인다."""
    items: list[str] = []
    for line in lines:
        line = line.strip()
        lower = line.lower()
        if not line or lower.startswith("(alternative") or lower == "<plus menu>":
            continue
        if line.startswith("&") and items:
            items[-1] += line
        else:
            items.append(line)
    return items


def monday_of(day: dt.date) -> dt.date:
    return day - dt.timedelta(days=day.weekday())


# ---------------------------------------------------------------------------
# 학식 (교직원식당 = 학생식당 백반)
# ---------------------------------------------------------------------------
def parse_cafeteria(payload: dict, week_start: dt.date) -> dict:
    """getCalendar.do 응답 → {'2026-11-23': {'lunch': [...]}, ...}
    menu1~menu5 가 월~금이다."""
    result: dict = {}
    for row in payload.get("item") or []:
        meal = CAFETERIA_TYPES.get(row.get("type"))
        if not meal:
            continue
        start = dt.date.fromisoformat(row.get("bgnde") or week_start.isoformat())
        for i in range(5):
            items = clean_items((row.get(f"menu{i + 1}") or "").splitlines())
            if items:
                day = (start + dt.timedelta(days=i)).isoformat()
                result.setdefault(day, {})[meal] = items
    return result


def fetch_cafeteria(today: dt.date) -> dict:
    result: dict = {}
    this_week = monday_of(today)
    for week in (this_week, this_week + dt.timedelta(days=7)):
        text = http(CAFETERIA_API, {"bgnde": week.isoformat()})
        result.update(parse_cafeteria(json.loads(text), week))
    return result


# ---------------------------------------------------------------------------
# 기숙사 (BTL관 주간 식단표)
# ---------------------------------------------------------------------------
class _DormTableParser(HTMLParser):
    """<table class="tbl ..."> 하나를 읽어 caption과 행(셀별 <li> 목록)을 모은다."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.caption = ""
        self.rows: list[dict] = []
        self._in_table = False
        self._done = False
        self._in_caption = False
        self._row: dict | None = None
        self._cell: dict | None = None
        self._li: str | None = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "table" and not self._done and "tbl" in (attrs.get("class") or "").split():
            self._in_table = True
            return
        if not self._in_table:
            return
        if tag == "caption":
            self._in_caption = True
        elif tag == "tr":
            self._row = {}
        elif tag == "td" and self._row is not None:
            self._cell = {"key": attrs.get("data-content", ""), "text": "", "items": []}
        elif tag == "li" and self._cell is not None:
            self._li = ""

    def handle_endtag(self, tag):
        if not self._in_table:
            return
        if tag == "caption":
            self._in_caption = False
        elif tag == "li" and self._li is not None and self._cell is not None:
            self._cell["items"].append(self._li)
            self._li = None
        elif tag == "td" and self._cell is not None and self._row is not None:
            self._row[self._cell["key"]] = self._cell
            self._cell = None
        elif tag == "tr" and self._row is not None:
            if self._row:
                self.rows.append(self._row)
            self._row = None
        elif tag == "table":
            self._in_table = False
            self._done = True

    def handle_data(self, data):
        if not self._in_table:
            return
        if self._in_caption:
            self.caption += data
        elif self._li is not None:
            self._li += data
        elif self._cell is not None:
            self._cell["text"] += data


def parse_dorm(html: str) -> dict:
    parser = _DormTableParser()
    parser.feed(html)
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", parser.caption)
    if not m:
        raise ValueError("기숙사 식단표를 찾지 못했어요. 사이트 구조가 바뀌었는지 확인해 주세요.")
    year, first_month = int(m.group(1)), int(m.group(2))

    result: dict = {}
    for row in parser.rows:
        day_cell = row.get("요일")
        dm = re.search(r"(\d+)월\s*(\d+)일", day_cell["text"]) if day_cell else None
        if not dm:
            continue
        month, day = int(dm.group(1)), int(dm.group(2))
        y = year + 1 if month < first_month else year  # 12월 → 1월로 넘어가는 주
        meals = {}
        for column, key in DORM_COLUMNS.items():
            items = clean_items(row[column]["items"]) if column in row else []
            if items:
                meals[key] = items
        if meals:
            result[dt.date(y, month, day).isoformat()] = meals
    return result


def fetch_dorm() -> dict:
    return parse_dorm(http(DORM_PAGE))


# ---------------------------------------------------------------------------
# 저장
# ---------------------------------------------------------------------------
def merge(old: dict | None, new: dict, today: dt.date) -> dict:
    cutoff = (today - dt.timedelta(days=KEEP_DAYS)).isoformat()
    merged = {day: v for day, v in (old or {}).items() if day >= cutoff}
    merged.update(new)
    return dict(sorted(merged.items()))


def build_data(existing: dict, cafeteria: dict, dorm: dict, today: dt.date, now: dt.datetime) -> dict:
    return {
        "note": "tools/crawl_meals.py가 만든 파일이에요. 직접 고치지 말고 스크립트를 다시 실행해 주세요.",
        "updatedAt": now.isoformat(timespec="minutes"),
        "sources": {"cafeteria": CAFETERIA_PAGE, "dorm": DORM_PAGE},
        "cafeteria": merge(existing.get("cafeteria"), cafeteria, today),
        "dorm": merge(existing.get("dorm"), dorm, today),
    }


def dump(data: dict) -> str:
    """메뉴 목록은 한 줄로 써서 파일을 읽기 쉽게 만든다."""
    text = json.dumps(data, ensure_ascii=False, indent=2)
    # ["백미밥",\n      "국", ...] → ["백미밥", "국", ...]
    return re.sub(
        r"\[\s*((?:\"[^\"\n]*\",?\s*)+)\]",
        lambda m: "[" + ", ".join(s.strip().rstrip(",") for s in m.group(1).split("\n") if s.strip()) + "]",
        text,
    ) + "\n"


def load_existing() -> dict:
    try:
        return json.loads(OUTPUT.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def main() -> int:
    ap = argparse.ArgumentParser(description="한밭대 학식·기숙사 식단 크롤러")
    ap.add_argument("--dry-run", action="store_true", help="파일에 쓰지 않고 결과만 출력")
    args = ap.parse_args()

    today = dt.date.today()
    errors = []
    try:
        cafeteria = fetch_cafeteria(today)
    except Exception as e:  # noqa: BLE001 - 한쪽이 실패해도 나머지는 저장
        errors.append(f"학식: {e}")
        cafeteria = {}
    try:
        dorm = fetch_dorm()
    except Exception as e:  # noqa: BLE001
        errors.append(f"기숙사: {e}")
        dorm = {}

    for err in errors:
        print(f"[경고] {err}", file=sys.stderr)
    if not cafeteria and not dorm:
        print("가져온 식단이 없어서 파일을 바꾸지 않았어요.", file=sys.stderr)
        return 1

    data = build_data(load_existing(), cafeteria, dorm, today, dt.datetime.now())
    text = dump(data)
    if args.dry_run:
        print(text)
    else:
        OUTPUT.write_text(text, encoding="utf-8")
        print(f"저장했어요: {OUTPUT}")
    print(f"학식 {len(cafeteria)}일 · 기숙사 {len(dorm)}일 새로 가져옴 "
          f"(파일 전체: 학식 {len(data['cafeteria'])}일 · 기숙사 {len(data['dorm'])}일)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
