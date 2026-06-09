import { validate } from "./drako_validate.mjs";
const D=(items,name)=>({id:name,name,access:"read",items});

// Реальные конструкции ДРАКОН, на которых v0 может ложно сработать.
const cases=[
  // Цикл: вопрос с возвратом наверх (valid DRAKON loop). Не должно быть ложных замечаний.
  { name:"F1 цикл (повтор по вопросу)", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"a1"},
      a1:{type:"action",content:"Сделать шаг",one:"q1"},
      q1:{type:"question",content:"Повторить?",one:"a1",two:"end"},  // one=да -> назад (цикл), two=нет -> выход
      end:{type:"end"} }) },
  // Вставка с проваливанием (insertion + sub). Должна проходить как действие с одним выходом.
  { name:"F3 вставка (insertion+sub)", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"a1"},
      a1:{type:"insertion",sub:"podproc",content:"Подпроцесс",one:"end"},
      end:{type:"end"} }) },
  // Выбор/case: N-арная развилка. В нашей модели портов только one/two — case НЕ представим.
  { name:"F2 выбор/case (3 ветви)", d:D({
      b0:{type:"branch",branchId:0,content:"Старт",one:"s1"},
      s1:{type:"select",content:"Выбор",one:"v1",two:"v2"/*, third:"v3" — НЕТ порта */},
      v1:{type:"action",content:"вар.1",one:"end"},
      v2:{type:"action",content:"вар.2",one:"end"},
      end:{type:"end"} }) },
];
for(const c of cases){
  const f=validate(c.d);
  console.log(`${f.length?"замечания":"чисто   "}  ${c.name}`);
  f.forEach(x=>console.log(`        [${x.rule}] ${x.msg}`));
}
