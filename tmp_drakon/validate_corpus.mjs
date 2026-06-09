import { validate } from "./drako_validate.mjs";

// Корпус: канонические ВАЛИДНЫЕ схемы + документированные АНТИ-ПАТТЕРНЫ.
// expectValid: ожидаем 0 findings; иначе ожидаем срабатывание правила wantRule.
const D = (items, name="t") => ({ id:name, name, access:"read", items });

const corpus = [
  // --- ВАЛИДНЫЕ (канон) ---
  { name:"V1 примитив (линейный)", expectValid:true, d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"a1"},
      a1:{type:"action",content:"Шаг",one:"end"},
      end:{type:"end"} }) },
  { name:"V2 силуэт с развилкой (алгоритм)", expectValid:true, d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"a1"},
      a1:{type:"action",content:"Подготовка",one:"q1"},
      q1:{type:"question",content:"Условие?",one:"b1",two:"b2"},
      b1:{type:"branch",branchId:1,content:"Да-ветка",one:"t1"},
      t1:{type:"action",content:"шаг да",one:"b3"},
      b2:{type:"branch",branchId:2,content:"Нет-ветка",one:"i1"},
      i1:{type:"action",content:"шаг нет",one:"b3"},
      b3:{type:"branch",branchId:3,content:"Финал",one:"r1"},
      r1:{type:"action",content:"завершить",one:"end"},
      end:{type:"end"} }) },

  // --- АНТИ-ПАТТЕРНЫ (каждый должен ловиться) ---
  { name:"X1 висячее ребро", expectValid:false, wantRule:"I3", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"a1"},
      a1:{type:"action",content:"Шаг",one:"nope"},
      end:{type:"end"} }) },
  { name:"X2 одиночный узел", expectValid:false, wantRule:"I2", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"a1"},
      a1:{type:"action",content:"Шаг",one:"end"},
      z:{type:"action",content:"сирота"},
      end:{type:"end"} }) },
  { name:"X3 вопрос без второго выхода", expectValid:false, wantRule:"I1", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"q1"},
      q1:{type:"question",content:"?",one:"end"},
      end:{type:"end"} }) },
  { name:"X4 дыра в branchId (0,1,3)", expectValid:false, wantRule:"I7", d:D({
      b0:{type:"branch",branchId:0,content:"А",one:"q1"},
      q1:{type:"question",content:"?",one:"b1",two:"b3"},
      b1:{type:"branch",branchId:1,content:"Б",one:"x1"}, x1:{type:"action",content:"x",one:"end"},
      b3:{type:"branch",branchId:3,content:"В",one:"x2"}, x2:{type:"action",content:"y",one:"end"},
      end:{type:"end"} }) },
  // V3: безымянная ветка-вход (примитив Митькина) — ВАЛИДНО (после фикса ложного I7)
  { name:"V3 безымянный примитив (как у Митькина)", expectValid:true, d:D({
      b0:{type:"branch",branchId:0,one:"a1"},
      a1:{type:"action",content:"Hello!",one:"end"},
      end:{type:"end"} }) },
  // X5: дубль имён веток — адрес неоднозначен -> I7 (уникальность)
  { name:"X5 дубль имени ветки", expectValid:false, wantRule:"I7", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"q1"},
      q1:{type:"question",content:"?",one:"b1",two:"b2"},
      b1:{type:"branch",branchId:1,content:"Ветка",one:"x1"}, x1:{type:"action",content:"x",one:"end"},
      b2:{type:"branch",branchId:2,content:"Ветка",one:"x2"}, x2:{type:"action",content:"y",one:"end"},
      end:{type:"end"} }) },
  { name:"X6 два конца", expectValid:false, wantRule:"I7", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"q1"},
      q1:{type:"question",content:"?",one:"e1",two:"e2"},
      e1:{type:"end"}, e2:{type:"end"} }) },
  // V4: безразвилочный ПОСЛЕДОВАТЕЛЬНЫЙ силуэт (ветки сцеплены адресами = один токен) — ВАЛИДЕН
  // (это и есть «План» как последовательность; IV снят, a1c6d66d v2).
  { name:"V4 безразвилочный последовательный силуэт (сцепленные ветки)", expectValid:true, d:D({
      b0:{type:"branch",branchId:0,content:"Закупка",one:"c0"}, c0:{type:"action",content:"...",one:"b1"},
      b1:{type:"branch",branchId:1,content:"Расходы",one:"c1"}, c1:{type:"action",content:"...",one:"b2"},
      b2:{type:"branch",branchId:2,content:"Инфо",one:"c2"}, c2:{type:"action",content:"...",one:"b3"},
      b3:{type:"branch",branchId:3,content:"Archi",one:"c3"}, c3:{type:"action",content:"...",one:"end"},
      end:{type:"end"} }) },
  // X7: РЕАЛЬНЫЙ параллельный список (независимые истоки, несколько концов) — отклоняется I2+I7,
  // НЕ по IV. Истинная параллель -> слой DAG/«Процесс».
  { name:"X7 реальный параллельный список (независимые истоки/2 конца)", expectValid:false, wantRule:"I2", d:D({
      b0:{type:"branch",branchId:0,content:"Закупка",one:"c0"}, c0:{type:"action",content:"...",one:"e0"}, e0:{type:"end"},
      b1:{type:"branch",branchId:1,content:"Archi",one:"c1"}, c1:{type:"action",content:"...",one:"e1"}, e1:{type:"end"} }) },
];

let pass=0, fail=0;
for(const c of corpus){
  const f=validate(c.d);
  const rules=[...new Set(f.map(x=>x.rule))];
  let ok;
  if(c.expectValid) ok = f.length===0;
  else ok = f.length>0 && (!c.wantRule || rules.includes(c.wantRule));
  console.log(`${ok?"PASS":"FAIL"}  ${c.name}`);
  if(f.length) f.forEach(x=>console.log(`        [${x.rule}] ${x.msg}`));
  ok?pass++:fail++;
}
console.log(`\nИТОГ: PASS ${pass} / ${corpus.length}, FAIL ${fail}`);
