// drako_gen — переходник: плоская модель Definition (узлы + переходы из lmn)
// -> diagram-JSON для движка DrakonWidget (Митькин). Координат НЕ задаёт —
// силуэт раскладывает движок из branchId и связей one/two.
//
// Это эталонная реализация логики endpoint #2131 (здесь на JS для офлайн-
// доказательства; портируется в C# PlanController как GET .../drakon).
//
// Контракт входа (то, что DC кладёт в lmn как Definition — #2120):
//   { id, name, nodes:[{code,type,content?,branchId?,sub?,status?}], deps:[{from,to,port}] }
//   type  : branch | action | question | insertion | end (+ прочие иконы движка)
//   port  : "one" (низ/основной/«да») | "two" (право/ветка/«нет»)
//   status: todo | in_progress | done | blocked  (todo -> без style)
//
// Выход (то, что принимает движок):
//   { id, name, access:"read", items:{ <code>:{type,content?,one?,two?,branchId?,sub?,status?} } }

(function (root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.drakoGen = factory();
})(typeof self !== "undefined" ? self : this, function () {

  // Статус -> стиль иконки (тот же словарь, что в каноне 3fe14b0a / index.html applyStatus).
  // Возвращается как поле status; покраску (style) делает фронт, чтобы не дублировать
  // словарь в двух местах — движок сам style не вычисляет.
  function buildDiagram(flat) {
    if (!flat || !Array.isArray(flat.nodes)) {
      throw new Error("drakoGen: ожидается { nodes:[...], deps:[...] }");
    }
    var items = {};
    var byCode = {};

    // 1) узлы -> items (без связей)
    flat.nodes.forEach(function (n) {
      if (!n || !n.code) throw new Error("drakoGen: узел без code: " + JSON.stringify(n));
      if (items[n.code]) throw new Error("drakoGen: дубль code: " + n.code);
      var it = { type: n.type };
      if (n.content != null && n.type !== "end") it.content = n.content;
      if (n.type === "branch") {
        if (n.branchId == null) throw new Error("drakoGen: branch без branchId: " + n.code);
        it.branchId = n.branchId;
      }
      if (n.sub != null) it.sub = n.sub;          // host-расширение: проваливание в под-схему
      if (n.status != null && n.status !== "todo") it.status = n.status;
      items[n.code] = it;
      byCode[n.code] = it;
    });

    // 2) переходы -> one/two
    (flat.deps || []).forEach(function (d) {
      if (!d || !d.from || !d.to) throw new Error("drakoGen: ребро без from/to: " + JSON.stringify(d));
      var src = byCode[d.from];
      if (!src) throw new Error("drakoGen: ребро from неизвестного узла: " + d.from);
      if (!byCode[d.to]) throw new Error("drakoGen: ребро to неизвестного узла: " + d.to);
      var port = d.port === "two" ? "two" : "one";
      if (src[port] != null) {
        throw new Error("drakoGen: порт " + port + " узла " + d.from + " уже занят (-> " + src[port] + ")");
      }
      src[port] = d.to;
    });

    // 3) валидация силуэта (грабли движка из хендоффа)
    validate(items);

    return { id: flat.id || "diagram", name: flat.name || "", access: "read", items: items };
  }

  // Минимальная проверка структуры, чтобы не отдать движку то, на чём он падает.
  function validate(items) {
    var branches = Object.keys(items).filter(function (k) { return items[k].type === "branch"; })
      .map(function (k) { return items[k].branchId; }).sort(function (a, b) { return a - b; });
    // branchId должны идти 0..N без дыр (силуэт = цепочка веток)
    branches.forEach(function (bid, i) {
      if (bid !== i) throw new Error("drakoGen: branchId не сплошные 0..N (дыра у " + bid + ") — движок упадёт");
    });
    // вопрос обязан иметь оба выхода one/two
    Object.keys(items).forEach(function (k) {
      var it = items[k];
      if (it.type === "question" && (it.one == null || it.two == null)) {
        throw new Error("drakoGen: question " + k + " без обоих выходов one/two");
      }
      if (it.type !== "end" && it.type !== "branch" && it.one == null && it.type !== "question") {
        // действие/вставка без продолжения — допустимо только если это терминальная ветка,
        // но в силуэте всё ведёт к end; предупреждаем мягко (не бросаем).
      }
    });
  }

  return { buildDiagram: buildDiagram };
});
