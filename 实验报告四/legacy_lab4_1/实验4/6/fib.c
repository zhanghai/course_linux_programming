#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

long *map;

void *fib(void *_index) {
    long index = *(long *)_index, i;
    map = calloc((index + 1) * sizeof(long), 1);
    map[0] = 0;
    map[1] = 1;
    for (i = 2; i <= index; ++i) {
        map[i] = map[i - 2] + map[i - 1];
    }
}

int main() {

    long index;
    pthread_t pthread;

    scanf("%ld", &index);
    if (index <= 0) {
        return 1;
    }

    if (pthread_create(&pthread, NULL, fib, &index)) {
        perror("Thread creation failed");
    }
    pthread_join(pthread, NULL);

    printf("%d\n", map[index]);
    free(map);

    return 0;
}
