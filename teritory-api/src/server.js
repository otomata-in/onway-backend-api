const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const http = require('http');
const { Server } = require('socket.io');

const app = require('./app');
const { initSocket } = require('./sockets');
const { startCronJobs } = require('./jobs/tripExpiry.cron');
const prisma = require('./config/prisma');

const PORT = process.env.PORT || 4000;

const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  pingInterval: 25000,
  pingTimeout: 20000,
});

app.set('io', io);
initSocket(io);

// Start background cron jobs
startCronJobs();

server.listen(PORT, () => {
  console.log(`\n🏴 ═══════════════════════════════════════════════════════`);
  console.log(`🚀 Teritory Standalone Backend running on port ${PORT}`);
  console.log(`📍 Health Check: http://localhost:${PORT}/health`);
  console.log(`🌐 Base API:     http://localhost:${PORT}/v1`);
  console.log(`🔌 WebSockets:   ws://localhost:${PORT}`);
  console.log(`═════════════════════════════════════════════════════════\n`);
});

// Graceful shutdown
const shutdown = async () => {
  console.log('Stopping Teritory server...');
  server.close(async () => {
    await prisma.$disconnect();
    console.log('Teritory API gracefully terminated.');
    process.exit(0);
  });
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

