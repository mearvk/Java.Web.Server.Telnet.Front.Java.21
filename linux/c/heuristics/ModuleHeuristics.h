#ifndef MODULE_HEURISTICS_H
#define MODULE_HEURISTICS_H

#include <stddef.h>

#define MH_PASS_THRESHOLD  70
#define MH_MAX_SIZE_BYTES  (50 * 1024 * 1024)
#define MH_MAX_FINDINGS    32
#define MH_FINDING_LEN     128

typedef enum { MH_TYPE_UNKNOWN, MH_TYPE_JAR, MH_TYPE_ZIP, MH_TYPE_JAVA, MH_TYPE_NATIVE } mh_type_t;

typedef struct {
    int        score;                              /* 0–100                    */
    int        suitable;                           /* 1 if score >= threshold  */
    mh_type_t  type;
    int        finding_count;
    char       findings[MH_MAX_FINDINGS][MH_FINDING_LEN];
} mh_result_t;

/**
 * Evaluate a candidate module from a memory buffer.
 * name     — original filename (used for extension hint)
 * data     — raw file bytes
 * length   — byte count
 * result   — caller-allocated result struct to populate
 */
void mh_evaluate(const char *name, const unsigned char *data, size_t length, mh_result_t *result);

/** Print a human-readable summary of the result to stdout. */
void mh_print_result(const mh_result_t *result);

#endif /* MODULE_HEURISTICS_H */
