/*
 * mod_nwe_key.c — Apache2 module for NWE public.key handshake + JAR install
 * ===========================================================================
 * Drop-in Apache module. Handles POST to /nwe-key-listener endpoint.
 *
 * Phase 1: POST /nwe-key-listener/handshake — body must match GitHub public.key
 * Phase 2: POST /nwe-key-listener/install   — body is JAR binary (from verified IP)
 *
 * Build:  apxs -i -a -c mod_nwe_key.c -lcurl -lcrypto
 * Enable: Already done by apxs -a (adds LoadModule to apache2.conf)
 * Restart: sudo systemctl restart apache2
 *
 * Author: Max Rupplin — MEARVK LLC
 */

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_log.h"
#include "ap_config.h"
#include "apr_strings.h"
#include "apr_file_io.h"

#include <string.h>
#include <stdlib.h>
#include <curl/curl.h>
#include <openssl/sha.h>
#include <sys/stat.h>

#define GITHUB_KEY_URL "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
#define INSTALL_PATH "/opt/nwe/nwe-module-installer.jar"
#define INSTALL_DIR "/opt/nwe"
#define MAX_BODY (100 * 1024 * 1024)

/* Shared state: verified IP after handshake */
static char verified_ip[64] = {0};
static apr_time_t verified_time = 0;
#define VERIFY_TTL_USEC (1800 * 1000000LL) /* 30 min */

/* curl write callback */
struct CurlBuf { char *data; size_t len; size_t cap; };

static size_t curl_cb(void *ptr, size_t size, size_t nmemb, void *ud)
{
    struct CurlBuf *b = (struct CurlBuf *)ud;
    size_t total = size * nmemb;
    if (b->len + total >= b->cap) return 0;
    memcpy(b->data + b->len, ptr, total);
    b->len += total;
    return total;
}

static int fetch_github_key(char *out, size_t cap, size_t *out_len)
{
    CURL *c = curl_easy_init();
    if (!c) return 0;
    struct CurlBuf buf = { out, 0, cap };
    curl_easy_setopt(c, CURLOPT_URL, GITHUB_KEY_URL);
    curl_easy_setopt(c, CURLOPT_WRITEFUNCTION, curl_cb);
    curl_easy_setopt(c, CURLOPT_WRITEDATA, &buf);
    curl_easy_setopt(c, CURLOPT_TIMEOUT, 10L);
    curl_easy_setopt(c, CURLOPT_FOLLOWLOCATION, 1L);
    CURLcode res = curl_easy_perform(c);
    long code = 0;
    curl_easy_getinfo(c, CURLINFO_RESPONSE_CODE, &code);
    curl_easy_cleanup(c);
    if (res != CURLE_OK || code != 200) return 0;
    *out_len = buf.len;
    return 1;
}

static void sha256_hex(const unsigned char *data, size_t len, char *hex)
{
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(data, len, hash);
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++)
        sprintf(hex + i * 2, "%02x", hash[i]);
    hex[64] = '\0';
}

/* Read full request body */
static int read_body(request_rec *r, char **buf, size_t *len)
{
    int rc = ap_setup_client_block(r, REQUEST_CHUNKED_DECHUNK);
    if (rc != OK) return rc;
    if (!ap_should_client_block(r)) { *buf = NULL; *len = 0; return OK; }

    size_t cap = 8192, total = 0;
    char *b = apr_palloc(r->pool, cap);
    long read;
    while ((read = ap_get_client_block(r, b + total, cap - total)) > 0)
    {
        total += read;
        if (total >= cap - 1)
        {
            cap *= 2;
            if (cap > MAX_BODY) break;
            char *nb = apr_palloc(r->pool, cap);
            memcpy(nb, b, total);
            b = nb;
        }
    }
    *buf = b;
    *len = total;
    return OK;
}

static int nwe_handler(request_rec *r)
{
    if (!r->handler || strcmp(r->handler, "nwe-key-handler") != 0)
        return DECLINED;

    if (r->method_number != M_POST) return HTTP_METHOD_NOT_ALLOWED;

    const char *client_ip = r->useragent_ip ? r->useragent_ip : r->connection->client_ip;

    /* ── Handshake endpoint ── */
    if (strstr(r->uri, "/handshake"))
    {
        char *body; size_t body_len;
        if (read_body(r, &body, &body_len) != OK) return HTTP_INTERNAL_SERVER_ERROR;

        char github_key[8192]; size_t gk_len = 0;
        if (!fetch_github_key(github_key, sizeof(github_key), &gk_len))
        {
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "ERROR Cannot fetch GitHub public.key\n");
            return OK;
        }

        if (body_len == gk_len && memcmp(body, github_key, gk_len) == 0)
        {
            strncpy(verified_ip, client_ip, sizeof(verified_ip) - 1);
            verified_time = apr_time_now();
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "ACK\n");
        }
        else
        {
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "REJECTED\n");
            return HTTP_FORBIDDEN;
        }
        return OK;
    }

    /* ── Install endpoint ── */
    if (strstr(r->uri, "/install"))
    {
        /* Verify sender is the handshake-verified IP within TTL */
        if (verified_ip[0] == '\0' || strcmp(client_ip, verified_ip) != 0)
        {
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "REJECTED Handshake required first\n");
            return HTTP_FORBIDDEN;
        }
        if (apr_time_now() - verified_time > VERIFY_TTL_USEC)
        {
            verified_ip[0] = '\0';
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "REJECTED Handshake expired (30 min)\n");
            return HTTP_FORBIDDEN;
        }

        char *body; size_t body_len;
        if (read_body(r, &body, &body_len) != OK) return HTTP_INTERNAL_SERVER_ERROR;

        /* Verify JAR magic */
        if (body_len < 4 || body[0] != 'P' || body[1] != 'K')
        {
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "REJECTED Not a JAR\n");
            return HTTP_BAD_REQUEST;
        }

        /* SHA-256 */
        char sha_hex[65];
        sha256_hex((unsigned char *)body, body_len, sha_hex);

        /* Write to disk */
        mkdir(INSTALL_DIR, 0755);
        FILE *fp = fopen(INSTALL_PATH, "wb");
        if (!fp)
        {
            ap_set_content_type(r, "text/plain");
            ap_rprintf(r, "ERROR Cannot write to %s\n", INSTALL_PATH);
            return HTTP_INTERNAL_SERVER_ERROR;
        }
        fwrite(body, 1, body_len, fp);
        fclose(fp);

        /* Open port 8888 */
        system("ufw allow 8888/tcp >/dev/null 2>&1 || iptables -I INPUT -p tcp --dport 8888 -j ACCEPT 2>/dev/null");

        /* Launch */
        system("java -jar " INSTALL_PATH " &");

        /* Respond */
        ap_set_content_type(r, "text/plain");
        ap_rprintf(r, "INSTALLED %zu bytes SHA256:%s\n", body_len, sha_hex);

        /* Clear verified IP */
        verified_ip[0] = '\0';
        return OK;
    }

    return DECLINED;
}

static void register_hooks(apr_pool_t *p)
{
    ap_hook_handler(nwe_handler, NULL, NULL, APR_HOOK_MIDDLE);
    curl_global_init(CURL_GLOBAL_DEFAULT);
}

module AP_MODULE_DECLARE_DATA nwe_key_module = {
    STANDARD20_MODULE_STUFF,
    NULL, NULL, NULL, NULL, NULL,
    register_hooks
};
