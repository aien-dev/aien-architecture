/*
 * crumb: RFC-0001 Crumb Protocol (v1.0.0) tool. Single file, C11, no dependencies.
 * Spec: aien-dev/crumb-spec SPEC.md + ROLES.md (archived, pinned at 10b8251).
 *
 *   crumb seed <root> [-n] [-v]     write/refresh .crumb in every qualifying directory
 *   crumb create <dir> <name> <purpose> [layer]
 *   crumb claim <agent> <dir> <target> <intent> [ttl_seconds]   scent + advisory lock
 *   crumb update <agent> <dir> <focus> [ttl_seconds]            refresh scent
 *   crumb whisper <from> <dir> <to|-> <message> [priority] [target_file]
 *   crumb close <agent> <dir> <target> [action] [message]       release lock, history vector
 *   crumb sniff <agent> <dir>
 *   crumb list [path]
 *   crumb validate [path]
 */
#define _DEFAULT_SOURCE
#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define SCHEMA "1.0.0"
#define HISTORY_CAP 20
#define SCENT_TTL 3600
#define LOCK_TTL 1800
#define WHISPER_RETENTION (24 * 3600)

static void die(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "crumb: ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    exit(1);
}
static void *xmalloc(size_t n) { void *p = malloc(n ? n : 1); if (!p) die("out of memory"); return p; }
static void *xrealloc(void *q, size_t n) { void *p = realloc(q, n ? n : 1); if (!p) die("out of memory"); return p; }
static char *xstrdup(const char *s) { size_t n = strlen(s) + 1; char *p = xmalloc(n); memcpy(p, s, n); return p; }

/* ---------- growable buffer ---------- */
typedef struct { char *p; size_t n, cap; } Buf;
static void bput(Buf *b, const char *s, size_t n) {
    if (b->n + n + 1 > b->cap) { b->cap = (b->n + n + 1) * 2; b->p = xrealloc(b->p, b->cap); }
    memcpy(b->p + b->n, s, n); b->n += n; b->p[b->n] = 0;
}
static void bstr(Buf *b, const char *s) { bput(b, s, strlen(s)); }

/* ---------- minimal ordered JSON DOM (preserves unknown fields) ---------- */
enum { JNULL, JTRUE, JFALSE, JNUM, JSTR, JARR, JOBJ };
typedef struct J { int t; char *s; struct J **v; char **k; size_t n, cap; } J;

static J *jnew(int t) { J *j = xmalloc(sizeof *j); memset(j, 0, sizeof *j); j->t = t; return j; }
static J *jstr(const char *s) { J *j = jnew(JSTR); j->s = xstrdup(s); return j; }
static J *jnum(long x) { char t[32]; snprintf(t, sizeof t, "%ld", x); J *j = jnew(JNUM); j->s = xstrdup(t); return j; }
static void jgrow(J *a) { if (a->n == a->cap) { a->cap = a->cap ? a->cap * 2 : 4; a->v = xrealloc(a->v, a->cap * sizeof *a->v); if (a->t == JOBJ) a->k = xrealloc(a->k, a->cap * sizeof *a->k); } }
static void jpush(J *a, J *v) { jgrow(a); a->v[a->n++] = v; }
static J *jget(const J *o, const char *key) {
    if (!o || o->t != JOBJ) return NULL;
    for (size_t i = 0; i < o->n; i++) if (!strcmp(o->k[i], key)) return o->v[i];
    return NULL;
}
static void jset(J *o, const char *key, J *v) {
    for (size_t i = 0; i < o->n; i++) if (!strcmp(o->k[i], key)) { o->v[i] = v; return; }
    jgrow(o); o->k[o->n] = xstrdup(key); o->v[o->n++] = v;
}
static void jdel(J *o, const char *key) {
    for (size_t i = 0; i < o->n; i++) if (!strcmp(o->k[i], key)) {
        memmove(o->k + i, o->k + i + 1, (o->n - i - 1) * sizeof *o->k);
        memmove(o->v + i, o->v + i + 1, (o->n - i - 1) * sizeof *o->v);
        o->n--; return;
    }
}
static const char *jstrval(const J *o, const char *key) { J *v = jget(o, key); return v && v->t == JSTR ? v->s : NULL; }
static J *jobj_of(J *o, const char *key) {  /* get-or-create object member */
    J *v = jget(o, key);
    if (!v || v->t != JOBJ) { v = jnew(JOBJ); jset(o, key, v); }
    return v;
}
static J *jarr_of(J *o, const char *key) {
    J *v = jget(o, key);
    if (!v || v->t != JARR) { v = jnew(JARR); jset(o, key, v); }
    return v;
}

