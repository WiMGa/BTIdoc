#!/usr/bin/env node

/**
 * BTI MCP Proxy - проксирует stdio к HTTP MCP серверу BTI_API
 * Использование: node bti_mcp_proxy.js
 */

const http = require('http');
const readline = require('readline');

const MCP_URL = 'http://62.149.5.16:5080/mcp';

// Читаем JSON-RPC запросы из stdin
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

rl.on('line', async (line) => {
  try {
    const request = JSON.parse(line);

    // Преобразуем JSON-RPC запрос в HTTP запрос к BTI_API
    const response = await makeHttpRequest(request);

    // Отправляем ответ в stdout
    console.log(JSON.stringify(response));
  } catch (error) {
    console.error(JSON.stringify({
      jsonrpc: '2.0',
      error: {
        code: -32700,
        message: 'Parse error: ' + error.message
      }
    }));
  }
});

async function makeHttpRequest(rpcRequest) {
  return new Promise((resolve, reject) => {
    // Определяем endpoint на основе метода
    let path = '/mcp';

    if (rpcRequest.method === 'tools/list') {
      path = '/mcp/tools';
    } else if (rpcRequest.method === 'tools/call') {
      const toolName = rpcRequest.params.name;
      path = `/mcp/tools/${toolName}`;
    }

    const postData = JSON.stringify(rpcRequest.params || {});

    const options = {
      hostname: '62.149.5.16',
      port: 5080,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve({
            jsonrpc: '2.0',
            id: rpcRequest.id,
            result: response
          });
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Обработка ошибок
process.on('uncaughtException', (error) => {
  console.error(JSON.stringify({
    jsonrpc: '2.0',
    error: {
      code: -32603,
      message: 'Internal error: ' + error.message
    }
  }));
});
