// Референс-валидатор методологии ДРАКОН (модель v0, инварианты I1-I8 + граница IV).
// Вход — наш diagram-JSON {items:{code:{type,content,one,two,branchId,sub}}}.
// Это эталон для инварианта допуска (DC встроит в add_plan_fragment/create_definition).

export function validate(d){
  const f=[];                       // findings {rule,msg}
  const it=(d&&d.items)||{};
  const codes=Object.keys(it);
  const ex=c=>c!=null && it[c]!=null;
  const branches=codes.filter(c=>it[c].type==='branch');
  const ends=codes.filter(c=>it[c].type==='end');
  const questions=codes.filter(c=>it[c].type==='question'||it[c].type==='select');
  const adj=c=>{const n=it[c]||{};const o=[];if(ex(n.one))o.push(n.one);if(ex(n.two))o.push(n.two);return o;};

  // I1 — один вход/один выход; арность портов по типу иконы
  for(const c of codes){const n=it[c],t=n.type;
    if(t==='question'){ if(n.one==null||n.two==null) f.push({rule:'I1',msg:`вопрос ${c}: нужны оба выхода (да=one, нет=two)`}); }
    else if(t==='end'){ if(n.one!=null||n.two!=null) f.push({rule:'I1',msg:`конец ${c}: не должно быть выходов`}); }
    else { if(n.two!=null) f.push({rule:'I1',msg:`${t} ${c}: выход two (вправо) только у вопроса`});
           if(n.one==null) f.push({rule:'I1',msg:`${t} ${c}: нет выхода one`}); }
  }
  // I3 — валентность (минимум): выход ведёт в существующий узел
  for(const c of codes){const n=it[c];
    for(const p of ['one','two']) if(n[p]!=null && !ex(n[p])) f.push({rule:'I3',msg:`${c}.${p} -> несуществующий "${n[p]}"`});
  }
  // I7 — имя ветки непустое+уникальное; branchId сплошные 0..N; ровно один конец
  // I7 имя ветки: PRESENCE не требуем — реальные схемы Митькина имеют безымянную ветку-вход
  // (branchId=0 / примитив), прошлое «имя обязательно» ложно резало валидное. Требуем лишь
  // УНИКАЛЬНОСТЬ непустых имён (иначе адрес неоднозначен). «Имя обязательно у адресуемых веток
  // силуэта» — уточнение v1.
  const seenT=new Set();
  for(const c of branches){const t=it[c].content && String(it[c].content).trim();
    if(t){ if(seenT.has(t)) f.push({rule:'I7',msg:`ветка ${c}: дубль имени "${t}"`}); seenT.add(t); }
  }
  const bids=branches.map(c=>it[c].branchId).filter(x=>x!=null).sort((a,b)=>a-b);
  bids.forEach((v,i)=>{ if(v!==i) f.push({rule:'I7',msg:`branchId не сплошные 0..N (дыра у ${v})`}); });
  if(ends.length!==1) f.push({rule:'I7',msg:`концов должно быть ровно 1, а найдено ${ends.length}`});
  // I2 — достижимость от входа (ветка branchId=0) + нет одиночных
  const entry=branches.filter(c=>it[c].branchId===0);
  const seen=new Set(), st=[...(entry.length?entry:branches.slice(0,1))];
  while(st.length){const c=st.pop(); if(seen.has(c))continue; seen.add(c); for(const x of adj(c)) st.push(x);}
  for(const c of codes) if(!seen.has(c)) f.push({rule:'I2',msg:`${c}: недостижим от входа`});
  const inSet=new Set(); for(const c of codes) for(const x of adj(c)) inSet.add(x);
  for(const c of codes) if(it[c].type!=='end' && adj(c).length===0 && !inSet.has(c)) f.push({rule:'I2',msg:`${c}: одиночный (нет рёбер)`});
  // IV СНЯТО (канон a1c6d66d v2, принцип «один токен»): безразвилочный последовательный силуэт
  // (ветки сцеплены адресами = один токен) — ВАЛИДЕН, IV его ложно резал. Свойство «один токен»
  // покрыто совокупно I1+I2+I7. Реальный параллельный список (независимые истоки/несколько концов)
  // отклоняется I2 (недостижимость от branch_id=0) и I7 (>1 конца). Истинный параллелизм -> слой DAG/«Процесс».
  return f;
}