static void jescape(Buf *b, const char *s) {
    bput(b, "\"", 1);
    for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
        char t[8];
        switch (*p) {
        case '"': bstr(b, "\\\""); break;
        case '\\': bstr(b, "\\\\"); break;
        case '\n': bstr(b, "\\n"); break;
        case '\r': bstr(b, "\\r"); break;
        case '\t': bstr(b, "\\t"); break;
        default:
            if (*p < 0x20) { snprintf(t, sizeof t, "\\u%04x", *p); bstr(b, t); }
            else bput(b, (const char *)p, 1);
        }
    }
    bput(b, "\"", 1);
}
static void jprint(const J *j, Buf *b, int ind) {
    switch (j->t) {
    case JNULL: bstr(b, "null"); break;
    case JTRUE: bstr(b, "true"); break;
    case JFALSE: bstr(b, "false"); break;
    case JNUM: bstr(b, j->s); break;
    case JSTR: jescape(b, j->s); break;
    case JARR:
        if (!j->n) { bstr(b, "[]"); break; }
        bstr(b, "[\n");
        for (size_t i = 0; i < j->n; i++) {
            for (int s = 0; s < ind + 2; s++) bput(b, " ", 1);
            jprint(j->v[i], b, ind + 2);
            bstr(b, i + 1 < j->n ? ",\n" : "\n");
        }
        for (int s = 0; s < ind; s++) bput(b, " ", 1);
        bput(b, "]", 1); break;
    case JOBJ:
        if (!j->n) { bstr(b, "{}"); break; }
        bstr(b, "{\n");
        for (size_t i = 0; i < j->n; i++) {
            for (int s = 0; s < ind + 2; s++) bput(b, " ", 1);
            jescape(b, j->k[i]); bstr(b, ": ");
            jprint(j->v[i], b, ind + 2);
            bstr(b, i + 1 < j->n ? ",\n" : "\n");
        }
        for (int s = 0; s < ind; s++) bput(b, " ", 1);
        bput(b, "}", 1); break;
    }
}
static char *jdump(const J *j) { Buf b = {0}; jprint(j, &b, 0); bstr(&b, "\n"); return b.p; }

typedef struct { const char *p; int depth; int err; } P;
static void pws(P *p) { while (*p->p == ' ' || *p->p == '\t' || *p->p == '\n' || *p->p == '\r') p->p++; }
static void putf8(Buf *b, unsigned c) {
    if (c >= 0xD800 && c < 0xE000) c = 0xFFFD;
    char t[4]; int n;
    if (c < 0x80) { t[0] = (char)c; n = 1; }
    else if (c < 0x800) { t[0] = (char)(0xC0 | c >> 6); t[1] = (char)(0x80 | (c & 63)); n = 2; }
    else if (c < 0x10000) { t[0] = (char)(0xE0 | c >> 12); t[1] = (char)(0x80 | ((c >> 6) & 63)); t[2] = (char)(0x80 | (c & 63)); n = 3; }
    else { t[0] = (char)(0xF0 | c >> 18); t[1] = (char)(0x80 | ((c >> 12) & 63)); t[2] = (char)(0x80 | ((c >> 6) & 63)); t[3] = (char)(0x80 | (c & 63)); n = 4; }
    bput(b, t, (size_t)n);
}
static int hex4(const char *s, unsigned *out) {
    unsigned v = 0;
    for (int i = 0; i < 4; i++) {
        char c = s[i]; v <<= 4;
        if (c >= '0' && c <= '9') v |= (unsigned)(c - '0');
        else if (c >= 'a' && c <= 'f') v |= (unsigned)(c - 'a' + 10);
        else if (c >= 'A' && c <= 'F') v |= (unsigned)(c - 'A' + 10);
        else return 0;
    }
    *out = v; return 1;
}
static char *pstring(P *p) {
    Buf b = {0}; bstr(&b, "");
    p->p++;
    while (*p->p && *p->p != '"') {
        if (*p->p == '\\') {
            p->p++;
            switch (*p->p) {
            case 'n': bput(&b, "\n", 1); break;
            case 't': bput(&b, "\t", 1); break;
            case 'r': bput(&b, "\r", 1); break;
            case 'b': bput(&b, "\b", 1); break;
            case 'f': bput(&b, "\f", 1); break;
            case '/': case '\\': case '"': bput(&b, p->p, 1); break;
            case 'u': {
                unsigned c, d;
                if (!hex4(p->p + 1, &c)) { p->err = 1; return b.p; }
                p->p += 4;
                if (c >= 0xD800 && c < 0xDC00 && p->p[1] == '\\' && p->p[2] == 'u' && hex4(p->p + 3, &d) && d >= 0xDC00 && d < 0xE000) {
                    c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00); p->p += 6;
                }
                putf8(&b, c); break;
            }
            default: p->err = 1; return b.p;
            }
            p->p++;
        } else bput(&b, p->p++, 1);
    }
    if (*p->p != '"') p->err = 1; else p->p++;
    return b.p;
}
static J *pvalue(P *p) {
    pws(p);
    if (p->err || ++p->depth > 64) { p->err = 1; return NULL; }
    J *r = NULL;
    char c = *p->p;
    if (c == '{') {
        r = jnew(JOBJ); p->p++; pws(p);
        if (*p->p == '}') p->p++;
        else for (;;) {
            pws(p);
            if (*p->p != '"') { p->err = 1; break; }
            char *k = pstring(p); pws(p);
            if (*p->p != ':') { p->err = 1; break; }
            p->p++;
            J *v = pvalue(p); if (!v) break;
            jset(r, k, v); pws(p);
            if (*p->p == ',') { p->p++; continue; }
            if (*p->p == '}') { p->p++; break; }
            p->err = 1; break;
        }
    } else if (c == '[') {
        r = jnew(JARR); p->p++; pws(p);
        if (*p->p == ']') p->p++;
        else for (;;) {
            J *v = pvalue(p); if (!v) break;
            jpush(r, v); pws(p);
            if (*p->p == ',') { p->p++; continue; }
            if (*p->p == ']') { p->p++; break; }
            p->err = 1; break;
        }
    } else if (c == '"') { r = jnew(JSTR); r->s = pstring(p); }
    else if (!strncmp(p->p, "true", 4)) { r = jnew(JTRUE); p->p += 4; }
    else if (!strncmp(p->p, "false", 5)) { r = jnew(JFALSE); p->p += 5; }
    else if (!strncmp(p->p, "null", 4)) { r = jnew(JNULL); p->p += 4; }
    else if (c == '-' || (c >= '0' && c <= '9')) {
        const char *s = p->p;
        while (*p->p == '-' || *p->p == '+' || *p->p == '.' || *p->p == 'e' || *p->p == 'E' || (*p->p >= '0' && *p->p <= '9')) p->p++;
        r = jnew(JNUM); r->s = xmalloc((size_t)(p->p - s) + 1); memcpy(r->s, s, (size_t)(p->p - s)); r->s[p->p - s] = 0;
        { char *end; (void)strtod(r->s, &end); if (end == r->s || *end) p->err = 1; }
    } else p->err = 1;
    p->depth--;
    return p->err ? NULL : r;
}
static J *jparse(const char *s) {
    P p = { s, 0, 0 };
    J *j = pvalue(&p);
    if (!j) return NULL;
    pws(&p);
    return *p.p ? NULL : j;
}

