# node-ide package

A full source-based JS/CS IDE for Atom or any node target

### Status -- Not ready to use ...
  Running, stepping and breakpoints work but variables aren't inspectable yet.  Breakpoint and stack lists are also working.
  
### Quick instructions ...
- Install this package
- In any Atom window execute `ctrl-F1` (`node-ide:toggle`).
  - You will see the IDE toolbar at the top.  It will have a red lightning bolt.  This means there is no connection to any target.
- Open the target node process using `node --debug-brk myApp.js`.
 - You will see `Debugger listening on port 5858`.
- Click on the lightning bolt.
  - The lightning bolt will turn black to show connection.
  - The navigation buttons to its right will be enabled.
  - The source file `myApp.js` will appear with the current execution point line number highlighted in red.
- Use the navigation buttons to hop around.
- Try a breakpoint
  - Click on any line number to set a breakpoint
    - It will appear red which means active
  - Click again to disable the breakpoint
    - It will change to gray which means disabled
  - Click a third time to remove the breakpoint
- Click on the stop sign to pop up the breakpoint list.
  - The Active checkbox will temporarily disable all breakpoints.
  
### To-Do

- dup breakpoints
- breakpoints with wrong id
