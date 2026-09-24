const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..', 'build', 'web');
const port = Number(process.env.PORT || 4180);
const types = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

http
  .createServer((request, response) => {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const candidate = path.resolve(root, `.${pathname}`);
    const safePath = candidate.startsWith(root) ? candidate : root;
    const file = fs.existsSync(safePath) && fs.statSync(safePath).isFile()
      ? safePath
      : path.join(root, 'index.html');
    response.writeHead(200, {
      'Content-Type': types[path.extname(file)] || 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    fs.createReadStream(file).pipe(response);
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`Phương Đông demo: http://127.0.0.1:${port}`);
  });
