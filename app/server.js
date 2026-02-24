// server.js
const http = require("http");
const os = require("os");

const PORT = 80;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("OK");
    return;
  }

  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(`
    <h1>3-Tier Application</h1>
    <p>Hostname: ${os.hostname()}</p>
  `);
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});