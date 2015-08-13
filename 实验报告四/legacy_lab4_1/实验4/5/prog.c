#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>


typedef void (*Runnable)();

void print(char *name, char *string);
void printPid(char *name);
void spawn(Runnable child);
void p1Runnable();
void p2Runnable();
void p3Runnable();


int pipe1[2], pipe2[2];

void spawn(Runnable child) {
    pid_t pid = fork();
    if (pid == 0) {
        child();
        exit(0);
    } else if (pid == -1) {
        abort();
    }
}

void print(char *name, char *message) {
    printf("[%s] %s\n", name, message);
}

void printPid(char *name) {
    printf("[%s] Pid: %d\n", name, getpid());
}

void p1Runnable() {

    char msgsnd[] = "Child process p1 is sending a message!", msgrcv[256];

    printPid("p1");

    close(pipe1[1]);
    close(pipe2[0]);
    write(pipe2[1], msgsnd, sizeof(msgsnd));
    read(pipe1[0], msgrcv, sizeof(msgrcv));
    print("p1", msgrcv);

    spawn(p3Runnable);
}

void p2Runnable() {

    char msgsnd[] = "Child process p2 is sending a message!", msgrcv[256];

    printPid("p2");

    close(pipe2[1]);
    close(pipe1[0]);
    write(pipe1[1], msgsnd, sizeof(msgsnd));
    read(pipe2[0], msgrcv, sizeof(msgrcv));
    print("p2", msgrcv);
}

void p3Runnable() {

    print("p3", "I am child process p3");
    printPid("p3");

    printf("[p3] ");
    fflush(stdout);
    execlp("ls", "ls", 0);
    abort();
}

int main() {

    print("main", "I am main process");
    printPid("main");

    pipe(pipe1);
    pipe(pipe2);

    spawn(p1Runnable);

    spawn(p2Runnable);

    return 0;
}
