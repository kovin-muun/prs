# Muun Observability Standards

Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f) + codebase patterns.

Validated against codebase:
- [`Trace.java` @ ac4d62e4](https://github.com/muun/muun/blob/ac4d62e47963f6040d4b5ac7cf5ffc5cfd4e3976/service/src/main/java/io/muun/service/observability/Trace.java)
- [`ConfirmInterceptResolutionAction.java` @ 232c7bd4](https://github.com/muun/muun/blob/232c7bd4e2f07d4f185ae4c7e1d25171ce07a422/forwarder/src/main/java/io/muun/forwarder/domain/action/incoming/ConfirmInterceptResolutionAction.java)
- [`IncomingHtlcRepository.java` @ 128bb904](https://github.com/muun/muun/blob/128bb904652eeb29a43c52bbd6b220b08cdf72ac/forwarder/src/main/java/io/muun/forwarder/data/repository/IncomingHtlcRepository.java)

## Philosophy
Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), section "Our production mindset"
Relevant quote (Our practices): "We learn most in production, so we need Observability. It's about having the right tools to ask questions regarding the behaviour of users and the state of our systems. This requires observability to be baked into everything we ship as a first-class concern."

Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f)
Relevant quote (On observability): "We also try our best to make our systems observable: that is, making it easy to understand any state it might find itself in, no matter how bizarre or corner-case-y it may be, without having to deploy new code."
Relevant quote (On observability — Grafana section): "The rule of thumb is that everything infra related may be queried from grafana & stored in prometheus, but all business-logic related should be sent and queried from honeycomb."

- Observability is a first-class concern — baked into everything shipped
- Observable = can understand any system state by interrogating externally, without deploying new code
- Prefer traces (Honeycomb) over metrics (Grafana/Prometheus) over logs (Kibana)
- Business logic → Honeycomb. Infrastructure → Grafana/Prometheus

## Stack
Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), section "Tools — Honeycomb, Grafana, and Kibana"
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), sections "Honeycomb", "Grafana", "Logs"

- **Honeycomb**: Primary. Distributed tracing with wide events. First pick for all services
- **Grafana + Prometheus**: Infrastructure metrics (k8s, RDS, nodes). Rule: infra in Grafana, business logic in Honeycomb
- **Kibana**: Last-resort log search. Auto-collects stdout from k8s. Used for third-party services (lnd, bitcoind) that don't emit traces
- **Sentry**: Error tracking. warn/error logs automatically generate Sentry entries (quota limited — use sparingly)

## Honeycomb Traces

### Concepts
- **Trace**: complete unit of work story. **Span**: single piece within a trace. **Tag**: key-value metadata on a span
- Spans have: serviceName, name, timestamp, duration, ID, traceID, parentID, tags

### Instrumenting Code
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), section "Instrumenting your code"

- `Trace.getCurrent()` — get current trace anywhere
- `.child(spanName)` — attach child span, then `.runAndFinish(lambda)` to trace execution
- `@WithSpan` — annotation alternative to manual child (span named `ClassName#methodName`)
- `@SpanAttributeSize` — annotate params to tag their size
- `.addTag(tagName, tagValue)` — add queryable key-value pair

### Naming Conventions
Source: Notion ["Muun-specific best practices"](https://www.notion.so/5e0f40684a304dc097298433b5a8917f), section "Honeycomb"
Relevant quote: "Tags should be named `<project name>:<tag name>` using snake_case for the tag name (respect the case for the project, i.e. `fee-estimator` should be written `fee-estimator` and not `fee_estimator`). Child traces are named with camelCase. Async actions created with JobRunner should also go with camelCase. Periodic action names are traced at Honeycomb by their name. These should be in camelCase as well."

- Tags: `<project>:<tag_name>` with snake_case for tag name, project name keeps original case
  - `mempool:tx_fees_cache_hits` (correct)
  - `mempool:tx-fees-cache-hits` (wrong — hyphens in tag name)
  - `tx_fees_cache_hits` (wrong — missing project prefix)
- Child spans: camelCase (`childSpanName`)
- Async actions (JobRunner): camelCase (`asyncActionRunner`)
- Periodic action names: camelCase (`periodicActionName`)

### Automatic Instrumentation (no code needed)
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), section "Automatic instrumentation"

