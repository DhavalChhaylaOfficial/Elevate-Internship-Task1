var http = require("http");
port = 3033;

function handleRequest(req, res) {
  res.writeHead(200, { "Content-type": "text/html" });
  res.write("Hello, Dhaval! This is Node.js app v2.0");
  res.end();
}

http.createServer(handleRequest).listen(port);
console.log("Static file server running at\n  => http://localhost:" + port);
