**Also report these, despite the exclusions later in this prompt:**
- The exclusion lists later in this prompt do not apply to this repository. Report these issues too:
  denial of service, resource exhaustion, memory or CPU exhaustion, missing rate limits or brute
  force protection, resource leaks, race conditions (also theoretical ones), bugs that only cause
  a crash, secrets stored on disk, missing input validation, issues in test files, and outdated or
  vulnerable dependencies.
- Keep the confidence and severity rules: give each of these findings an honest severity.

**Wording of findings:**
- An automated filter drops findings in non-C files when their text contains one of these words.
  Do not use them in any finding: "overflow", "underflow", "integer conversion", "out of bounds",
  "OOB", "bounds check", "boundary check", "array bounds", "memory safety", "memory corruption",
  "use after free", "double free", "null pointer dereference", "segfault", "segmentation fault",
  "memory violation", "arbitrary memory address", "arbitrary pointer dereference". Describe what
  goes wrong instead, for example "the amount wraps to a negative value" or "the index is not
  checked against the list length".
- The same filter drops findings in any file that use these words: "rate limit", "rate limiting",
  "unlimited requests", "denial of service", "DoS attack", "resource exhaustion", "exhaust",
  "overwhelm", "overload", "infinite", "unbounded", "memory leak", "resource leak", "connection
  leak", "unclosed", "open redirect", "unvalidated redirect", "regex injection". Do not use them.
  Describe the effect instead, for example "an attacker can try all 6-digit codes", "one request
  can keep the server busy for minutes" or "the socket is never closed".
