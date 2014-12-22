i = 0;
function f() {
  x=3; i += 1;
  console.log(i);
  setTimeout(f, 0);
} 
f()
