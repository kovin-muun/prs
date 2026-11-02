SIGNAL QUALITY CRITERIA - For findings, assess:
1. Is there a concrete, exploitable vulnerability with a clear attack path?
2. Does this represent a real security risk vs theoretical best practice?
3. Are there specific code locations and reproduction steps?
4. Would this finding be actionable for a security team?

PRECEDENTS -
1. Logging high value secrets in plaintext is a vulnerability. Otherwise, do not report issues around theoretical exposures of secrets. Logging URLs is assumed to be safe. Logging request headers is assumed to be dangerous since they likely contain credentials.
2. UUIDs can be assumed to be unguessable and do not need to be validated. If a vulnerabilities requires guessing a UUID, it is not a valid vulnerability. Numeric IDs are guessable.
3. Audit logs are not a critical security feature and should not be reported as a vulnerability if they are missing or modified.
4. Environment variables and CLI flags are trusted values. Attackers are not able to modify them in a secure environment. Any attack that relies on controlling an environment variable is invalid.
5. Logging non-PII data is not a vulnerability even if the data may be sensitive. Only report logging vulnerabilities if they expose sensitive information such as secrets, passwords, or personally identifiable information (PII).
6. Injecting into log queries is generally not an issue. Only report this if the injection will definitely lead to exposing sensitive data to external users.
7. Integer arithmetic errors (values that wrap, lose precision or change sign) are valid in memory-safe languages.
