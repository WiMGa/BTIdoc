# PLAN_INTAKE как Definition для lmn — готово к вставке (CCL → DC)

Переходник `{узлы + переходы} → силуэт DrakonWidget` доказан офлайн (test_gen.mjs PASS:
сгенерированный diagram-JSON тождественен рабочему scheme.json). Чтобы силуэт
строился ИЗ БД, нужен этот Definition в lmn. Запись в lmn — зона DC (#2120).

## Узлы (lmn.t_plan_node, признак definition)
| code | type      | branchId | content | примечание |
|------|-----------|----------|---------|-----------|
| b0   | branch    | 0 | Старт | голова силуэта |
| b1   | branch    | 1 | Целевой план (Класс 1) | |
| b2   | branch    | 2 | Инфра-план (Класс 2) | |
| b3   | branch    | 3 | Запуск | |
| end  | end       | — | — | терминал |
| a1   | insertion | — | Зафиксировать: что хочу… | sub=intake1 (проваливание в под-схему) |
| q1   | question  | — | Целевая работа (Класс 1)? | развилка |
| t1   | action    | — | Найти/создать Definition (DECK/BFSC) | |
| i1   | action    | — | Найти/создать Definition в плане AIon | |
| r1   | action    | — | Инстанцировать Definition под корень → Instance | |
| r2   | action    | — | Выставить фокус (b_is_current_focus) | |

## Переходы (lmn.t_plan_dependency: i_from_node_id, i_to_node_id, port)
| from | to  | port | смысл |
|------|-----|------|-------|
| b0   | a1  | one  | тело ветки Старт |
| a1   | q1  | one  | |
| q1   | b1  | one  | ДА  → ветка Целевой |
| q1   | b2  | two  | НЕТ → ветка Инфра |
| b1   | t1  | one  | тело ветки Целевой |
| t1   | b3  | one  | адрес → Запуск |
| b2   | i1  | one  | тело ветки Инфра |
| i1   | b3  | one  | адрес → Запуск |
| b3   | r1  | one  | тело ветки Запуск |
| r1   | r2  | one  | |
| r2   | end | one  | |

## Что нужно от модели #2120 (одно открытое поле)
Развилка да/нет и низ-ветки-адрес кодируются полем **port ∈ {one, two}** на ребре
(`one` = низ/основной/«да», `two` = право/ветка/«нет»). Если в t_plan_dependency
такого поля нет — добавить (s_port или b_is_secondary). Без него развилку из БД
не восстановить. Имена type/branchId — как удобно DC; переходник читает их по карте.

Машиночитаемый вход переходника: tmp_drakon/plan_intake.flat.json
Логика endpoint (#2131, портируется в C#): tmp_drakon/drako_gen.js
