#include "ModuleHeuristics.h"
#include <stdio.h>
#include <string.h>
#include <strings.h>

/* ── Internal helpers ──────────────────────────────────────────────────────── */

static void add_finding(mh_result_t *r, const char *msg)
{
    if (r->finding_count >= MH_MAX_FINDINGS) return;
    strncpy(r->findings[r->finding_count++], msg, MH_FINDING_LEN - 1);
}

static mh_type_t detect_type(const char *name, const unsigned char *data, size_t len)
{
    /* ZIP/JAR magic bytes: PK (0x50 0x4B) */
    if (len >= 4 && data[0] == 0x50 && data[1] == 0x4B)
    {
        /* Heuristic: if the first 512 bytes contain "META-INF" it is a jar */
        size_t scan = len < 512 ? len : 512;
        for (size_t i = 0; i + 8 < scan; i++)
            if (memcmp(data + i, "META-INF", 8) == 0) return MH_TYPE_JAR;
        return MH_TYPE_ZIP;
    }

    /* ELF magic: native shared object / executable */
    if (len >= 4 && data[0] == 0x7F && data[1] == 'E' && data[2] == 'L' && data[3] == 'F')
        return MH_TYPE_NATIVE;

    /* Java source by extension */
    if (name)
    {
        size_t nlen = strlen(name);
        if (nlen > 5 && strcasecmp(name + nlen - 5, ".java") == 0) return MH_TYPE_JAVA;
    }

    return MH_TYPE_UNKNOWN;
}

/* ── Public API ────────────────────────────────────────────────────────────── */

void mh_evaluate(const char *name, const unsigned char *data, size_t length, mh_result_t *result)
{
    memset(result, 0, sizeof(*result));

    /* 1. Type recognised (+20) */
    result->type = detect_type(name, data, length);
    if (result->type == MH_TYPE_UNKNOWN)
    {
        add_finding(result, "FAIL unrecognised type — must be .jar, .zip, .java, or ELF");
        result->suitable = 0;
        return;
    }
    result->score += 20;
    switch (result->type)
    {
        case MH_TYPE_JAR:    add_finding(result, "OK   type: jar");    break;
        case MH_TYPE_ZIP:    add_finding(result, "OK   type: zip");    break;
        case MH_TYPE_JAVA:   add_finding(result, "OK   type: java");   break;
        case MH_TYPE_NATIVE: add_finding(result, "OK   type: native ELF"); break;
        default: break;
    }

    /* 2. Non-empty (+10) */
    if (length > 0)
    {
        result->score += 10;
        add_finding(result, "OK   file is non-empty");
    }
    else
    {
        add_finding(result, "FAIL file is empty");
        result->suitable = 0;
        return;
    }

    /* 3. Size within limit (+10) */
    if (length <= MH_MAX_SIZE_BYTES)
    {
        result->score += 10;
        add_finding(result, "OK   size within 50 MB limit");
    }
    else
    {
        add_finding(result, "WARN size exceeds 50 MB — server may reject");
    }

    /* 4. Type-specific checks */
    if (result->type == MH_TYPE_JAR || result->type == MH_TYPE_ZIP)
    {
        /* Verify ZIP local-file header signature at offset 0 */
        if (length >= 30 && data[0] == 0x50 && data[1] == 0x4B && data[2] == 0x03 && data[3] == 0x04)
        {
            result->score += 30;
            add_finding(result, "OK   valid ZIP local-file header");
        }
        else
        {
            add_finding(result, "WARN ZIP local-file header not found at offset 0");
        }
    }
    else if (result->type == MH_TYPE_JAVA)
    {
        /* Scan first 2 KB for Java declarations */
        size_t scan = length < 2048 ? length : 2048;
        char preview[2049];
        memcpy(preview, data, scan);
        preview[scan] = '\0';

        if (strstr(preview, "public class") || strstr(preview, "public interface"))
        {
            result->score += 20;
            add_finding(result, "OK   public type declaration found");
        }
        else
        {
            add_finding(result, "WARN no public class/interface found");
        }

        if (strstr(preview, "package "))
        {
            result->score += 10;
            add_finding(result, "OK   package declaration present");
        }

        if (strstr(preview, "Runtime.getRuntime") || strstr(preview, "ProcessBuilder"))
            add_finding(result, "WARN process-execution pattern detected — review before install");
        else
        {
            result->score += 10;
            add_finding(result, "OK   no process-execution patterns found");
        }
    }
    else if (result->type == MH_TYPE_NATIVE)
    {
        /* ELF: check 64-bit class byte (offset 4: 1=32-bit, 2=64-bit) */
        if (length > 4 && data[4] == 2)
        {
            result->score += 20;
            add_finding(result, "OK   ELF 64-bit class");
        }
        else if (length > 4 && data[4] == 1)
        {
            result->score += 10;
            add_finding(result, "INFO ELF 32-bit class");
        }

        /* ELF type offset 16 (2 bytes LE): 3 = ET_DYN (shared object) */
        if (length > 17)
        {
            unsigned short etype = (unsigned short)(data[16] | (data[17] << 8));
            if (etype == 3)
            {
                result->score += 20;
                add_finding(result, "OK   ELF type ET_DYN (shared object — loadable)");
            }
            else
            {
                add_finding(result, "WARN ELF type is not ET_DYN — may not be loadable as a module");
            }
        }
    }

    /* 5. Safe name (+5) */
    if (name)
    {
        int safe = 1;
        for (const char *c = name; *c; c++)
            if (!((*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z') ||
                  (*c >= '0' && *c <= '9') || *c == '.' || *c == '_' || *c == '-'))
                { safe = 0; break; }
        if (safe) { result->score += 5; add_finding(result, "OK   module name is safe"); }
        else        add_finding(result, "WARN module name contains special characters");
    }

    if (result->score > 100) result->score = 100;
    result->suitable = (result->score >= MH_PASS_THRESHOLD);
}

void mh_print_result(const mh_result_t *result)
{
    printf("ModuleHeuristics score: %d/100 — %s\n",
           result->score,
           result->suitable ? "SUITABLE for install" : "NOT suitable");
    for (int i = 0; i < result->finding_count; i++)
        printf("  %s\n", result->findings[i]);
}
