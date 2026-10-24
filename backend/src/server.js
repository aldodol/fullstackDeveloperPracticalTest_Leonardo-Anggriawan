const app = require('./app');
const { testConnection } = require('./config/db');

const PORT = process.env.PORT || 5000;

async function startServer() {
  await testConnection();

  const server = app.listen(PORT, () => {
    console.log(`====================================================`);
    console.log(`  Raw Material Inventory Server (Studi Kasus 4)    `);
    console.log(`  Running on: http://localhost:${PORT}             `);
    console.log(`  API Docs:   http://localhost:${PORT}/api-docs    `);
    console.log(`====================================================`);
  });

  // Graceful shutdown
  const shutdown = () => {
    console.log('\n[Server] Shutting down gracefully...');
    server.close(() => {
      console.log('[Server] Closed remaining connections.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

startServer();
