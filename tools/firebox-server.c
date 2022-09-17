#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>

#include "firebox-server.h"

static pthread_t server_thread;

static void
fail(const char *path, int line) {
    printf("%s:%d fail\n", path, line);
}

#define CHECK(r) { int r2 = (r); if (r2<0) { fail(__FILE__,__LINE__); } }

#define READER_BUFSIZE (1024*8)
struct Reader {
    size_t cur_line_start, cur, size;
    char buffer[READER_BUFSIZE];

    char *line_start, *line_end;
};

static int
read_line(struct Reader *r)
{
    if (r->cur == 0) {
        r->cur_line_start = r->cur;
    } else {
        r->cur_line_start = r->cur + 2;
    }

    while (1) {
        if (r->cur >= r->size-1) {
            return -1;
        }

        if ((r->buffer[r->cur] == '\r') &&
            (r->buffer[r->cur+1] == '\n'))
        {
            r->line_start = &r->buffer[r->cur_line_start];
            r->line_end = &r->buffer[r->cur];

            return 0;
        }

        r->cur++;
    }

}

static void
send_404(int sock)
{
    static const char msg[] = "char HTTP/1.1 404 Not Found\r\n\r\n";
    size_t len = sizeof(msg) - 1;
    write(sock, msg, len);
}
static void
send_200(int sock)
{
    static const char msg[] = "HTTP/1.1 200 OK\r\n\r\n";
    size_t len = sizeof(msg) - 1;
    write(sock, msg, len);
}

#define SEND_CONST(sock, MSG) {                                         \
    static const char msg[] = MSG;                                      \
    size_t len = sizeof(msg) - 1;                                       \
    write(sock, msg, len);                                              \
    }

static void *
server_thread_func(void *args)
{
    int fd = (int)(intptr_t)args;

    while (1) {
        int client = accept(fd, NULL, NULL);
        struct Reader r;
        CHECK(client);

        ssize_t rdsz = read(client, r.buffer, READER_BUFSIZE);
        if (rdsz < 0) {
            break;
        }
        if (rdsz == READER_BUFSIZE) {
            goto fail;
        }

        r.cur = 0;
        r.size = rdsz;

        int res = read_line(&r);
        if (res < 0) {
            goto fail;
        }

        char path[4096];
        size_t line_len = r.line_end - r.line_start;
        if (line_len < 14) {
            goto fail;
        }

        size_t path_len = line_len - 4 - 9;
        if (path_len >= 4095) {
            send_404(client);
            goto fail;
        }

        memcpy(path, r.line_start+4, path_len);
        path[path_len] = '\0';
        puts(path);

        if (strcmp(path,"/") == 0) {
            send_200(client);
            SEND_CONST(client, "<html><head><meta charset=\"utf-8\"></head><body><p>Welcome to FireBox!!</p><p>ようこそ！</p></body></html>");
        } else {
            send_404(client);
        }

        // 1234 123456789
        //"GET / HTTP/1.1"

        puts(r.buffer);

    fail:
        shutdown(client, SHUT_RDWR);
        close(client);
    }

    return NULL;
}

void
start_firebox_server() {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    CHECK(sock);

    //int yes=1;
    //setsockopt(sock,
    //           SOL_SOCKET, SO_REUSEADDR, (const char *)&yes, sizeof(yes));

    struct sockaddr_in localhost={};
    localhost.sin_family = AF_INET;
    localhost.sin_port = htons(8080);
    localhost.sin_addr.s_addr = htonl(INADDR_ANY);

    CHECK(bind(sock, (struct sockaddr*)&localhost, sizeof(localhost)));
    CHECK(listen(sock, 20));

    pthread_create(&server_thread, NULL,
                   server_thread_func, (void*)(intptr_t)sock);
//    sleep(1);
//    int sock2 = socket(AF_INET, SOCK_STREAM, 0);
//    int cc = connect(sock2, (struct sockaddr*)&localhost, sizeof(localhost));
//    close(cc);
}