/* ---------- files ---------- */
static char *slurp(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    Buf b = {0}; bstr(&b, "");
    char t[4096]; size_t n;
    while ((n = fread(t, 1, sizeof t, f)) > 0) bput(&b, t, n);
    fclose(f);
    return b.p;
}
static void spit(const char *path, const char *data) {
    size_t tn = strlen(path) + 32; char *tmp = xmalloc(tn);
    snprintf(tmp, tn, "%s.tmp%ld", path, (long)getpid());
    FILE *f = fopen(tmp, "wb");
    if (!f) die("cannot write %s: %s", tmp, strerror(errno));
    if (fputs(data, f) < 0 || fclose(f) != 0) die("write failed: %s", tmp);
    if (rename(tmp, path) != 0) die("rename failed: %s", path);
}
static char *pjoin(const char *a, const char *b) {
    size_t n = strlen(a) + strlen(b) + 2; char *p = xmalloc(n);
    snprintf(p, n, "%s/%s", a, b); return p;
}
static char *absdir(const char *d) {
    char r[PATH_MAX];
    if (!realpath(d, r)) die("no such directory: %s", d);
    struct stat st; if (stat(r, &st) || !S_ISDIR(st.st_mode)) die("not a directory: %s", d);
    return xstrdup(r);
}
static const char *base_of(const char *p) { const char *s = strrchr(p, '/'); return s && s[1] ? s + 1 : p; }

/* ---------- time ---------- */
static void now_iso(char *out) { time_t t = time(NULL); struct tm tm; gmtime_r(&t, &tm); strftime(out, 21, "%Y-%m-%dT%H:%M:%SZ", &tm); }
static long parse_iso(const char *s) {  /* tolerant: first 19 chars, treated as UTC; -1 on failure */
    struct tm tm; memset(&tm, 0, sizeof tm);
    int y, mo, d, h, mi, se;
    if (!s || sscanf(s, "%d-%d-%dT%d:%d:%d", &y, &mo, &d, &h, &mi, &se) != 6) return -1;
    tm.tm_year = y - 1900; tm.tm_mon = mo - 1; tm.tm_mday = d; tm.tm_hour = h; tm.tm_min = mi; tm.tm_sec = se;
    return (long)timegm(&tm);
}
static long jlong(const J *o, const char *key, long dflt) { J *v = jget(o, key); return v && v->t == JNUM ? atol(v->s) : dflt; }

/* ---------- .crumb.local (ephemeral bus) ---------- */
typedef struct { char *path, *dir, *before; J *root; } Local;

