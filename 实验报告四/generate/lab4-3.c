#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>

int main() {
    int i = 0;
    sleep(10);
    while (i < 5) {
        system("date");
        sleep(5);
        ++i;
    }
    while (1) {
        system("date");
        sleep(10);
    }
    return EXIT_SUCCESS;
}
