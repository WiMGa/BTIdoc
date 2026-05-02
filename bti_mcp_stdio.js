#!/usr/bin/env node

/**
 * BTI MCP stdio proxy - для Desktop Claude
 * Проксирует stdio → HTTP JSON-RPC → BTI_API
 */

const http = require('http');
const readline = require('readline');

// Отладочные сообщения идут в stderr (видны в логах Desktop Claude)
const log = (msg) => process.stderr.write(`[BTI-MCP] ${msg}\n`);

// Admin tools живут на отдельном /mcp/admin endpoint (см. #1606), все остальные — на /mcp/streamable.
const ADMIN_TOOL_NAMES = new Set(['query_database', 'execute_python']);
const PATH_STREAMABLE = '/mcp/streamable';
const PATH_ADMIN = '/mcp/admin';

log('Starting BTI MCP stdio proxy...');

// Читаем JSON-RPC из stdin построчно
const rl = readline.createInterface({
  input: process.stdin,
  terminal: false
});

rl.on('line', async (line) => {
  try {
    const request = JSON.parse(line);
    const isNotification = request.id === undefined || request.id === null;
    log(`Request: ${request.method} (id=${request.id}, notification=${isNotification})`);

    // Для notifications: отправляем на сервер но НЕ ждём ответа
    if (isNotification) {
      makeHttpRequest(PATH_STREAMABLE, request).catch(err => log(`Notification error: ${err.message}`));
      // Notifications не требуют ответа согласно JSON-RPC 2.0
      log(`Notification sent, no response expected`);
      return;
    }

    // tools/list: объединяем результаты /mcp/streamable + /mcp/admin
    if (request.method === 'tools/list') {
      const response = await mergeToolsList(request);
      process.stdout.write(JSON.stringify(response) + '\n');
      log(`Response sent for id=${request.id} (merged tools/list)`);
      return;
    }

    // tools/call: маршрутизация по имени tool
    if (request.method === 'tools/call') {
      const sToolName = request.params && request.params.name;
      const sPath = ADMIN_TOOL_NAMES.has(sToolName) ? PATH_ADMIN : PATH_STREAMABLE;
      const response = await makeHttpRequest(sPath, request);
      process.stdout.write(JSON.stringify(response) + '\n');
      log(`Response sent for id=${request.id} (tool=${sToolName} via ${sPath})`);
      return;
    }

    // Все остальные методы (initialize / resources/list / prompts/list / ...) → /mcp/streamable
    const response = await makeHttpRequest(PATH_STREAMABLE, request);

    // Отвечаем в stdout
    process.stdout.write(JSON.stringify(response) + '\n');
    log(`Response sent for id=${request.id}`);
  } catch (error) {
    log(`ERROR: ${error.message}`);
    // Сохраняем id из запроса, если он был
    let requestId = 'error-0';
    try {
      const parsed = JSON.parse(line);
      if (parsed.id !== undefined && parsed.id !== null) {
        requestId = parsed.id;
      }
    } catch (e) { /* ignore */ }
    
    process.stdout.write(JSON.stringify({
      jsonrpc: '2.0',
      id: requestId,  // Zod требует string|number, не null!
      error: {
        code: -32603,
        message: error.message
      }
    }) + '\n');
  }
});

async function makeHttpRequest(sPath, rpcRequest) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(rpcRequest);

    const options = {
      hostname: '62.149.5.16',
      port: 5080,
      path: sPath,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'User-Agent': 'claude-desktop-stdio-bridge'
      },
      timeout: 20000  // 20 сек
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`Invalid JSON: ${data}`));
        }
      });
    });

    req.on('error', (e) => reject(e));
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.write(postData);
    req.end();
  });
}

// Объединяет tools из /mcp/streamable и /mcp/admin в один tools/list ответ.
// Если один из endpoint падает — возвращаем результат другого (graceful degradation).
async function mergeToolsList(request) {
  const lPaths = [PATH_STREAMABLE, PATH_ADMIN];
  const lResults = await Promise.allSettled(lPaths.map(s => makeHttpRequest(s, request)));

  const lTools = [];
  let eBaseResponse = null;
  for (let i = 0; i < lResults.length; i++) {
    const eItem = lResults[i];
    if (eItem.status === 'fulfilled') {
      const eResponse = eItem.value;
      if (!eBaseResponse) eBaseResponse = eResponse;
      const lEndpointTools = (eResponse && eResponse.result && Array.isArray(eResponse.result.tools))
        ? eResponse.result.tools : [];
      lTools.push(...lEndpointTools);
      log(`tools/list ${lPaths[i]}: ${lEndpointTools.length} tools`);
    } else {
      log(`tools/list ${lPaths[i]} FAILED: ${eItem.reason && eItem.reason.message}`);
    }
  }

  if (!eBaseResponse) {
    throw new Error('Both /mcp/streamable and /mcp/admin failed for tools/list');
  }

  return {
    jsonrpc: '2.0',
    id: request.id,
    result: { tools: lTools }
  };
}

process.on('uncaughtException', (error) => {
  log(`FATAL: ${error.message}`);
  process.exit(1);
});

log('BTI MCP proxy ready');