static void sweep(J *root) {  /* SPEC 5.4 */
    long now = (long)time(NULL);
    J *sc = jget(root, "active_scents");
    if (sc && sc->t == JOBJ) for (size_t i = sc->n; i-- > 0;) {
        long u = parse_iso(jstrval(sc->v[i], "updated_at"));
        if (u < 0 || now - u > jlong(sc->v[i], "ttl_seconds", SCENT_TTL)) jdel(sc, sc->k[i]);
    }
    J *lk = jget(root, "locks");
    if (lk && lk->t == JOBJ) for (size_t i = lk->n; i-- > 0;) {
        long u = parse_iso(jstrval(lk->v[i], "acquired_at"));
        if (u < 0 || now - u > jlong(lk->v[i], "ttl_seconds", LOCK_TTL)) jdel(lk, lk->k[i]);
    }
    J *wh = jget(root, "whispers");
    if (wh && wh->t == JARR) {
        size_t m = 0;
        for (size_t i = 0; i < wh->n; i++) {
            long u = parse_iso(jstrval(wh->v[i], "timestamp"));
            if (u >= 0 && now - u > WHISPER_RETENTION) continue;
            wh->v[m++] = wh->v[i];
        }
        wh->n = m;
    }
}
static Local local_open(const char *dir) {
    Local l; l.dir = absdir(dir); l.path = pjoin(l.dir, ".crumb.local");
    char *txt = slurp(l.path);
    l.root = txt ? jparse(txt) : NULL;
    if (txt && (!l.root || l.root->t != JOBJ)) die("%s is not valid JSON; fix or move it aside", l.path);
    if (!l.root) l.root = jnew(JOBJ);
    l.before = jdump(l.root);                 /* compare against the file as parsed, before any change */
    if (!jget(l.root, "schema_version")) {    /* adopt legacy/foreign file, keep every existing field */
        J *n = jnew(JOBJ); jset(n, "schema_version", jstr(SCHEMA)); jset(n, "directory", jstr(l.dir));
        for (size_t i = 0; i < l.root->n; i++) jset(n, l.root->k[i], l.root->v[i]);
        l.root = n;
    }
    if (!jget(l.root, "directory")) jset(l.root, "directory", jstr(l.dir));
    sweep(l.root);
    return l;
}
static void local_save(Local *l) {
    char *now = jdump(l->root);
    if (strcmp(now, l->before)) spit(l->path, now);
}
static void history_add(J *root, const char *agent, const char *action, const char *target, const char *intent) {
    char ts[21]; now_iso(ts);
    J *h = jarr_of(root, "history"), *e = jnew(JOBJ);
    jset(e, "agent", jstr(agent)); jset(e, "action", jstr(action)); jset(e, "target", jstr(target));
    jset(e, "intent", jstr(intent)); jset(e, "vector", jstr("")); jset(e, "timestamp", jstr(ts));
    jpush(h, e);
    if (h->n > HISTORY_CAP) { size_t d = h->n - HISTORY_CAP; memmove(h->v, h->v + d, HISTORY_CAP * sizeof *h->v); h->n = HISTORY_CAP; }
}
static void whisper_add(J *root, const char *from, const char *to, const char *msg, const char *prio, const char *tf) {
    char ts[21]; now_iso(ts);
    J *w = jarr_of(root, "whispers"), *e = jnew(JOBJ);
    jset(e, "from", jstr(from));
    if (to && strcmp(to, "-")) jset(e, "to", jstr(to));
    jset(e, "message", jstr(msg));
    if (tf && *tf) jset(e, "target_file", jstr(tf));
    jset(e, "timestamp", jstr(ts));
    if (prio && *prio) jset(e, "priority", jstr(prio));
    jpush(w, e);
}
static void scent_set(J *root, const char *agent, const char *focus, long ttl) {
    char ts[21]; now_iso(ts);
    J *s = jobj_of(root, "active_scents"), *e = jget(s, agent);
    if (!e || e->t != JOBJ) { e = jnew(JOBJ); jset(s, agent, e); }
    jset(e, "focus", jstr(focus)); jset(e, "updated_at", jstr(ts)); jset(e, "ttl_seconds", jnum(ttl));
}
static int has_lock_by(J *root, const char *agent) {
    J *lk = jget(root, "locks");
    if (!lk || lk->t != JOBJ) return 0;
    for (size_t i = 0; i < lk->n; i++) { const char *h = jstrval(lk->v[i], "holder"); if (h && !strcmp(h, agent)) return 1; }
    return 0;
}

