/*
 * BitcoinBase.c — controlled C implementation
 * Mirrors the security boundary of source/bitcoin/base/BitcoinBase.java.
 *
 * RPC credentials are never placed on the command line. Bitcoin Core cookie
 * authentication is delegated to bitcoin-cli. Command construction is done
 * with argv/execvp rather than a shell, and destructive wallet deletion is
 * intentionally disabled.
 */
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include "BitcoinBase.h"

#define BITCOIN_CLI "bitcoin-cli"
#define BITCOIND "bitcoind"
#define WALLET_NAME "United States"
#define DEFAULT_RPC_PORT "2222"
#define NETWORK "-regtest"
#define RESULT_BUF_SIZE 4096
#define PROCESS_TIMEOUT_SECONDS 30

struct BitcoinBase {
    char hash[32];
};

static const char* rpc_port(void)
{
    const char* value = getenv("BITCOIN_RPC_PORT");
    if (!value || !*value) return DEFAULT_RPC_PORT;
    char* end = NULL;
    long port = strtol(value, &end, 10);
    if (*end != '\0' || port < 1 || port > 65535) return DEFAULT_RPC_PORT;
    return value;
}

static int wait_with_timeout(pid_t pid, int* status)
{
    for (int second = 0; second < PROCESS_TIMEOUT_SECONDS; ++second)
    {
        pid_t result = waitpid(pid, status, WNOHANG);
        if (result == pid) return 0;
        if (result < 0) return -1;
        sleep(1);
    }
    kill(pid, SIGKILL);
    waitpid(pid, status, 0);
    return 1;
}

static int run_argv(char* const argv[], char* output, size_t output_size)
{
    int pipefd[2];
    if (pipe(pipefd) != 0) return -1;

    pid_t pid = fork();
    if (pid < 0)
    {
        close(pipefd[0]);
        close(pipefd[1]);
        return -1;
    }

    if (pid == 0)
    {
        close(pipefd[0]);
        if (dup2(pipefd[1], STDOUT_FILENO) < 0) _exit(126);
        if (dup2(pipefd[1], STDERR_FILENO) < 0) _exit(126);
        close(pipefd[1]);
        execvp(argv[0], argv);
        _exit(127);
    }

    close(pipefd[1]);
    size_t used = 0;
    if (output && output_size > 0) output[0] = '\0';

    while (1)
    {
        char buffer[512];
        ssize_t n = read(pipefd[0], buffer, sizeof(buffer) - 1);
        if (n <= 0) break;
        if (output && used + (size_t)n < output_size)
        {
            memcpy(output + used, buffer, (size_t)n);
            used += (size_t)n;
            output[used] = '\0';
        }
    }
    close(pipefd[0]);

    int status = 0;
    int wait_result = wait_with_timeout(pid, &status);
    if (wait_result != 0) return wait_result == 1 ? -2 : -1;
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    return -1;
}

static int bitcoin_cli(char* const args[], size_t count, char* output, size_t output_size)
{
    char port_arg[32];
    snprintf(port_arg, sizeof(port_arg), "-rpcport=%s", rpc_port());

    char* argv[32];
    if (count + 4 > sizeof(argv) / sizeof(argv[0])) return -1;
    argv[0] = (char*)BITCOIN_CLI;
    argv[1] = (char*)NETWORK;
    argv[2] = port_arg;
    for (size_t i = 0; i < count; ++i) argv[i + 3] = args[i];
    argv[count + 3] = NULL;

    return run_argv(argv, output, output_size);
}

BitcoinBase* BitcoinBase_new(void)
{
    BitcoinBase* self = malloc(sizeof(BitcoinBase));
    if (!self) return NULL;
    strncpy(self->hash, "0xDA717018470E213F", sizeof(self->hash) - 1);
    self->hash[sizeof(self->hash) - 1] = '\0';
    fprintf(stdout, "[BitcoinBase] initialized\n");
    return self;
}

void BitcoinBase_free(BitcoinBase* self)
{
    free(self);
}

void BitcoinBase_start_server_instance(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    char port_arg[32];
    snprintf(port_arg, sizeof(port_arg), "-rpcport=%s", rpc_port());
    char* argv[] = {(char*)BITCOIND, (char*)NETWORK, (char*)"-daemon", port_arg, NULL};
    int rc = run_argv(argv, 4, NULL, 0);
    if (rc != 0) fprintf(stderr, "[BitcoinBase] bitcoind start failed: %d\n", rc);
}

void BitcoinBase_load_wallet(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    char* args[] = {(char*)"loadwallet", (char*)WALLET_NAME};
    int rc = bitcoin_cli(args, 2, NULL, 0);
    if (rc != 0) fprintf(stderr, "[BitcoinBase] loadwallet failed: %d\n", rc);
}

char* BitcoinBase_get_wallet_name(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    char output[RESULT_BUF_SIZE];
    char* args[] = {(char*)"getwalletinfo"};
    int rc = bitcoin_cli(args, 1, output, sizeof(output));
    if (rc != 0 || output[0] == '\0')
    {
        char* err = malloc(3);
        if (err) strcpy(err, "-1");
        return err;
    }
    size_t length = strlen(output);
    char* result = malloc(length + 1);
    if (!result) return NULL;
    memcpy(result, output, length + 1);
    return result;
}

void BitcoinBase_delete_wallet(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    fprintf(stderr, "[BitcoinBase] delete_wallet is disabled; wallet deletion must be performed by an explicit operator-controlled Bitcoin Core workflow.\n");
}

void BitcoinBase_unload_wallet(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    char* args[] = {(char*)"unloadwallet", (char*)WALLET_NAME};
    int rc = bitcoin_cli(args, 2, NULL, 0);
    if (rc != 0) fprintf(stderr, "[BitcoinBase] unloadwallet failed: %d\n", rc);
}

void BitcoinBase_rename_wallet(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    fprintf(stdout, "[BitcoinBase] rename_wallet: no-op; Bitcoin Core has no native rename RPC.\n");
}

void BitcoinBase_add_new_wallet(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    char* args[] = {(char*)"createwallet", (char*)WALLET_NAME};
    int rc = bitcoin_cli(args, 2, NULL, 0);
    if (rc != 0) fprintf(stderr, "[BitcoinBase] createwallet failed: %d\n", rc);
}

void BitcoinBase_send_local_to_remote(BitcoinBase* self, const char* url)
{
    (void)self;
    (void)url;
    fprintf(stdout, "[BitcoinBase] send_local_to_remote: not configured; no transaction is broadcast by this placeholder.\n");
}

void BitcoinBase_send_message_buf(BitcoinBase* self, const char* buf, size_t len)
{
    (void)self;
    if (buf && len > 0) fwrite(buf, 1, len, stdout);
    fputc('\n', stdout);
}

void BitcoinBase_send_message_str(BitcoinBase* self, const char* message)
{
    (void)self;
    if (message) fprintf(stdout, "[BitcoinBase] message: %s\n", message);
}