- SQL queries (Hibernate) — use `.setComment("ClassName#methodName")` on NativeQuery for readable span names
- HTTP clients (BaseInternalClient / BaseExternalClient)
- JSON-RPC clients (bitcoind, electrum) — spans follow `ClientName#endpointName`
- DB locks
- Async jobs
- Tests (CI runs)

### Quota & Limits
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), section "Usage quotas and size limits"
Relevant quote: "We have a monthly quota of 1.5B events. ... Keep in mind that traces from local environments also contribute towards the 1.5B monthly quota!"
Relevant quote: "Honeycomb keeps an undocumented but very real hard limit of 10k possible tag names per dataset. In particular, this implies that generating tag names programmatically is something we should avoid. ... In most cases, the existence of programmatic tag names is due to some parametric value(s) we want to store (e.g. we want something like `foo_updated_by_bar` where both `foo` and `bar` may vary). In those cases we can avoid the variability in the tag names by keeping the variables as values instead."

- Monthly quota: 1.5B events. Be mindful of span creation frequency
- 60-day history retention (query results stored longer)
- Max 10k unique tag names per dataset — NEVER generate tag names programmatically
  - Bad: `foo_updated_by_bar` with dynamic foo/bar
  - Good: separate `updated_object` and `updated_by` tags with values
- Max 2k tag names per single event
- Max event size: 100 KB
- Local env traces count toward quota

### Sampling
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), section "Usage quotas and size limits"
Validated against codebase: [`helm/conf/prd/refinery.yml` @ 79eac001](https://github.com/muun/muun/blob/79eac001b4245f07052a48cda75fd9fd429a36eb/helm/conf/prd/refinery.yml)

Traces go through two sampling tiers before reaching Honeycomb:

1. **In-code sampling lambda** — each periodic action registers a lambda `(index, lastFailed) -> boolean` that decides whether a given invocation produces a trace at all. A common pattern is `(index, lastFailed) -> (index % 100 == 0) || lastFailed`.
2. **Refinery (post-hoc sampling)** — a Honeycomb proxy that applies rules-based sampling to traces before they are sent to Honeycomb. Production rules live in `helm/conf/prd/refinery.yml`. Refinery can keep, sample, or drop spans based on service name, duration, error status, or custom tags.

Critical or high-frequency actions sometimes intentionally use `-> true` (always trace) and rely on Refinery rules to manage quota. For example, the syncer's blockchain syncer and syncer's payment notifier both trace every invocation — Refinery keeps only long, failed, or otherwise interesting spans and aggressively samples the rest.

Before flagging an always-trace lambda as a quota concern, check whether Refinery rules already cover that service and action name.

### Logging
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), section "Logs"
Relevant quote: "Keep in mind that any logs with severity level `warn` or `error` also generate error entries in Sentry. Given that we have error tracing quotas there we should use these sparingly, only for things that should happen infrequently enough."

- SLF4J + Logback, @Slf4j annotation
- warn/error logs generate Sentry entries (quota!) — use sparingly
- Config files: `/$SERVICE/config/logback/remote-prod.xml` (prod), `src/main/resources/logback-local.xml` (local)

### Slack Alerts
Source: Notion ["On observability"](https://www.notion.so/3c4232a3d1f0478db481e5480843a10f), section "Slack alerts" (Honeycomb trigger configuration)
Source (channel descriptions): Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), section "Slack"

- Honeycomb triggers configurable for Slack alerts
- `#prd_alerts`: uptime-critical, low noise, communicate via threads
- `#prd_events`: noisy stream of repeated errors, check periodically

## What Reviewers Check
- Is new code instrumented with traces?
- Do new periodic actions have appropriate sampling (in-code lambda, Refinery rules, or both)?
- Are tags following naming conventions (project:snake_case)?
- Are SQL queries using `.setComment()` for Honeycomb visibility?
- Are warn/error logs used only for truly exceptional cases?
- Could tag names be generated programmatically? (flag this)
- Is the new code safe for the Honeycomb event quota?