/* ---------- operations ---------- */
static int cmd_claim(const char *agent, const char *dir, const char *target, const char *intent, long ttl) {
    Local l = local_open(dir);
    J *lk = jget(l.root, "locks");
    J *cur = lk ? jget(lk, target) : NULL;
    if (cur) {
        const char *h = jstrval(cur, "holder");
        if (h && strcmp(h, agent)) {   /* ROLES.md section 2: active lock on same target, must not proceed */
            printf("BLOCKED %s held by %s since %s (%s)\n", target, h, jstrval(cur, "acquired_at") ? jstrval(cur, "acquired_at") : "?", jstrval(cur, "intent") ? jstrval(cur, "intent") : "");
            return 2;
        }
    }
    char ts[21]; now_iso(ts);
    J *e = cur && cur->t == JOBJ ? cur : jnew(JOBJ);
    jset(e, "holder", jstr(agent)); jset(e, "intent", jstr(intent)); jset(e, "acquired_at", jstr(ts)); jset(e, "ttl_seconds", jnum(ttl));
    jset(jobj_of(l.root, "locks"), target, e);
    scent_set(l.root, agent, intent, SCENT_TTL > ttl ? SCENT_TTL : ttl);
    local_save(&l);
    printf("CLAIMED %s in %s as %s (ttl %lds)\n", target, l.dir, agent, ttl);
    return 0;
}
static int cmd_update(const char *agent, const char *dir, const char *focus, long ttl) {
    Local l = local_open(dir);
    scent_set(l.root, agent, focus, ttl);
    local_save(&l);
    printf("SCENT %s in %s: %s (ttl %lds)\n", agent, l.dir, focus, ttl);
    return 0;
}
static int cmd_whisper(const char *from, const char *dir, const char *to, const char *msg, const char *prio, const char *tf) {
    if (prio && *prio && strcmp(prio, "low") && strcmp(prio, "normal") && strcmp(prio, "high") && strcmp(prio, "critical")) die("priority must be low|normal|high|critical");
    Local l = local_open(dir);
    whisper_add(l.root, from, to, msg, prio, tf);
    local_save(&l);
    printf("WHISPER %s -> %s in %s\n", from, to && strcmp(to, "-") ? to : "(broadcast)", l.dir);
    return 0;
}
static int cmd_close(const char *agent, const char *dir, const char *target, const char *action, const char *msg) {
    static const char *ok[] = { "create", "modify", "delete", "audit", "test", "build", NULL };
    int good = 0; for (int i = 0; ok[i]; i++) if (!strcmp(ok[i], action)) good = 1;
    if (!good) die("action must be create|modify|delete|audit|test|build");
    Local l = local_open(dir);
    J *lk = jget(l.root, "locks"), *cur = lk ? jget(lk, target) : NULL;
    const char *intent = "";
    if (cur) {
        const char *h = jstrval(cur, "holder");
        if (h && strcmp(h, agent)) { printf("REFUSED: %s is held by %s, not %s\n", target, h, agent); return 2; }
        if (jstrval(cur, "intent")) intent = jstrval(cur, "intent");
    }
    history_add(l.root, agent, action, target, intent);
    if (cur) jdel(lk, target);
    if (!has_lock_by(l.root, agent)) { J *sc = jget(l.root, "active_scents"); if (sc) jdel(sc, agent); }
    if (msg && *msg) whisper_add(l.root, agent, NULL, msg, "normal", target);
    local_save(&l);
    printf("CLOSED %s in %s by %s (%s)%s\n", target, l.dir, agent, action, cur ? "" : " [no lock was held]");
    return 0;
}
static void show_local(const char *dir, J *root, const char *agent) {
    J *sc = jget(root, "active_scents"), *lk = jget(root, "locks"), *wh = jget(root, "whispers");
    if (sc && sc->t == JOBJ) for (size_t i = 0; i < sc->n; i++)
        printf("  scent   %-16s %s  [%s, ttl %lds]\n", sc->k[i], jstrval(sc->v[i], "focus") ? jstrval(sc->v[i], "focus") : "", jstrval(sc->v[i], "updated_at") ? jstrval(sc->v[i], "updated_at") : "?", jlong(sc->v[i], "ttl_seconds", SCENT_TTL));
    if (lk && lk->t == JOBJ) for (size_t i = 0; i < lk->n; i++)
        printf("  lock    %-16s held by %s: %s  [%s]\n", lk->k[i], jstrval(lk->v[i], "holder") ? jstrval(lk->v[i], "holder") : "?", jstrval(lk->v[i], "intent") ? jstrval(lk->v[i], "intent") : "", jstrval(lk->v[i], "acquired_at") ? jstrval(lk->v[i], "acquired_at") : "?");
    if (wh && wh->t == JARR) for (size_t i = 0; i < wh->n; i++) {
        const char *to = jstrval(wh->v[i], "to"), *from = jstrval(wh->v[i], "from");
        if (agent && to && strcmp(to, agent)) continue;
        printf("  whisper %s -> %s: %s  [%s%s%s]\n", from ? from : "?", to ? to : "all", jstrval(wh->v[i], "message") ? jstrval(wh->v[i], "message") : "", jstrval(wh->v[i], "timestamp") ? jstrval(wh->v[i], "timestamp") : "?", jstrval(wh->v[i], "priority") ? " " : "", jstrval(wh->v[i], "priority") ? jstrval(wh->v[i], "priority") : "");
    }
    (void)dir;
}
static int cmd_sniff(const char *agent, const char *dir) {   /* SPEC 5.1 */
    char *d = absdir(dir), *cp = pjoin(d, ".crumb");
    char *txt = slurp(cp); J *c = txt ? jparse(txt) : NULL;
    printf("sniff %s as %s\n", d, agent);
    if (c) {
        J *inv = jget(c, "invariants");
        printf("  .crumb: %s | %s\n", jstrval(c, "name") ? jstrval(c, "name") : "?", jstrval(c, "purpose") ? jstrval(c, "purpose") : "(legacy format)");
        if (inv && inv->t == JARR) for (size_t i = 0; i < inv->n; i++) if (inv->v[i]->t == JSTR) printf("  invariant: %s\n", inv->v[i]->s);
    } else printf("  no .crumb here\n");
    Local l = local_open(d);
    show_local(d, l.root, agent);
    return 0;
}

