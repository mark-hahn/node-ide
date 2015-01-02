fs = require('fs');

i = 0;
function f() {
  x=3; i += 1;
  console.log(i);
  
  try {
    fs.readFileSync('liydkdh');
  } catch (e) {
    'hello';
  }
  
  if (i == 3)
    fs.readFileSync('jyrehgrd');
  
  setTimeout(f, 0);
} 
f()
