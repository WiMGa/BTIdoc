// #2169 поведенческая сверка: эталон drako_validate.mjs ↔ живой SQL-admission (create_definition).
// Прогоняем корпус через боевой endpoint, сравниваем вердикт с референс-валидатором. Чистим за собой.
import { validate } from "./drako_validate.mjs";
const B="https://btiapi.net/api/lmn";

const D=(items)=>items;
const cases=[
  {name:"V1 примитив", valid:true, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"a1"}, a1:{type:"action",content:"Шаг",one:"end"}, end:{type:"end"}}},
  {name:"V2 силуэт с развилкой", valid:true, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"a1"}, a1:{type:"action",content:"Подготовка",one:"q1"},
     q1:{type:"question",content:"Условие?",one:"b1",two:"b2"},
     b1:{type:"branch",branchId:1,content:"Да",one:"t1"}, t1:{type:"action",content:"шаг да",one:"b3"},
     b2:{type:"branch",branchId:2,content:"Нет",one:"i1"}, i1:{type:"action",content:"шаг нет",one:"b3"},
     b3:{type:"branch",branchId:3,content:"Финал",one:"r1"}, r1:{type:"action",content:"завершить",one:"end"}, end:{type:"end"}}},
  {name:"V3 безымянный примитив (Митькин)", valid:true, items:{
     b0:{type:"branch",branchId:0,one:"a1"}, a1:{type:"action",content:"Hello!",one:"end"}, end:{type:"end"}}},
  {name:"X1 висячее ребро", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"a1"}, a1:{type:"action",content:"Шаг",one:"nope"}, end:{type:"end"}}},
  {name:"X2 одиночный узел", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"a1"}, a1:{type:"action",content:"Шаг",one:"end"}, z:{type:"action",content:"сирота"}, end:{type:"end"}}},
  {name:"X3 вопрос без 2-го выхода", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"q1"}, q1:{type:"question",content:"?",one:"end"}, end:{type:"end"}}},
  {name:"X4 дыра в branchId", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"А",one:"q1"}, q1:{type:"question",content:"?",one:"b1",two:"b3"},
     b1:{type:"branch",branchId:1,content:"Б",one:"x1"}, x1:{type:"action",content:"x",one:"end"},
     b3:{type:"branch",branchId:3,content:"В",one:"x2"}, x2:{type:"action",content:"y",one:"end"}, end:{type:"end"}}},
  {name:"X5 дубль имени ветки", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"q1"}, q1:{type:"question",content:"?",one:"b1",two:"b2"},
     b1:{type:"branch",branchId:1,content:"Ветка",one:"x1"}, x1:{type:"action",content:"x",one:"end"},
     b2:{type:"branch",branchId:2,content:"Ветка",one:"x2"}, x2:{type:"action",content:"y",one:"end"}, end:{type:"end"}}},
  {name:"X6 два конца", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"Старт",one:"q1"}, q1:{type:"question",content:"?",one:"e1",two:"e2"}, e1:{type:"end"}, e2:{type:"end"}}},
  {name:"V4 безразвилочный последовательный силуэт (План)", valid:true, items:{
     b0:{type:"branch",branchId:0,content:"Закупка",one:"c0"}, c0:{type:"action",content:"...",one:"b1"},
     b1:{type:"branch",branchId:1,content:"Расходы",one:"c1"}, c1:{type:"action",content:"...",one:"b2"},
     b2:{type:"branch",branchId:2,content:"Инфо",one:"c2"}, c2:{type:"action",content:"...",one:"b3"},
     b3:{type:"branch",branchId:3,content:"Archi",one:"c3"}, c3:{type:"action",content:"...",one:"end"}, end:{type:"end"}}},
  {name:"X7 реальный параллельный список (2 истока/2 конца)", valid:false, items:{
     b0:{type:"branch",branchId:0,content:"Закупка",one:"c0"}, c0:{type:"action",content:"...",one:"e0"}, e0:{type:"end"},
     b1:{type:"branch",branchId:1,content:"Archi",one:"c1"}, c1:{type:"action",content:"...",one:"e1"}, e1:{type:"end"}}},
];

function toFragment(items){
  const nodes=[], edges=[];
  for(const code of Object.keys(items)){const n=items[code];
    const nd={code, kind:n.type}; if(n.branchId!=null)nd.branch_id=n.branchId; if(n.content!=null)nd.title=n.content; if(n.sub!=null)nd.sub=n.sub;
    nodes.push(nd);
    if(n.one!=null) edges.push({from:code,to:n.one,port:"one"});
    if(n.two!=null) edges.push({from:code,to:n.two,port:"two"});
  }
  return {nodes,edges};
}

const created=[];
let agree=0, diverge=0;
console.log("кейс".padEnd(34),"вал-р","SQL ","совпало");
for(let i=0;i<cases.length;i++){const c=cases[i];
  const myFindings=validate({items:c.items});
  const myValid=myFindings.length===0;
  const code="ZZ_SV_"+i;
  const {nodes,edges}=toFragment(c.items);
  let httpOk, msg="";
  try{
    const r=await fetch(`${B}/definition`,{method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({code, name:c.name, nodes, edges, created_by:"CCL"})});
    httpOk = r.status===200;
    if(httpOk) created.push(code); else { const j=await r.json().catch(()=>({})); msg=(j.error||j.message||"").slice(0,60); }
  }catch(e){ httpOk=false; msg="fetch:"+e.message; }
  const sqlValid=httpOk;
  const same = myValid===sqlValid;
  same?agree++:diverge++;
  console.log(c.name.padEnd(34), (myValid?"valid":"REJECT").padEnd(6), (sqlValid?"valid":"REJECT").padEnd(5), same?"да":"!!! РАСХОЖДЕНИЕ", msg?("  SQL: "+msg):"");
}
console.log(`\nсовпадений ${agree}/${cases.length}, расхождений ${diverge}`);
// чистим созданные валидные scratch
for(const code of created){ try{ await fetch(`${B}/definition/${code}?caller=CCL`,{method:"DELETE"}); }catch(e){} }
console.log("scratch удалены:", created.join(", ")||"нет");