/* ---------- tree walk ---------- */
static int skip_name(const char *n) {
    return n[0] == '.' || !strcmp(n, "target") || !strcmp(n, "node_modules") || !strcmp(n, "build") || !strcmp(n, "dist") || !strcmp(n, "__pycache__");
}
static int is_src(const char *n) {
    static const char *ext[] = { "c", "h", "cc", "cpp", "hpp", "S", "s", "rs", "mojo", "sh", NULL };
    const char *dot = strrchr(n, '.');
    if (!dot || dot == n) return !strcmp(n, "Makefile");
    for (int i = 0; ext[i]; i++) if (!strcmp(dot + 1, ext[i])) return 1;
    return 0;
}
static int cmpp(const void *a, const void *b) { return strcmp(*(char *const *)a, *(char *const *)b); }
static int nested_repo(const char *path) { char *g = pjoin(path, ".git"); struct stat st; int r = lstat(g, &st) == 0; free(g); return r; }

typedef struct Node { char *path, *rel, *name; char **files; size_t nf; struct Node **sub; size_t ns; int src; } Node;
static Node *scan(const char *path, const char *rel, int isroot) {
    Node *n = xmalloc(sizeof *n); memset(n, 0, sizeof *n);
    n->path = xstrdup(path); n->rel = xstrdup(rel); n->name = xstrdup(base_of(path));
    DIR *d = opendir(path);
    if (!d) return n;
    char **names = NULL; size_t cnt = 0, cap = 0; struct dirent *e;
    while ((e = readdir(d))) {
        if (!strcmp(e->d_name, ".") || !strcmp(e->d_name, "..")) continue;
        if (cnt == cap) { cap = cap ? cap * 2 : 32; names = xrealloc(names, cap * sizeof *names); }
        names[cnt++] = xstrdup(e->d_name);
    }
    closedir(d);
    qsort(names, cnt, sizeof *names, cmpp);
    (void)isroot;
    for (size_t i = 0; i < cnt; i++) {
        char *full = pjoin(path, names[i]); struct stat st;
        if (lstat(full, &st) == 0) {
            if (S_ISDIR(st.st_mode)) {
                if (!skip_name(names[i]) && !nested_repo(full)) {
                    char *r = !strcmp(rel, ".") ? xstrdup(names[i]) : pjoin(rel, names[i]);
                    n->sub = xrealloc(n->sub, (n->ns + 1) * sizeof *n->sub);
                    n->sub[n->ns++] = scan(full, r, 0);
                }
            } else if (S_ISREG(st.st_mode) && strcmp(names[i], ".crumb") && strcmp(names[i], ".crumb.local") && names[i][0] != '.') {
                n->files = xrealloc(n->files, (n->nf + 1) * sizeof *n->files);
                n->files[n->nf++] = xstrdup(names[i]);
                if (is_src(names[i])) n->src = 1;
            }
        }
        free(full);
    }
    return n;
}
static int qualifies(const Node *n, int depth) { return depth <= 1 || n->nf > 0; }

static char *run_git(const char *root, const char *args) {
    Buf q = {0}; bstr(&q, "'");
    for (const char *p = root; *p; p++) { if (*p == '\'') bstr(&q, "'\\''"); else bput(&q, p, 1); }
    bstr(&q, "'");
    size_t cn = q.n + strlen(args) + 32; char *cmd = xmalloc(cn);
    snprintf(cmd, cn, "git -C %s %s 2>/dev/null", q.p, args);
    FILE *f = popen(cmd, "r"); if (!f) return xstrdup("");
    char t[512]; size_t n = fread(t, 1, sizeof t - 1, f); t[n] = 0; pclose(f);
    while (n && (t[n - 1] == '\n' || t[n - 1] == '\r')) t[--n] = 0;
    return xstrdup(t);
}

typedef struct { int created, updated, unchanged, legacy, skipped_bad; int dry, verbose; J *git; } Stats;

