const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '../../.env') });

async function initDatabase() {
  console.log('[DB Init] Connecting to MySQL server...');
  
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'rootpassword',
    multipleStatements: true
  });

  try {
    console.log('[DB Init] Reading database/init.sql...');
    const initSqlPath = path.join(__dirname, '../../../database/init.sql');
    const initSql = fs.readFileSync(initSqlPath, 'utf8');

    console.log('[DB Init] Executing init schema script...');
    await connection.query(initSql);
    console.log('[DB Init] Tables created successfully!');

    console.log('[DB Init] Reading database/seed.sql...');
    const seedSqlPath = path.join(__dirname, '../../../database/seed.sql');
    if (fs.existsSync(seedSqlPath)) {
      const seedSql = fs.readFileSync(seedSqlPath, 'utf8');
      console.log('[DB Init] Executing seed script...');
      await connection.query(seedSql);
      console.log('[DB Init] Sample data seeded successfully!');
    }

    console.log('[DB Init] Database initialization completed.');
  } catch (error) {
    console.error('[DB Init] Error during database initialization:', error);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

initDatabase();
