const { createServer } = require("http");
const server = createServer();

server.on("request", (req, res) => {
  res.end('Hello wonderful world!\n');
});

server.listen(8080, function () {
  console.log('Example app listening on port 8080!');
});