static void seed_node(const Node *n, int depth, const char *anc_name, const char *anc_path, Stats *st) {
    int q = qualifies(n, depth);
    const char *next_name = anc_name, *next_path = anc_path;
    char *selfname = NULL, *nextpath = NULL;
    if (q) {
        char *cp = pjoin(n->path, ".crumb"), *txt = slurp(cp);
        J *c = txt ? jparse(txt) : NULL;
        const char *state = "unchanged";
        if (txt && (!c || c->t != JOBJ)) { st->skipped_bad++; printf("BAD-JSON %s (left untouched)\n", cp); goto after; }
        if (c && jget(c, "version") && !jget(c, "schema_version")) {   /* pre-RFC Atlas/spark-crumbs format */
            st->legacy++; if (st->verbose) printf("legacy   %s (left untouched)\n", cp); goto after;
        }
        char *before = c ? jdump(c) : xstrdup("");
        int fresh = !c; if (!c) c = jnew(JOBJ);
        char auto_purpose[PATH_MAX + 96];
        if (depth == 0) snprintf(auto_purpose, sizeof auto_purpose, "Repository root %s. Purpose not yet described by a human.", n->name);
        else snprintf(auto_purpose, sizeof auto_purpose, "Directory %s. Purpose not yet described by a human.", n->rel);
        J *oldext = jget(c, "extensions"), *seed = oldext ? jget(oldext, "seed") : NULL;
        const char *prev_auto = seed ? jstrval(seed, "purpose_auto") : NULL;
        if (!jget(c, "schema_version")) jset(c, "schema_version", jstr(SCHEMA));
        if (!jget(c, "name")) jset(c, "name", jstr(depth == 0 ? n->name : n->rel));
        if (!jget(c, "layer")) jset(c, "layer", jstr(depth == 0 ? "root" : n->rel));
        J *ext = NULL;
        const char *pur = jstrval(c, "purpose");
        if (!pur || (prev_auto && !strcmp(pur, prev_auto))) jset(c, "purpose", jstr(auto_purpose));  /* hand-written purpose is never touched */
        if (depth > 0 && !jget(c, "above")) {
            J *a = jnew(JOBJ); jset(a, "name", jstr(anc_name)); jset(a, "path", jstr(anc_path)); jset(c, "above", a);
        }
        if (n->ns) {
            J *b = jarr_of(c, "below");
            for (size_t i = 0; i < n->ns; i++) {
                int have = 0;
                for (size_t k = 0; k < b->n; k++) { const char *nm = b->v[k]->t == JSTR ? b->v[k]->s : jstrval(b->v[k], "name"); if (nm && !strcmp(nm, n->sub[i]->name)) have = 1; }
                if (!have) { J *e = jnew(JOBJ); jset(e, "name", jstr(n->sub[i]->name)); jset(e, "role", jstr("")); jpush(b, e); }
            }
        }
        ext = jobj_of(c, "extensions");
        J *ns = jnew(JOBJ);            /* tool-owned block; everything else in the file is the humans' */
        jset(ns, "purpose_auto", jstr(auto_purpose));
        J *fl = jnew(JARR);
        for (size_t i = 0; i < n->nf && i < 50; i++) jpush(fl, jstr(n->files[i]));
        jset(ns, "files", fl);
        if (depth == 0 && st->git) jset(ns, "git", st->git);
        jset(ext, "seed", ns);
        if (!jget(ext, "owner_lane")) jset(ext, "owner_lane", jstr(""));
        char *after_txt = jdump(c);
        if (fresh) { st->created++; state = "created"; }
        else if (strcmp(before, after_txt)) { st->updated++; state = "updated"; }
        else st->unchanged++;
        if (strcmp(state, "unchanged")) { if (!st->dry) spit(cp, after_txt); if (st->verbose || st->dry) printf("%-8s %s\n", state, cp); }
        else if (st->verbose) printf("%-8s %s\n", state, cp);
    }
after:
    if (q) { selfname = depth == 0 ? n->name : n->rel; next_name = selfname; next_path = ".."; }
    else { nextpath = pjoin(anc_path, ".."); next_path = nextpath; }
    for (size_t i = 0; i < n->ns; i++) seed_node(n->sub[i], depth + 1, next_name, next_path, st);
}
static void ensure_gitignore(const char *root, Stats *st) {
    char *g = pjoin(root, ".gitignore"), *txt = slurp(g);
    if (!nested_repo(root)) return;
    if (txt) { for (char *l = strtok(xstrdup(txt), "\n"); l; l = strtok(NULL, "\n")) if (!strcmp(l, ".crumb.local") || !strcmp(l, "/.crumb.local") || !strcmp(l, "**/.crumb.local")) return; }
    printf("gitignore: adding .crumb.local to %s\n", g);
    if (st->dry) return;
    Buf b = {0}; bstr(&b, txt ? txt : "");
    if (b.n && b.p[b.n - 1] != '\n') bstr(&b, "\n");
    bstr(&b, ".crumb.local\n");
    spit(g, b.p);
}
static int cmd_seed(const char *root, int dry, int verbose) {
    char *r = absdir(root);
    Stats st; memset(&st, 0, sizeof st); st.dry = dry; st.verbose = verbose;
    if (nested_repo(r)) {
        J *g = jnew(JOBJ);
        jset(g, "remote", jstr(run_git(r, "remote get-url origin")));
        jset(g, "branch", jstr(run_git(r, "branch --show-current")));
        jset(g, "head", jstr(run_git(r, "rev-parse --short HEAD")));
        st.git = g;
    }
    Node *tree = scan(r, ".", 1);
    seed_node(tree, 0, tree->name, "..", &st);
    ensure_gitignore(r, &st);
    printf("seed %s%s: created %d, updated %d, unchanged %d, legacy-skipped %d, bad-json %d\n", r, dry ? " (dry run)" : "", st.created, st.updated, st.unchanged, st.legacy, st.skipped_bad);
    return 0;
}
static int cmd_create(const char *dir, const char *name, const char *purpose, const char *layer) {
    char *d = absdir(dir), *cp = pjoin(d, ".crumb");
    struct stat s; if (stat(cp, &s) == 0) { printf("EXISTS %s (use seed to refresh, edit by hand to change fields)\n", cp); return 2; }
    J *c = jnew(JOBJ);
    jset(c, "schema_version", jstr(SCHEMA)); jset(c, "name", jstr(name));
    if (layer && *layer) jset(c, "layer", jstr(layer));
    jset(c, "purpose", jstr(purpose));
    spit(cp, jdump(c));
    printf("CREATED %s\n", cp);
    return 0;
}

