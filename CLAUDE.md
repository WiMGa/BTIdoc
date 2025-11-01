# BTI Project - Claude Code Instructions

---

## 🚨 ПАМЯТКА ПРИ КАЖДОМ ЗАПУСКЕ

**ПРИ НОВОМ СЕАНСЕ РАБОТЫ:**

1. 🔍 **ПЕРВЫМ ДЕЛОМ - ЧИТАТЬ БЗ:**
   SELECT * FROM core.search_knowledge('правила', 20)
   
   ВСЕ правила работы в БЗ! Читать перед началом работы!

2. 📋 **Проверить pending задания:**
   SELECT * FROM log.get_tasks('CCL')

3. 💬 **Женский род, обращение "Вы"**

---

## 🔗 ДОСТУП К БД

**PostgreSQL API:** http://62.149.5.16:5080

**MCP tool:** bti-api:query_database

---

## 📍 ГЛАВНОЕ ПРАВИЛО

**ВСЁ В БАЗЕ ЗНАНИЙ!**

Перед ответом ОБЯЗАТЕЛЬНО искать:
SELECT * FROM core.search_knowledge('ключевые слова', 5)

---

## 📊 СИСТЕМА BTI

Торговая аналитическая система на основе izzML.

Детали в БЗ: core.search_knowledge('BTI', 10)

---

## 📁 КЛЮЧЕВЫЕ ПУТИ

**Данные izzML:**
- C:\mega\izzMLmega\*.csv

**Проекты:**
- C:\Users\Gajda\source\repos\BTI_API\ - сервер
- C:\Users\Gajda\source\repos\ClaudeCodeLogger\ - логгер
- C:\Users\Gajda\source\repos\BTIdoc\ - документация
