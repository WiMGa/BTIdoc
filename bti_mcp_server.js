#!/usr/bin/env node

/**
 * BTI MCP Server - официальный TypeScript SDK подход
 * Прямое подключение к PostgreSQL БД BTI
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import pg from 'pg';

const { Client } = pg;

// PostgreSQL connection
const dbConfig = {
  host: '62.149.5.16',
  port: 5432,
  database: 'bti_db',
  user: 'postgres',
  password: 'postgres',
};

// Create MCP server
const server = new Server(
  {
    name: 'BTI MCP Server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'query_database',
        description: 'Execute SQL SELECT queries to BTI database',
        inputSchema: {
          type: 'object',
          properties: {
            sSqlQuery: {
              type: 'string',
              description: 'SQL SELECT query to execute',
            },
          },
          required: ['sSqlQuery'],
        },
      },
      {
        name: 'log_event',
        description: 'Log BTI system evolution events',
        inputSchema: {
          type: 'object',
          properties: {
            sEventType: {
              type: 'string',
              description: 'Event type',
            },
            sComponent: {
              type: 'string',
              description: 'System component',
            },
            sDescription: {
              type: 'string',
              description: 'Event description',
            },
          },
          required: ['sEventType', 'sComponent', 'sDescription'],
        },
      },
      {
        name: 'get_task_stats',
        description: 'Get BTI task execution statistics',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
      {
        name: 'add_knowledge',
        description: 'Add knowledge to BTI Master Tree',
        inputSchema: {
          type: 'object',
          properties: {
            sSection: {
              type: 'string',
              description: 'Section name',
            },
            sTitle: {
              type: 'string',
              description: 'Title',
            },
            sContent: {
              type: 'string',
              description: 'Content',
            },
            sKeywords: {
              type: 'string',
              description: 'Keywords',
            },
          },
          required: ['sSection', 'sTitle', 'sContent'],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'query_database': {
        const client = new Client(dbConfig);
        await client.connect();
        const result = await client.query(args.sSqlQuery);
        await client.end();

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result.rows, null, 2),
            },
          ],
        };
      }

      case 'log_event': {
        const client = new Client(dbConfig);
        await client.connect();
        await client.query(
          'INSERT INTO "BTI_Evolution_Log" ("sEventType", "sComponent", "sDescription", "tmEvent") VALUES ($1, $2, $3, NOW())',
          [args.sEventType, args.sComponent, args.sDescription]
        );
        await client.end();

        return {
          content: [
            {
              type: 'text',
              text: 'Event logged successfully',
            },
          ],
        };
      }

      case 'get_task_stats': {
        const client = new Client(dbConfig);
        await client.connect();
        const result = await client.query(
          'SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE "sStatus" = \'completed\') as completed FROM "Tasks"'
        );
        await client.end();

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result.rows[0], null, 2),
            },
          ],
        };
      }

      case 'add_knowledge': {
        const client = new Client(dbConfig);
        await client.connect();
        await client.query(
          'INSERT INTO "BTI_Master_Tree" ("sSection", "sTitle", "sContent", "sKeywords") VALUES ($1, $2, $3, $4)',
          [args.sSection, args.sTitle, args.sContent, args.sKeywords || '']
        );
        await client.end();

        return {
          content: [
            {
              type: 'text',
              text: 'Knowledge added successfully',
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('BTI MCP Server running on stdio');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
