# 🏦 KuboBank — Backend Decisions & Cross-Cutting Concerns

> Complemento a ARCHITECTURE.md. Cubre decisiones transversales del backend que aplican a todos los bounded contexts.

---

## 1. 🔴 Concurrencia en `account_balances` — Locking Strategy

### El problema
Dos transacciones concurrentes sobre la misma cuenta y moneda pueden producir un race condition:

```
T1 lee balance USD = 500
T2 lee balance USD = 500
T1 descuenta 200 → escribe 300
T2 descuenta 200 → escribe 300  ← incorrecto, debería ser 100
```

### Decisión: Pessimistic Locking (`SELECT FOR UPDATE`)

En un sistema bancario la consistencia es no negociable. Usamos **Pessimistic Locking** sobre `account_balances`.

Antes de cualquier operación de débito o crédito, MyBatis ejecuta:

```sql
SELECT * FROM account_balances
WHERE account_id = #{accountId}
  AND currency_code = #{currencyCode}
FOR UPDATE;
```

Esto bloquea la fila hasta que la transacción de base de datos se complete o revierta.

**Por qué no Optimistic Locking:**
Optimistic Locking (`version` column + retry) es adecuado para sistemas con baja contención. En un banco, una transacción fallida por conflicto de versión requiere reintentar toda la operación de negocio — incluyendo la consulta FX — lo cual es costoso e impredecible con activos volátiles como BTC.

**Garantía adicional:**
La constraint `CHECK (amount >= 0)` en `account_balances` actúa como última línea de defensa a nivel de base de datos.

---

## 2. ❌ Manejo de Errores — Catálogo de Excepciones

### Estrategia
Un `GlobalExceptionHandler` (`@RestControllerAdvice`) captura todas las excepciones del dominio y las traduce a respuestas HTTP con el esquema `ErrorResponse` definido en el `openapi.yml`.

Toda excepción de dominio extiende `KuboBankException` con un `errorCode` tipificado.

### Catálogo de errores

#### Dominio — `identity`
| Code | HTTP | Descripción |
|---|---|---|
| `CUSTOMER_NOT_FOUND` | 404 | Cliente no existe |
| `CUSTOMER_EMAIL_ALREADY_EXISTS` | 409 | Email duplicado |
| `CUSTOMER_INVALID_STATUS_TRANSITION` | 409 | Transición de estado inválida (ej. activar un cliente ya activo) |

#### Dominio — `account`
| Code | HTTP | Descripción |
|---|---|---|
| `ACCOUNT_NOT_FOUND` | 404 | Cuenta no existe |
| `ACCOUNT_INVALID_STATUS_TRANSITION` | 409 | Transición de estado inválida |
| `ACCOUNT_CURRENCY_NOT_ALLOWED` | 422 | Moneda no permitida en la jurisdicción de la cuenta |
| `ACCOUNT_CURRENCY_INACTIVE` | 422 | Moneda desactivada — cuenta en REVIEW |
| `ACCOUNT_FROZEN` | 422 | Operación rechazada — cuenta congelada |
| `ACCOUNT_CLOSED` | 422 | Operación rechazada — cuenta cerrada |

#### Dominio — `transaction`
| Code | HTTP | Descripción |
|---|---|---|
| `TRANSACTION_NOT_FOUND` | 404 | Transacción no existe |
| `TRANSACTION_DUPLICATE_REFERENCE` | 409 | `reference` ya existe (idempotencia) |
| `TRANSACTION_INSUFFICIENT_FUNDS` | 422 | Saldo insuficiente para débito |
| `TRANSACTION_INVALID_AMOUNT` | 400 | Monto debe ser mayor a cero |
| `TRANSACTION_SAME_CURRENCY_REQUIRED` | 422 | Transferencia mono-moneda con monedas distintas |
| `TRANSACTION_CANNOT_REVERSE` | 409 | Solo se pueden revertir transacciones COMPLETED |
| `TRANSACTION_SELF_TRANSFER` | 422 | Origen y destino son la misma cuenta y moneda |

#### Dominio — `ledger`
| Code | HTTP | Descripción |
|---|---|---|
| `JOURNAL_ENTRY_NOT_FOUND` | 404 | Asiento contable no existe |
| `JOURNAL_ENTRY_UNBALANCED` | 422 | Suma de DEBIT ≠ suma de CREDIT |
| `JOURNAL_ENTRY_INSUFFICIENT_LINES` | 422 | Se requieren al menos 2 líneas |
| `CHART_OF_ACCOUNT_NOT_FOUND` | 404 | Cuenta contable no existe |

