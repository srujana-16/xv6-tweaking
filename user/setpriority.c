#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  if (argc != 3)
  {
    fprintf(2, "usage: setpriority - incorrect number of arguements\n");
    exit(1);
  }
  else {
    int priority = atoi(argv[1]);
    int pid = atoi(argv[2]);
    int prev_priority = set_priority(priority, pid);
    printf("setpriority: Priority of %d changed from %d to %d.\n", pid, prev_priority, priority);
    exit(0);  
  }
}