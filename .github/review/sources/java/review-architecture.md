# Muun Backend Architecture & Patterns

Source: Codebase exploration + Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f) + PR patterns.

Validated against codebase:
- [`SwapperApplication.java` @ 237c5808](https://github.com/muun/muun/blob/237c5808095b1a0fa0c67a2af79052ea41f5e3ad/swapper/src/main/java/io/muun/swapper/app/SwapperApplication.java)
- [`IncomingHtlcRepository.java` @ 128bb904](https://github.com/muun/muun/blob/128bb904652eeb29a43c52bbd6b220b08cdf72ac/forwarder/src/main/java/io/muun/forwarder/data/repository/IncomingHtlcRepository.java)
- [`TrackInFlightLightningPaymentAction.java` @ 172266b4](https://github.com/muun/muun/blob/172266b4b7b5e8914e328910c3da432f77b0d201/swapper/src/main/java/io/muun/swapper/domain/action/lightning_payment/TrackInFlightLightningPaymentAction.java)

## Stack
Source: codebase pattern
Validated against codebase: [`swapper/build.gradle` @ e284786a](https://github.com/muun/muun/blob/e284786a5a4a7154a4cb6b593d786cbfb54f7070/swapper/build.gradle), [`BaseApplication.java` @ 0ab4191c](https://github.com/muun/muun/blob/0ab4191c0be310d312d6c571316942aa85e11943/service/src/main/java/io/muun/service/BaseApplication.java)

- **Framework**: Dropwizard 1.3.17 (Jersey REST, Jetty server)
- **DI**: Dagger 2 (compile-time)
- **Database**: PostgreSQL + Hibernate 5.4.x + Liquibase migrations
- **Build**: Gradle 8.x, Java 17
- **Code gen**: Lombok (getters/setters/etc.), Dagger compiler
- **Testing**: JUnit 4 + Mockito 3.8 + AssertJ
- **Observability**: OpenTelemetry + Honeycomb, Prometheus, Sentry
- **HTTP clients**: Retrofit 2 + OkHttp

## Monorepo Structure
Source: codebase pattern
Validated against codebase: [`settings.gradle` @ bc35ed3f](https://github.com/muun/muun/blob/bc35ed3f4b645970ed8d851ea1c1502d54b4c053/settings.gradle)

- Single Git repo with 20+ Java services and shared libraries
- Package convention: `io.muun.{service}.{layer}.{domain}`
- Key services: houston, swapper, syncer, funder, beam, prover, forwarder, mempool, risk-analyzer, etc.

## Clean Architecture Layers
Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), section "Clean Architecture"
Relevant quote: "Our mobile apps and Java microservices follow the clean architecture pattern, and usually have three layers: Data: handles the data backends, such as the database, the operating system, or the network. Domain: contains the models and business logic (use cases in clean architecture lingo). Presentation: contains the UI code or public API endpoints."

Every service follows three layers:
- **Data**: database repositories, external service clients, caches
- **Domain**: models (JPA entities), actions (business logic), exceptions
- **Presentation**: REST resources (*Resource.java), API mappers

## Shared Libraries
Source: codebase pattern
Validated against codebase: [`settings.gradle` @ bc35ed3f](https://github.com/muun/muun/blob/bc35ed3f4b645970ed8d851ea1c1502d54b4c053/settings.gradle), [`service/src/main/java/io/muun/service/`](https://github.com/muun/muun/tree/master/service/src/main/java/io/muun/service/)

- `service`: BaseApplication, BaseRepository, exception mappers, DB utilities, tracing, jobs framework, rate limiting, idempotency
- `common`: cross-platform DTOs, validation, crypto utilities, common exceptions
- `clients`: bitcoind JSON-RPC client, c-lightning client, forwarder client, service-to-service communication
- `backend-libs/bitcoin`: Bitcoin-specific utilities
- `backend-libs/taproot4j`: Taproot crypto Java wrapper

## Key Patterns

### Application Bootstrap
Source: codebase pattern
Validated against codebase: [`SwapperApplication.java` @ 237c5808](https://github.com/muun/muun/blob/237c5808095b1a0fa0c67a2af79052ea41f5e3ad/swapper/src/main/java/io/muun/swapper/app/SwapperApplication.java)

```java
@Singleton @Slf4j
public class HoustonApplication extends BaseApplication<HoustonConfiguration, JobVariants> {
    @Inject SessionResource sessionResource;
    // ... injected resources and actions

    @Override
    protected void run() throws Exception {
        final HoustonComponent component = DaggerHoustonComponent.builder()
                .serviceModule(getServiceModule())
                .houstonModule(new HoustonModule(configuration))
                .build();
        component.inject(this);
        registerResource(sessionResource);
        registerPeriodicAction("healthChecker", ..., Duration.ofMinutes(1), ...);
    }
}
```

### Action Pattern (Domain Logic)
Source: codebase pattern
Validated against codebase: [`SubscribeToInFlightPaymentsAction.java` @ e02188be](https://github.com/muun/muun/blob/e02188befe27776e80e7ffeaa0e083e2499fd02d/forwarder/src/main/java/io/muun/forwarder/domain/action/outgoing/SubscribeToInFlightPaymentsAction.java)

```java
@Singleton
public class UpdateOperationMetadataAction {
    private final OperationRepository operationRepository;

    @Inject
    public UpdateOperationMetadataAction(OperationRepository operationRepository) {
        this.operationRepository = operationRepository;
    }

    public void run(Operation operation, String receiverMetadata) {
        Preconditions.checkArgument(operation.isIncomingSwap());
        Preconditions.checkNotNull(receiverMetadata);
        operation.setReceiverMetadata(receiverMetadata);
        operationRepository.save(operation);
    }
}
```

### Repository Pattern
Source: codebase pattern
Validated against codebase: [`IncomingHtlcRepository.java` @ 128bb904](https://github.com/muun/muun/blob/128bb904652eeb29a43c52bbd6b220b08cdf72ac/forwarder/src/main/java/io/muun/forwarder/data/repository/IncomingHtlcRepository.java)

Repositories use native SQL queries (not Hibernate Criteria API, which is deprecated).
```java
@Singleton
@Slf4j
public class SwapRepository extends BaseRepository<Swap> {
    @Inject
    public SwapRepository(SessionFactory sessionFactory) {
        super(sessionFactory);
    }

    public Optional<Swap> fetchByFundingAddress(String address) {
        // language=sql
        final var sql = """
                SELECT swaps.*
                FROM swaps
                JOIN funding_outputs ON funding_outputs.id = swaps."fundingOutput"
                WHERE funding_outputs."outputAddress" = :address
                """;

        final var query = currentSession().createNativeQuery(sql, Swap.class)
                .setComment("SwapRepository#fetchByFundingAddress")
                .addSynchronizedEntityClass(Swap.class)
                .addSynchronizedEntityClass(FundingOutput.class)
                .setParameter("address", address);

        return extractOptionalSingleResult(query, Swap.class);
    }
}
```
Key elements:
- `// language=sql` comment for IDE SQL highlighting
- `.setComment("ClassName#methodName")` for Honeycomb tracing
- `.addSynchronizedEntityClass()` for all joined tables (Hibernate cache sync)
- Named parameters with `:name` syntax
- Use `extractOptionalSingleResult()` or `extractFirstEntityList()` helpers from BaseRepository

### Entity Pattern
Source: codebase pattern
Validated against codebase: [`User.java` @ b1b3f1a8](https://github.com/muun/muun/blob/b1b3f1a8d888a53e8504bfd5072f5e065593b46a/houston/src/main/java/io/muun/houston/domain/model/User.java)

One annotation per line, always.
```java
@Entity(name = "users")
@Table(name = "users")
@EqualsAndHashCode(of = "uuid")
@NoArgsConstructor
@Slf4j
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private Long id;

    @Getter
    private String uuid;

    @OneToOne(fetch = FetchType.LAZY, mappedBy = "user")
    @Getter
    @Setter
    @Nullable
    private PhoneNumber phoneNumber;
}
```

### Error Handling
Source: codebase pattern
Validated against codebase: [`BaseExceptionMapper.java` @ c38e9c02](https://github.com/muun/muun/blob/c38e9c02998fc18392ed8625e10bbc3916c4541f/service/src/main/java/io/muun/service/errors/BaseExceptionMapper.java)

- BaseExceptionMapper hierarchy converts exceptions to JSON responses
- Tags errors with trace info (Sentry integration)
- CLIENT_FAILURE → warn log, SERVER_FAILURE → error log (ignored errors → debug)
- Use proper ApiException with ErrorCode, not RuntimeException

## Design Principles
Source: Notion ["Our practices"](https://www.notion.so/b125a87b52de4906bd6f99670e3e635f), sections "Our platform" and "Code Style"
Relevant quote: "We use postgres as our storage layer. ... Whenever we need to store something, we first reach out for it. ... Adding new storage layers means using a new innovation token. ... One of our defaults is to use postgres until it hurts."
Relevant quote: "We approach code writing having very present that other humans will need to read it, understand it and/or maintain it. For that reason, we optimize for simplicity, maintainability, and code review-ability. We intentionally leave out very desirable code characteristics which are reusability and flexibility. ... we do not actively optimize for them. Instead, we let them organically surface where and when they are needed."
Relevant quote: "Our domain eats up all our mental load for complexity. Our domain eats up all our innovation tokens."

- "Use postgres until it hurts" — postgres is the default storage, adding new storage is an innovation token
- Optimize for simplicity and maintainability, NOT reusability and flexibility
- Let reusability surface organically where needed
- Sane defaults for common dev needs — platform handles the boring stuff
- "Our domain eats up all our innovation tokens" — keep infrastructure boring

## What Reviewers Check
- Is clean architecture respected (layers, dependencies flow inward)?
- Are models in the domain layer?
- Do new actions and repositories use @Inject constructor injection?
- Do new repositories extend BaseRepository, use native SQL queries (not Criteria API), and include .setComment()?
- Are existing shared libraries used (not reinvented)?
- Is the solution as simple as it can be?
- Would another developer understand this code easily?
- Is proper exception handling used (ApiException with ErrorCode, not RuntimeException)?
- Is @Nullable annotated with explanatory comments?
- Are Optional returns preferred over nullable returns?
