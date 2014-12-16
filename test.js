// var http = require('http');
// http.createServer(function (req, res) {
//   res.writeHead(200, {'Content-Type': 'text/plain'});
//   res.end('Hello World\n');
// }).listen(5648, '127.0.0.1');
// console.log('Server running at http://127.0.0.1:5648/');

i = 0
function f(x) {
  x=3;
  i += 1;
  console.log('testjs, i:', i);
  setTimeout(f, 2000);
}

f()

