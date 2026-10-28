// Офлайн-доказательство: переходник из плоской модели даёт ТОТ ЖЕ diagram-JSON,
// что заведомо рабочий (рисуемый движком) scheme.json PLAN_INTAKE.
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { buildDiagram } = require("./drako_gen.js");

const flat = JSON.parse(readFileSync(new URL("./plan_intake.flat.json", import.meta.url)));
const golden = JSON.parse(readFileSync("C:/Mega/deck/archisim/scheme_work/scheme.json"));

const gen = buildDiagram(flat);

// нормализация: сравниваем граф items по сути (type, content, one, two, branchId, sub)
function norm(d) {
  const o = {};
  for (const k of Object.keys(d.items).sort()) {
    const it = d.items[k];
    o[k] = { type: it.type, content: it.content ?? null, one: it.one ?? null,
             two: it.two ?? null, branchId: it.branchId ?? null, sub: it.sub ?? null };
  }
  return o;
}
const a = norm(gen), b = norm(golden);
const ja = JSON.stringify(a, null, 1), jb = JSON.stringify(b, null, 1);

if (ja === jb) {
  console.log("PASS — сгенерированный diagram-JSON ИДЕНТИЧЕН рабочему scheme.json");
  console.log("  узлов:", Object.keys(a).length,
              "| веток:", Object.values(a).filter(x => x.type === "branch").length,
              "| вопросов:", Object.values(a).filter(x => x.type === "question").length);
} else {
  console.log("FAIL — расхождения:");
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  for (const k of keys) {
    const sa = JSON.stringify(a[k]), sb = JSON.stringify(b[k]);
    if (sa !== sb) console.log("  [" + k + "]\n    gen:    " + sa + "\n    golden: " + sb);
  }
  process.exit(1);
}