#### Infraestructura — `fx`
| Code | HTTP | Descripción |
|---|---|---|
| `FX_RATE_UNAVAILABLE` | 503 | Proveedor externo no disponible |
| `FX_CURRENCY_PAIR_NOT_SUPPORTED` | 422 | Par de monedas sin tasa disponible |

#### Infraestructura — general
| Code | HTTP | Descripción |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Error de validación de entrada (Bean Validation) |
| `UNAUTHORIZED` | 401 | JWT ausente o inválido |
| `FORBIDDEN` | 403 | Rol insuficiente para la operación |
| `RATE_LIMIT_EXCEEDED` | 429 | Límite de requests superado |
| `INTERNAL_ERROR` | 500 | Error inesperado — loggear y no exponer detalle |

### Formato de respuesta de error

Consistente con `ErrorResponse` del `openapi.yml`:

```json
{
  "timestamp": "2025-01-20T10:30:00Z",
  "status": 422,
  "error": "TRANSACTION_INSUFFICIENT_FUNDS",
  "message": "Insufficient USD balance in account SV-00100001. Available: 50.00, Required: 200.00",
  "path": "/api/v1/transactions"
}
```

> **Regla:** Los errores `5xx` nunca exponen stack traces ni detalles internos al cliente. Solo el `errorCode` y un mensaje genérico. El detalle va al log.

---

## 3. ✅ Validación de Entrada

### Estrategia
Bean Validation (`jakarta.validation`) en los DTOs de request. Spring valida automáticamente con `@Valid` en los controllers.

### Reglas por request

#### `RegisterCustomerRequest`
| Campo | Regla |
|---|---|
| `fullName` | `@NotBlank`, max 200 chars |
| `email` | `@NotBlank`, `@Email`, max 254 chars |
| `phoneNumber.countryCode` | `@NotBlank`, pattern `^\+\d{1,4}$` |
| `phoneNumber.number` | `@NotBlank`, pattern `^\d{6,15}$` |

#### `OpenAccountRequest`
| Campo | Regla |
|---|---|
| `customerId` | `@NotNull` |
| `type` | `@NotNull`, must be valid `AccountType` enum |
| `jurisdiction` | `@NotBlank`, exactly 2 chars (ISO 3166-1) |

#### `InitiateTransactionRequest`
| Campo | Regla |
|---|---|
| `amount` | `@NotNull`, `@DecimalMin("0.00000001")` |
| `currencyCode` | `@NotBlank`, max 10 chars |
| `reference` | `@NotBlank`, max 100 chars, pattern `^[A-Z0-9\-]+$` |
| `description` | optional, max 500 chars |
| `targetCurrencyCode` | optional, distinto a `currencyCode` si presente |

#### `CreateManualJournalEntryRequest`
| Campo | Regla |
|---|---|
| `description` | `@NotBlank`, max 500 chars |
| `lines` | `@Size(min=2)`, cada línea con amount > 0 |
| `lines[].accountCode` | `@NotBlank` |
| `lines[].side` | `@NotNull`, DEBIT o CREDIT |
| `lines[].amount` | `@DecimalMin("0.00000001")` |
| `lines[].currencyCode` | `@NotBlank` |

> Validaciones de negocio (fondos suficientes, DEBIT=CREDIT, moneda permitida, etc.) son responsabilidad del **dominio**, no de Bean Validation.

---

## 4. 📋 Logging y Observabilidad

### Formato: Structured JSON Logging
Todos los logs en formato JSON. En desarrollo se puede usar formato legible, en producción siempre JSON.

Dependencia: **Logback** (incluido en Spring Boot) con encoder JSON.

### Campos estándar en cada log entry
| Campo | Descripción |
|---|---|
| `timestamp` | ISO-8601 |
| `level` | INFO, WARN, ERROR |
| `correlationId` | UUID generado por request (ver abajo) |
| `userId` | Auth0 `sub` extraído del JWT (si está autenticado) |
| `userRole` | Rol del usuario: CUSTOMER, OPERATOR, FINANCE, ADMIN |
| `service` | `kubobank-backend` |
| `context` | Bounded context: `identity`, `account`, `transaction`, `ledger`, `fx` |
| `message` | Mensaje legible |
| `exception` | Stack trace solo en ERROR |

### Correlation ID
Cada request HTTP recibe un `X-Correlation-Id` header. Si el cliente lo envía, se reutiliza. Si no, el backend lo genera. Se propaga en todos los logs del request via `MDC` (Mapped Diagnostic Context).

