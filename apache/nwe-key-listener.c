/*
 * nwe-key-listener.c
 * ==================
 * Phase 1: Listens on port 80 for public.key. Verifies against GitHub copy.
 * Phase 2: After successful handshake, accepts the next connection as the
 *           nwe-module-installer.jar binary. Calculates SHA-256, installs to
 *           localhost, opens port 8888 on the OS firewall, and launches it.
 *
 * Build:  gcc -o nwe-key-listener nwe-key-listener.c -lcurl -lcrypto
 * Run:    sudo ./nwe-key-listener
 *
 * Requires: libcurl, openssl (apt install libcurl4-openssl-dev libssl-dev)
 *
 * Author: Max Rupplin — MEARVK LLC
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <curl/curl.h>
#include <openssl/sha.h>
#include <sys/stat.h>

#define PORT 80
#define TIMEOUT_SECONDS 1800
#define BUFFER_SIZE 16384
#define MAX_JAR_SIZE (100 * 1024 * 1024) /* 100MB max */
#define INSTALL_PATH "/opt/nwe/nwe-module-installer.jar"
#define INSTALL_DIR "/opt/nwe"
#define GITHUB_KEY_URL "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"

static volatile int running = 1;
static char github_key[BUFFER_SIZE];
static size_t github_key_len = 0;

void handle_signal(int sig) { running = 0; }

struct MemBuf { char *data; size_t len; size_t cap; };

size_t curl_write_cb(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    struct MemBuf *buf = (struct MemBuf *)userdata;
    size_t total = size * nmemb;
    if (buf->len + total >= buf->cap - 1) return 0;
    memcpy(buf->data + buf->len, ptr, total);
    buf->len += total;
    buf->data[buf->len] = '\0';
    return total;
}

int fetch_github_key(void)
{
    CURL *curl = curl_easy_init();
    if (!curl) return 0;
    struct MemBuf buf = { github_key, 0, BUFFER_SIZE };
    memset(github_key, 0, BUFFER_SIZE);
    curl_easy_setopt(curl, CURLOPT_URL, GITHUB_KEY_URL);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buf);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    CURLcode res = curl_easy_perform(curl);
    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
    curl_easy_cleanup(curl);
    if (res != CURLE_OK || http_code != 200) return 0;
    github_key_len = buf.len;
    return 1;
}

/* Strip HTTP headers, return pointer to body */
const char *strip_http(const char *data, int len, int *body_len)
{
    const char *sep = memmem(data, len, "\r\n\r\n", 4);
    if (sep) { sep += 4; *body_len = len - (int)(sep - data); return sep; }
    /* No HTTP headers — treat entire message as body */
    *body_len = len;
    return data;
}

/* Compute SHA-256 hex string */
void sha256_hex(const unsigned char *data, size_t len, char *out)
{
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(data, len, hash);
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++)
        sprintf(out + i * 2, "%02x", hash[i]);
    out[64] = '\0';
}

void send_msg(int fd, const char *msg)
{
    write(fd, msg, strlen(msg));
}

/* Open port 8888 on firewall */
void open_port_8888(void)
{
    /* Try ufw first, then iptables */
    if (system("command -v ufw >/dev/null 2>&1") == 0)
        system("ufw allow 8888/tcp >/dev/null 2>&1");
    else
        system("iptables -I INPUT -p tcp --dport 8888 -j ACCEPT 2>/dev/null");
    printf("[NWE Key Listener] Port 8888 opened on firewall.\n");
}

/* Launch the JAR on port 8888 */
void launch_installer(void)
{
    pid_t pid = fork();
    if (pid == 0)
    {
        /* Child: launch jar */
        setsid();
        execlp("java", "java", "-jar", INSTALL_PATH, NULL);
        perror("exec java");
        _exit(1);
    }
    else if (pid > 0)
    {
        printf("[NWE Key Listener] ✔ nwe-module-installer.jar launched (PID %d) on port 8888\n", pid);
    }
}

