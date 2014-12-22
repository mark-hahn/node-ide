
i = 0;

// while (true) {
//  x=1;
//  y=2;  
//  f()
// }

function f() {
  x=3; i += 1;
  console.log(i);
  setTimeout(f, 0);
} 

f()

