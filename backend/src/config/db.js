const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'rootpassword',
  database: process.env.DB_NAME || 'raw_material_db',
  waitForConnections: true,
  connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT || '10', 10),
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
  decimalNumbers: true
});

/**
 * Test MySQL connection
 */
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log(`[DB] Connected successfully to MySQL database: ${process.env.DB_NAME || 'raw_material_db'}`);
    connection.release();
    return true;
  } catch (error) {
    console.error('[DB] Connection error:', error.message);
    return false;
  }
}

module.exports = {
  pool,
  testConnection
};
