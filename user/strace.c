#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"
void traceError(int argc, char *argv[])
{
    if (argc < 3 || (argv[1][NUL] < '0' || argv[1][NUL] > '9'))
    {
        printf("WRONG FORMAT\n");
        exit(1);
    }

    if (trace(atoi(argv[1])) < NUL)
    {
        printf("TRACE FAILED\n");
        exit(1);
    }
}
int main(int argc, char *argv[])
{
    char *nargv[MAXARG];
    traceError(argc, argv);

    for (int i = 2; i < argc && i < MAXARG; i++)
    {
        int j = i - 2;
        nargv[j] = argv[i];
    }
    exec(nargv[0], nargv);
    exit(0);
}