typedef struct { int n_crumb, n_local, bad; } Tot;
static void walk_list(const char *path, const char *rel, int depth, int validate, Tot *t) {
    char *cp = pjoin(path, ".crumb"), *lp = pjoin(path, ".crumb.local"), *txt = slurp(cp);
    if (txt) {
        t->n_crumb++;
        J *c = jparse(txt);
        if (validate) {
            if (!c || c->t != JOBJ) { printf("INVALID %s: not a JSON object\n", cp); t->bad++; }
            else if (jget(c, "version") && !jget(c, "schema_version")) printf("LEGACY  %s (pre-RFC format, not validated)\n", cp);
            else {
                const char *sv = jstrval(c, "schema_version");
                if (!sv || strcmp(sv, SCHEMA) || !jstrval(c, "name") || !jstrval(c, "purpose")) { printf("INVALID %s: needs schema_version \"%s\", name, purpose\n", cp, SCHEMA); t->bad++; }
            }
        }
    }
    if (!validate && slurp(lp)) {
        Local l = local_open(path);   /* read side: sweep applied in memory, never saved */
        J *sc = jget(l.root, "active_scents"), *lk = jget(l.root, "locks"), *wh = jget(l.root, "whispers");
        if ((sc && sc->n) || (lk && lk->n) || (wh && wh->n)) { t->n_local++; printf("%s\n", rel); show_local(path, l.root, NULL); }
    }
    DIR *d = opendir(path); if (!d) return;
    char **names = NULL; size_t cnt = 0, cap = 0; struct dirent *e;
    while ((e = readdir(d))) {
        if (e->d_name[0] == '.' || skip_name(e->d_name)) continue;
        if (cnt == cap) { cap = cap ? cap * 2 : 32; names = xrealloc(names, cap * sizeof *names); }
        names[cnt++] = xstrdup(e->d_name);
    }
    closedir(d);
    qsort(names, cnt, sizeof *names, cmpp);
    for (size_t i = 0; i < cnt; i++) {
        char *full = pjoin(path, names[i]); struct stat st;
        if (lstat(full, &st) == 0 && S_ISDIR(st.st_mode) && !nested_repo(full)) {
            char *r = !strcmp(rel, ".") ? xstrdup(names[i]) : pjoin(rel, names[i]);
            walk_list(full, r, depth + 1, validate, t);
        }
    }
}

static long ttl_arg(const char *s, long dflt) { if (!s) return dflt; char *e; long v = strtol(s, &e, 10); if (*e || v < 0) die("bad ttl: %s", s); return v; }
static void usage(void) {
    fputs("usage: crumb <command> ...\n"
          "  seed <root> [-n] [-v]                       write/refresh .crumb files (idempotent; -n dry run)\n"
          "  create <dir> <name> <purpose> [layer]       new .crumb for one directory\n"
          "  claim <agent> <dir> <target> <intent> [ttl] scent + advisory lock (exit 2 if held by another)\n"
          "  update <agent> <dir> <focus> [ttl]          refresh scent\n"
          "  whisper <from> <dir> <to|-> <msg> [prio] [target_file]\n"
          "  close <agent> <dir> <target> [action] [msg] release lock, add history vector, optional whisper\n"
          "  sniff <agent> <dir>                         what to read before touching a directory\n"
          "  list [path]                                 live scents, locks, whispers under path\n"
          "  validate [path]                             check .crumb files against RFC-0001 required fields\n", stderr);
    exit(1);
}
int main(int argc, char **argv) {
    if (argc < 2) usage();
    const char *c = argv[1]; int a = argc - 2; char **v = argv + 2;
    if (!strcmp(c, "seed") && a >= 1) {
        int dry = 0, verb = 0;
        for (int i = 1; i < a; i++) { if (!strcmp(v[i], "-n")) dry = 1; else if (!strcmp(v[i], "-v")) verb = 1; else usage(); }
        return cmd_seed(v[0], dry, verb);
    }
    if (!strcmp(c, "create") && a >= 3) return cmd_create(v[0], v[1], v[2], a > 3 ? v[3] : NULL);
    if (!strcmp(c, "claim") && a >= 4) return cmd_claim(v[0], v[1], v[2], v[3], ttl_arg(a > 4 ? v[4] : NULL, LOCK_TTL));
    if (!strcmp(c, "update") && a >= 3) return cmd_update(v[0], v[1], v[2], ttl_arg(a > 3 ? v[3] : NULL, SCENT_TTL));
    if (!strcmp(c, "whisper") && a >= 4) return cmd_whisper(v[0], v[1], v[2], v[3], a > 4 ? v[4] : NULL, a > 5 ? v[5] : NULL);
    if (!strcmp(c, "close") && a >= 3) return cmd_close(v[0], v[1], v[2], a > 3 ? v[3] : "modify", a > 4 ? v[4] : NULL);
    if (!strcmp(c, "sniff") && a >= 2) return cmd_sniff(v[0], v[1]);
    if (!strcmp(c, "list") || !strcmp(c, "validate")) {
        int val = !strcmp(c, "validate"); Tot t = {0, 0, 0};
        char *r = absdir(a ? v[0] : ".");
        walk_list(r, ".", 0, val, &t);
        printf("%d .crumb file(s), %d directory(ies) with live local crumbs%s\n", t.n_crumb, t.n_local, val && t.bad ? ", INVALID found" : "");
        return t.bad ? 1 : 0;
    }
    usage();
    return 1;
}