```
Request entra → filtro extrae/genera correlationId → MDC.put("correlationId", id)
→ todos los logs del request incluyen ese correlationId automáticamente
```

### Niveles de log por capa
| Capa | Nivel |
|---|---|
| Domain Events publicados | INFO |
| Transacciones iniciadas/completadas | INFO |
| Asientos contables generados | INFO |
| Errores de validación / negocio (4xx) | WARN |
| Errores inesperados (5xx) | ERROR |
| FX provider calls | INFO (con latencia) |
| SQL queries (MyBatis) | DEBUG (solo en `dev`) |
| JWT validation | DEBUG (solo en `dev`) |

### Plataforma
En MVP: logs a `stdout` (Docker los captura). La plataforma de observabilidad se define en infraestructura — deuda técnica `TD-OBS-001`.

---

## 5. 🚦 Rate Limiting

### Decisión MVP: Spring + Bucket4j (in-memory)
Sin API Gateway en el MVP, el rate limiting vive dentro del backend usando **Bucket4j** — librería de token bucket para Spring.

### Límites por rol

| Rol | Endpoint | Límite | Justificación |
|---|---|---|---|
| `ROLE_CUSTOMER` | `POST /transactions` | 10 req/minuto | Usuario final — previene abuso |
| `ROLE_OPERATOR` | `POST /transactions` | 60 req/minuto | Operador de ventanilla — flujo alto |
| `ROLE_FINANCE` | `POST /ledger/journal-entries` | 20 req/minuto | Ajustes contables — volumen moderado |
| `ROLE_ADMIN` | `PATCH /currencies/*/deactivate` | 5 req/hora | Operación destructiva — throttle severo |
| `ROLE_ADMIN` | `PATCH /transactions/*/reverse` | 10 req/hora | Reversiones — operación crítica |
| Cualquier rol | `GET /**` | 300 req/minuto | Consultas — límite generoso |
| Cualquier rol | `GET /fx/rates` | 30 req/minuto | Protege al proveedor FX externo |

### Respuesta al exceder límite
```
HTTP 429 Too Many Requests
Retry-After: 60
```

Error code: `RATE_LIMIT_EXCEEDED`

### Evolución futura
Migrar a rate limiting en API Gateway (Kong, AWS API Gateway, etc.) cuando se tenga infraestructura dedicada. Deuda técnica `TD-INFRA-001`.

---

## 6. ⚙️ Configuración por Ambiente — Spring Profiles

### Perfiles definidos

| Profile | Uso |
|---|---|
| `dev` | Desarrollo local con Docker Compose |
| `test` | Ejecución de tests (Testcontainers) |
| `prod` | Producción — variables via env vars, sin valores hardcodeados |

### Variables de configuración por perfil

#### Comunes a todos los perfiles
```yaml
spring:
  application:
    name: kubobank-backend
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: ${DB_POOL_SIZE:10}
      minimum-idle: ${DB_POOL_MIN_IDLE:2}
      connection-timeout: 30000
      idle-timeout: 600000

security:
  auth0:
    domain: ${AUTH0_DOMAIN}
    audience: ${AUTH0_AUDIENCE}
    roles-claim: "https://kubobank.sv/roles"

fx:
  provider:
    base-url: ${FX_PROVIDER_URL}
    api-key: ${FX_PROVIDER_API_KEY}

liquibase:
  change-log: classpath:db/changelog/db.changelog-master.yml
```

#### `dev` overrides
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/kubobank_dev
    username: kubobank
    password: kubobank
  logging:
    level:
      sv.com.kubobank: DEBUG
      org.mybatis: DEBUG
      org.springframework.security: DEBUG

security:
  auth0:
    domain: kubobank-dev.us.auth0.com
    audience: https://api.kubobank.sv

fx:
  provider:
    base-url: https://api.coingecko.com/api/v3
```

#### `test` overrides
```yaml
spring:
  datasource:
    url: ${TEST_DB_URL}   # Testcontainers provides dynamically
  liquibase:
    change-log: classpath:db/changelog/db.changelog-master.yml
  logging:
    level:
      sv.com.kubobank: INFO

security:
  auth0:
    disabled: true   # Mock JWT — no real Auth0 calls in tests
```

#### `prod` — solo env vars, sin defaults sensibles
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: ${DB_POOL_SIZE}
  logging:
    level:
      sv.com.kubobank: INFO
      root: WARN
```

### HikariCP — Connection Pool
| Parámetro | Dev | Prod |
|---|---|---|
| `maximum-pool-size` | 5 | 20 (ajustar según carga) |
| `minimum-idle` | 2 | 5 |
| `connection-timeout` | 30s | 30s |
| `idle-timeout` | 10min | 10min |
| `max-lifetime` | 30min | 30min |

