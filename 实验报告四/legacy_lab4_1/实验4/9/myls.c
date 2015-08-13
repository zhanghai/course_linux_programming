/*
 * A simple 'ls' program that mimics the behavior of `ls -ali`
 * Copyright (C) 2014 Zhang Hai.
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <http://www.gnu.org/licenses/>.
 */

#include <dirent.h>
#include <errno.h>
#include <pwd.h>
#include <grp.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    char *dirname;
    time_t recent;
    DIR *dir;
    struct dirent *dirent;
    char *absname;
    struct stat stat;
    char mode[11];
    struct passwd *pwd;
    struct group *grp;
    char *timefmt, mtime[256];

    setlocale(LC_ALL, "");

    errno = 0;

    if (argc == 1) {
        dirname = ".";
    } else if (argc == 2) {
        dirname = argv[1];
    } else {
        printf("Usage: myls [directory]\n");
        return -1;
    }

    time(&recent);
    /* From GNU coreutils ls implementation:
       Consider a time to be recent if it is within the past six
       months.  A Gregorian year has 365.2425 * 24 * 60 * 60 ==
       31556952 seconds on the average.  Write this value as an
       integer constant to avoid floating point hassles. */
    recent -= 31556952 / 2;

    dir = opendir(dirname);
    if (errno != 0) {
        perror(dirname);
        return errno;
    }

    while ((dirent = readdir(dir)) != NULL) {

        absname = malloc(strlen(dirname) + strlen(dirent->d_name)
                + 2);
        strcpy(absname, dirname);
        strcat(absname, "/");
        strcat(absname, dirent->d_name);

        lstat(absname, &stat);
        if (errno != 0) {
            perror(absname);
            free(absname);
            continue;
        }
        free(absname);

        if (S_ISREG(stat.st_mode)) { mode[0] = '-'; }
        else if (S_ISBLK(stat.st_mode)) { mode[0] = 'b'; }
        else if (S_ISCHR(stat.st_mode)) { mode[0] = 'c'; }
        else if (S_ISDIR(stat.st_mode)) { mode[0] = 'd'; }
        else if (S_ISLNK(stat.st_mode)) { mode[0] = 'l'; }
        else if (S_ISFIFO(stat.st_mode)) { mode[0] = 'p'; }
        else if (S_ISSOCK(stat.st_mode)) { mode[0] = 's'; }
        mode[1] = stat.st_mode & S_IRUSR ? 'r' : '-';
        mode[2] = stat.st_mode & S_IWUSR ? 'w' : '-';
        mode[3] = stat.st_mode & S_IXUSR ? 'x' : '-';
        mode[4] = stat.st_mode & S_IRGRP ? 'r' : '-';
        mode[5] = stat.st_mode & S_IWGRP ? 'w' : '-';
        mode[6] = stat.st_mode & S_IXGRP ? 'x' : '-';
        mode[7] = stat.st_mode & S_IROTH ? 'r' : '-';
        mode[8] = stat.st_mode & S_IWOTH ? 'w' : '-';
        mode[9] = stat.st_mode & S_IXOTH ? 'x' : '-';
        mode[10] = 0;

        pwd = getpwuid(stat.st_uid);
        if (errno != 0) {
            perror("getpwuid() failed");
            continue;
        }

        grp = getgrgid(stat.st_gid);
        if (errno != 0) {
            perror("getgrgid() failed");
            continue;
        }

        timefmt = stat.st_mtim.tv_sec > recent ? "%b %d %H:%M"
                : "%b %d  %Y";
        strftime(mtime, sizeof(mtime), timefmt,
                localtime(&stat.st_mtim.tv_sec));

        printf("%lu	%s	%lu	%s	%s	%ld	%s	%s\n",
                stat.st_ino, mode, stat.st_nlink, pwd->pw_name,
                grp->gr_name, stat.st_size, mtime, dirent->d_name);
    }

    if (errno != 0) {
        perror(dirname);
    }
    closedir(dir);

    return errno;
}
