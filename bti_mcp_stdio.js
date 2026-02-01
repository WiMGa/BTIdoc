#!/usr/bin/env node

/**
 * BTI MCP stdio proxy - для Desktop Claude
 * Проксирует stdio → HTTP JSON-RPC → BTI_API
 */

const http = require('http');
const readline = require('readline');

// Отладочные сообщения идут в stderr (видны в логах Desktop Claude)
const log = (msg) => process.stderr.write(`[BTI-MCP] ${msg}\n`);

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
      makeHttpRequest(request).catch(err => log(`Notification error: ${err.message}`));
      // Notifications не требуют ответа согласно JSON-RPC 2.0
      log(`Notification sent, no response expected`);
      return;
    }

    // Для обычных запросов: ждём ответа
    const response = await makeHttpRequest(request);

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

async function makeHttpRequest(rpcRequest) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(rpcRequest);

    const options = {
      hostname: '62.149.5.16',
      port: 5080,
      path: '/mcp',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
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

process.on('uncaughtException', (error) => {
  log(`FATAL: ${error.message}`);
  process.exit(1);
});

log('BTI MCP proxy ready');