---

## 7. 🧪 Estrategia de Testing

### Pirámide de tests

```
        /\
       /  \   E2E (mínimos — solo smoke tests contra Docker Compose)
      /----\
     /      \  Integration Tests (Testcontainers + real PostgreSQL)
    /--------\
   /          \  Unit Tests (dominio puro — sin Spring, sin BD)
  /____________\
```

### Unit Tests — Dominio puro
- Sin Spring, sin base de datos, sin mocks de infraestructura
- Testean invariantes de negocio: `Account`, `Transaction`, `JournalEntry`, Value Objects
- Herramienta: **JUnit 5 + AssertJ**
- Cobertura objetivo: **80%+ en domain layer**

Ejemplos de lo que se testea:
- `Account` no puede abrirse con jurisdicción inválida
- `Transaction` de tipo DEPOSIT no puede tener `originAccountId`
- `Money` con BTC respeta 8 decimales
- `JournalEntry` rechaza si DEBIT ≠ CREDIT
- Balance no puede ser negativo

### Integration Tests — Capa de infraestructura
- Levantan PostgreSQL real vía **Testcontainers**
- Testean MyBatis mappers contra schema real (Liquibase aplicado automáticamente)
- Testean el flujo completo Command → Repository → DB
- Herramienta: **Spring Boot Test + Testcontainers**

### Integration Tests — Seguridad
- Testean que endpoints retornen `401` sin token
- Testean que endpoints retornen `403` con rol incorrecto
- Casos clave: CUSTOMER no puede acceder a `/ledger`, OPERATOR no puede crear asientos manuales, FINANCE no puede revertir transacciones
- Usan JWT mockeados (sin llamar a Auth0 real)
- Herramienta: **Spring Security Test (`@WithMockUser`)**

### Contract Tests — OpenAPI
- Validan que los controllers respondan exactamente el schema definido en `openapi.yml`
- Herramienta: **Spring Cloud Contract** o validación manual con `json-schema-validator`

### Convenciones de naming
```
// Unit test
CustomerTest.kt
TransactionTest.kt
MoneyTest.kt
JournalEntryTest.kt

// Integration test
CustomerMapperIT.kt
AccountRepositoryIT.kt
TransactionFlowIT.kt
LedgerFlowIT.kt

// Security test
SecurityIT.kt
```

---

## 8. 🏥 Health Checks y Actuator

### Endpoints habilitados

| Endpoint | Habilitado | Protegido | Descripción |
|---|---|---|---|
| `/actuator/health` | ✅ | ❌ público | Liveness + Readiness para Docker/K8s |
| `/actuator/health/db` | ✅ | ❌ público | Estado de conexión PostgreSQL |
| `/actuator/info` | ✅ | ❌ público | Versión del servicio, build info |
| `/actuator/metrics` | ✅ | ✅ ADMIN | Métricas JVM y HTTP |
| `/actuator/loggers` | ✅ | ✅ ADMIN | Cambio dinámico de log level |
| `/actuator/env` | ❌ | — | Deshabilitado — expone variables |
| `/actuator/beans` | ❌ | — | Deshabilitado — expone internos |
| `/actuator/httptrace` | ❌ | — | Deshabilitado — expone requests |

### Health check response esperada
```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "diskSpace": { "status": "UP" },
    "fxProvider": { "status": "UP" }
  }
}
```

### Custom health indicator — FX Provider
```json
{
  "fxProvider": {
    "status": "UP",
    "details": { "provider": "CoinGecko", "latencyMs": 120 }
  }
}
```

Si el proveedor FX está `DOWN`, el sistema reporta degradación pero no bloquea — las transacciones mono-currency siguen funcionando.

---

## 🗂 Deuda Técnica Adicional

| ID | Área | Descripción | Prioridad |
|---|---|---|---|
| TD-OBS-001 | Observabilidad | Integrar con plataforma de logs centralizada (Datadog / Grafana Loki / ELK). | Alta |
| TD-INFRA-001 | Rate Limiting | Migrar Bucket4j in-memory a API Gateway cuando haya infraestructura dedicada. | Media |
| TD-TEST-001 | Testing | Implementar tests de contrato OpenAPI con Spring Cloud Contract. | Media |
| TD-PERF-001 | Performance | Evaluar materialización de vistas read-side bajo carga alta. | Baja |

---

*Documento generado en fase de diseño. Actualizar conforme evolucione el MVP.*