int main(int argc, char *argv[])
{
    int server_fd, client_fd, opt = 1;
    struct sockaddr_in addr, client_addr;
    socklen_t client_len = sizeof(client_addr);
    char buffer[BUFFER_SIZE];
    time_t start_time;
    char verified_ip[INET_ADDRSTRLEN] = {0};

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);
    curl_global_init(CURL_GLOBAL_DEFAULT);

    printf("[NWE Key Listener] Fetching public.key from GitHub...\n");
    if (!fetch_github_key())
    {
        fprintf(stderr, "[FATAL] Cannot fetch public.key from GitHub.\n");
        return 1;
    }
    printf("[NWE Key Listener] ✔ GitHub public.key loaded (%zu bytes)\n", github_key_len);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) { perror("socket"); return 1; }
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
    {
        perror("bind (port 80 — run with sudo)");
        close(server_fd); return 1;
    }
    listen(server_fd, 5);
    printf("[NWE Key Listener] Listening on port %d (30 min timeout)\n", PORT);
    start_time = time(NULL);

    struct timeval tv = { 5, 0 };
    setsockopt(server_fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    /* ═══ PHASE 1: Wait for public.key handshake ═══ */
    int handshake_done = 0;
    while (running && !handshake_done)
    {
        if (difftime(time(NULL), start_time) >= TIMEOUT_SECONDS)
        {
            printf("[NWE Key Listener] 30 min timeout — exiting.\n");
            close(server_fd); curl_global_cleanup(); return 1;
        }

        client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0) continue;

        char *client_ip = inet_ntoa(client_addr.sin_addr);
        printf("[Phase 1] Connection from %s\n", client_ip);

        memset(buffer, 0, BUFFER_SIZE);
        int bytes = read(client_fd, buffer, BUFFER_SIZE - 1);
        if (bytes <= 0) { close(client_fd); continue; }

        int body_len = 0;
        const char *body = strip_http(buffer, bytes, &body_len);

        if ((size_t)body_len == github_key_len && memcmp(body, github_key, github_key_len) == 0)
        {
            printf("[Phase 1] ✔ public.key VERIFIED from %s\n", client_ip);
            send_msg(client_fd, "ACK\n");
            strncpy(verified_ip, client_ip, INET_ADDRSTRLEN - 1);
            handshake_done = 1;
        }
        else
        {
            printf("[Phase 1] ✗ Key mismatch from %s — ignored\n", client_ip);
            send_msg(client_fd, "REJECTED\n");
        }
        close(client_fd);
    }

    if (!handshake_done) { close(server_fd); curl_global_cleanup(); return 1; }

    /* ═══ PHASE 2: Accept JAR binary from verified IP ═══ */
    printf("[Phase 2] Waiting for JAR from %s...\n", verified_ip);
    time_t phase2_start = time(NULL);

    while (running)
    {
        if (difftime(time(NULL), phase2_start) >= TIMEOUT_SECONDS)
        {
            printf("[Phase 2] Timeout waiting for JAR.\n");
            break;
        }

        client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd < 0) continue;

        char *client_ip = inet_ntoa(client_addr.sin_addr);

        /* Only accept from the verified IP */
        if (strcmp(client_ip, verified_ip) != 0)
        {
            printf("[Phase 2] Rejected connection from %s (expected %s)\n", client_ip, verified_ip);
            send_msg(client_fd, "REJECTED\n");
            close(client_fd);
            continue;
        }

        printf("[Phase 2] Receiving JAR from %s...\n", client_ip);

        /* Read all data (strip HTTP if present) */
        unsigned char *jar_buf = malloc(MAX_JAR_SIZE);
        if (!jar_buf) { close(client_fd); break; }

        size_t total_read = 0;
        int r;
        while ((r = read(client_fd, jar_buf + total_read, MAX_JAR_SIZE - total_read)) > 0)
            total_read += r;

        /* Strip HTTP headers if present */
        int jar_len = 0;
        const char *jar_data = strip_http((char *)jar_buf, total_read, &jar_len);

        /* Verify it's a JAR (PK magic bytes) */
        if (jar_len < 4 || jar_data[0] != 'P' || jar_data[1] != 'K')
        {
            printf("[Phase 2] ✗ Not a valid JAR file. Ignoring.\n");
            send_msg(client_fd, "REJECTED NOT A JAR\n");
            free(jar_buf); close(client_fd);
            continue;
        }

        /* Compute SHA-256 */
        char sha_hex[65];
        sha256_hex((unsigned char *)jar_data, jar_len, sha_hex);
        printf("[Phase 2] JAR received: %d bytes, SHA-256: %s\n", jar_len, sha_hex);

        /* Install */
        mkdir(INSTALL_DIR, 0755);
        FILE *fp = fopen(INSTALL_PATH, "wb");
        if (!fp) { perror("fopen"); free(jar_buf); close(client_fd); break; }
        fwrite(jar_data, 1, jar_len, fp);
        fclose(fp);

        printf("[Phase 2] ✔ Installed to %s\n", INSTALL_PATH);

        /* Open port 8888 */
        open_port_8888();

        /* Launch */
        launch_installer();

        /* Send confirmation with SHA */
        char response[256];
        snprintf(response, sizeof(response), "INSTALLED %d bytes SHA256:%s\n", jar_len, sha_hex);
        send_msg(client_fd, response);

        free(jar_buf);
        close(client_fd);
        break; /* Done */
    }

    close(server_fd);
    curl_global_cleanup();
    printf("[NWE Key Listener] Complete.\n");
    return 0;
}
