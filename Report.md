# xv6-modifications
## System Calls
### System call 1: trace 
- Added `sys_trace()` function in `systproc.c` after delaring it in `syscall.c`. 
- Declared variable `trace_mask` whose bits specify which system
calls to trace.
- Modified `fork()` in `proc.c` to copy `tracemask` from parent to children.
- If syscall is traced, syscall is printed. Modified `syscall()` with respective declarations of functions and new arrays.
- User program `strace` is created that calls `sys_trace()` by creating `strace.c`.
- Edited `Makefile` to include $U/_strace to UPROGS.

## Scheduling
- Edited the `Makefile` to include a `SCHEDULER` flag.
- Round Robin will be the default scheduler, when no other flag is mentioned. 
- Disabled premption with timer interupts in the `kerneltrap()` function in `kernel/trap.c`, except for Round Robin
- Created a `time_update()` fuction in `kernel/proc.c` that gets triggered in the `clockintr()` function of `kernel/trap.c` and stores all the running, waiting times etc.    

### FCFS
- declared the variable `ctime` in `struct proc` in `kernel/proc.h` and initialised it in the `allocproc()` function in `kernel/proc.c` that stores the creation time of the procedure.
- Added the code to run the process with the lowest creation time in the `scheduler()` function in `kernel/proc.c`

### PBS
- Defined the variables `spriority`, `rtime`, `wtime`, `nruns` that store the static priority, waiting time, running time and number of runs respectively of a procedure in `struct proc` in `kernel/proc.h` and initialised it in the `allocproc()` function in `kernel/proc.c`.
- Created a function `dynamic_priority()` in `kernel/proc.c` that calculates the dynamic priority of all the procedures using the corresponding formula.
- Created a syscall `set_priority()` in `kernel/proc.c` that sets the priority to the given value, restores niceness to 5 and returns the old priority value. Edited the `kernel/syscall.c`, `kernel/syscall.h`, `kernel/sysproc.c`, `user/user.h` and `user/usys.pl` for the same.
- Added the code to run PBS Scheduler in the  `scheduler()` function in `kernel/proc.c`.

### MLFQ
- Define queues and their respective time slices in `proc.c`.
- Edited `strcut proc` to store current queue, number of ticks in current time slice, number of ticks recieved at each queue and the last execution time. 
- Edited `allocproc()` in `proc.c` to initialise the above variables when a process is created. [Process added to Queue 0 as it is the highest priority]
- Edited `scheduler()` to run the process with the highest priority - implemented aging and run the processes in order of priority in round robin fashion. 
