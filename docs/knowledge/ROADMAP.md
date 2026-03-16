# 🗺️ Kubo Bank — Roadmap Backend

> Roadmap optimizado para **un desarrollador individual**.
> Basado en la arquitectura documentada en `ARCHITECTURE.md` y `BACKEND_DECISIONS.md`.
> Los tiempos asumen jornadas de **6 horas productivas/día** (descuenta reuniones, context-switching, imprevistos).

---

## ⏱️ Supuestos de estimación

| Supuesto | Valor |
|---|---|
| Horas productivas por día | 6h |
| Días de trabajo por semana | 5 días |
| Factor de incertidumbre aplicado | +25% sobre estimación base |
| Perfil del dev | Senior con experiencia en Spring Boot y Kotlin. Primer contacto con MyBatis y Spring Modulith. |

> Las semanas son **semanas de trabajo**, no semanas calendario. Los fines de semana no están incluidos.

---

## 📍 Vista General de Milestones

```
M0  Fundaciones         ████░░░░░░░░░░░░░░░░░░░░  Semana 1-2
M1  Shared + Identity   ████████░░░░░░░░░░░░░░░░  Semana 3-4
M2  Account             ████████████░░░░░░░░░░░░  Semana 5-6
M3  Transaction         ████████████████░░░░░░░░  Semana 7-9
M4  Ledger              ████████████████████░░░░  Semana 10-12
M5  FX + Cross-currency ██████████████████████░░  Semana 13-14
M6  Seguridad + Hardening████████████████████████ Semana 15-16
M7  MVP Completo        ─────────────────────────  Semana 17 ✅
```

**Total estimado: ~16-17 semanas (~4 meses)**

---

## M0 — Fundaciones del Proyecto
**Duración estimada: 2 semanas**
**Objetivo: Proyecto arranca, compila, conecta a BD y Liquibase corre las migraciones.**

### Semana 1 — Scaffold del monorepo

| Tarea | Horas | Descripción |
|---|---|---|
| Gradle multi-project setup | 4h | `settings.gradle.kts`, módulos vacíos, `build.gradle.kts` raíz con version catalog |
| `apps/api-gateway` base | 3h | `SpringBootApplication`, `application.yml`, profiles `dev`/`test`/`prod` |
| `libs/shared` base | 3h | `KuboBankException`, `ErrorResponse`, `DomainEvent` |
| Docker Compose | 2h | PostgreSQL + pgAdmin, variables de entorno, volumen persistente |
| GitHub Actions CI básico | 3h | `./gradlew build` en push, Kotlin linting |
| `libs/infra/persistence` base | 3h | MyBatis config, HikariCP, Liquibase wired up |

**Total semana 1: ~18h (~3 días)**

### Semana 2 — Schema y configuración base

| Tarea | Horas | Descripción |
|---|---|---|
| Liquibase changelog master | 2h | `db.changelog-master.yml` referenciando los 9 scripts |
| Migraciones SQL (001-003) | 3h | `currencies`, `jurisdictions`, `jurisdiction_currencies` |
| Seed data (shared) | 2h | USD, SVC, BTC, jurisdicciones SV/GT/HN |
| `GlobalExceptionHandler` | 3h | `@RestControllerAdvice`, catálogo de errores, formato `ErrorResponse` |
| Correlation ID filter | 2h | `X-Correlation-Id` header, MDC propagation |
| Structured logging setup | 2h | Logback JSON encoder, campos estándar |
| Health checks + Actuator | 2h | Endpoints habilitados/deshabilitados según decisión |

**Total semana 2: ~16h (~2.5 días)**

### ✅ Criterio de salida M0
- `./gradlew bootRun` levanta sin errores
- Liquibase aplica las 3 primeras migraciones automáticamente
- `GET /actuator/health` responde `UP`
- Logs en JSON con `correlationId`

---

## M1 — `libs/shared` + `libs/domains/identity`
**Duración estimada: 2 semanas**
**Objetivo: CRUD completo de clientes con tests. Primer endpoint funcional con JWT.**

### Semana 3 — Value Objects y dominio identity

| Tarea | Horas | Descripción |
|---|---|---|
| Value Objects en `libs/shared` | 4h | `Currency`, `CurrencyType`, `Jurisdiction`, `Money` con precisión dinámica |
| `Customer` aggregate | 4h | Entidad, `CustomerStatus`, invariantes de dominio |
| `Email` + `PhoneNumber` VOs | 2h | Validación interna en constructor |
| Domain Events identity | 2h | `CustomerRegistered`, `CustomerActivated`, `CustomerSuspended` |
| Unit tests dominio identity | 4h | `CustomerTest.kt` — transiciones de estado, validaciones |

**Total semana 3: ~16h (~2.5 días)**

### Semana 4 — Infraestructura identity + Auth0 + API

| Tarea | Horas | Descripción |
|---|---|---|
| Migración 004 — customers | 2h | SQL + Liquibase |
| `CustomerMapper.kt` + XML | 4h | MyBatis mapper, queries CRUD + paginación |
| `libs/infra/auth0` | 4h | `JwtAuthFilter`, validación JWKS, `Auth0RoleExtractor` |
| `RegisterCustomerCommand` + `CustomerQueryService` | 3h | Application layer, Bean Validation |
| `CustomerController` | 3h | POST, GET, PATCH activate/suspend — con `@Valid` |
| Integration tests | 4h | `CustomerMapperIT.kt` con Testcontainers |

**Total semana 4: ~20h (~3.5 días)**

### ✅ Criterio de salida M1
- `POST /api/v1/customers` crea un cliente
- `GET /api/v1/customers/{id}` retorna 401 sin JWT, 403 con rol incorrecto
- `PATCH /activate` y `PATCH /suspend` cambian estado correctamente
- Tests unitarios + de integración pasan en CI

---

## M2 — `libs/domains/account`
**Duración estimada: 2 semanas**
**Objetivo: Cuentas multi-moneda abiertas, consultadas y sus saldos visibles.**

### Semana 5 — Dominio account

| Tarea | Horas | Descripción |
|---|---|---|
| `Account` aggregate | 4h | Multi-currency, `AccountStatus` con `REVIEW`, invariantes |
| `Balance` entity | 3h | Par account/currency, `amount >= 0` |
| `AccountNumber` VO | 2h | Generación de número interno |
| Domain Events account | 2h | `AccountOpened`, `AccountFrozen`, `AccountClosed`, `AccountUnderReview`, `BalanceUpdated` |
| Unit tests account | 4h | `AccountTest.kt` — apertura, congelación, cierre, REVIEW |

**Total semana 5: ~15h (~2.5 días)**

### Semana 6 — Persistencia + API account

| Tarea | Horas | Descripción |
|---|---|---|
| Migraciones 005-006 | 3h | `accounts` + `account_balances` |
| `AccountMapper.kt` + XML | 4h | CRUD, paginación, query por customer, `SELECT FOR UPDATE` en balances |
| `account_balance_view` | 2h | Vista read-side en migración |
| `OpenAccountCommand` + `AccountQueryService` | 3h | Application layer |
| `AccountController` | 3h | POST, GET, balances, freeze, close |
| Integration tests | 4h | `AccountRepositoryIT.kt`, `AccountMapperIT.kt` |

**Total semana 6: ~19h (~3 días)**

### ✅ Criterio de salida M2
- Una cuenta puede abrirse con jurisdicción SV y acepta USD/SVC/BTC
- `GET /accounts/{id}/balances` retorna saldos correctos
- `PATCH /freeze` y `PATCH /close` funcionan con reglas de estado
- Pessimistic locking probado en test de concurrencia básico

---

## M3 — `libs/domains/transaction`
**Duración estimada: 3 semanas**
**Objetivo: DEPOSIT, WITHDRAWAL y TRANSFER mono-currency funcionando con idempotencia.**

> Este es el milestone más complejo del MVP. Implica orquestar identity + account + ledger + fx.

### Semana 7 — Dominio transaction

| Tarea | Horas | Descripción |
|---|---|---|
| `Transaction` aggregate | 5h | Todos los campos, invariantes por tipo (DEPOSIT/WITHDRAWAL/TRANSFER) |
| `TransactionType` + `TransactionStatus` enums | 1h | |
| Domain Events transaction | 2h | `TransactionInitiated`, `TransactionCompleted`, `TransactionFailed`, `TransactionReversed` |
| Reglas de negocio dominio | 4h | Idempotencia, `originAccountId` null para DEPOSIT, etc. |
| Unit tests transaction | 5h | `TransactionTest.kt` — todas las combinaciones válidas e inválidas |

**Total semana 7: ~17h (~3 días)**

### Semana 8 — Persistencia + flujo DEPOSIT/WITHDRAWAL

| Tarea | Horas | Descripción |
|---|---|---|
| Migración 009 — transactions | 3h | SQL completo con todas las constraints |
| `TransactionMapper.kt` + XML | 5h | Insert, queries, filtros por accountId/status/currency/createdBy |
| `transaction_history_view` | 2h | Vista read-side |
| `InitiateTransactionCommand` — DEPOSIT | 4h | Flujo completo: validar cuenta, lock, acreditar balance, persistir |
| `InitiateTransactionCommand` — WITHDRAWAL | 3h | Validar fondos suficientes, debitar |
| Spring Modulith Outbox | 3h | `event_publication` table, publicación de `TransactionCompleted` |

**Total semana 8: ~20h (~3.5 días)**

### Semana 9 — TRANSFER + reversal + API

| Tarea | Horas | Descripción |
|---|---|---|
| `InitiateTransactionCommand` — TRANSFER | 4h | Debitar origen, acreditar destino, atómico |
| Idempotencia end-to-end | 3h | Duplicate `reference` retorna 409 sin crear duplicado |
| `PATCH /transactions/{id}/reverse` | 3h | Solo ADMIN, solo COMPLETED, invierte balances |
| `TransactionController` | 3h | POST, GET, filtros, reverse |
| Rate limiting con Bucket4j | 3h | Por rol según tabla documentada |
| Integration tests `TransactionFlowIT.kt` | 5h | Deposit, withdrawal, transfer, idempotencia, fondos insuficientes |

**Total semana 9: ~21h (~3.5 días)**

### ✅ Criterio de salida M3
- DEPOSIT/WITHDRAWAL/TRANSFER mono-currency funcionan end-to-end
- Idempotencia: mismo `reference` retorna 409 sin duplicar
- `created_by` se extrae del JWT y persiste correctamente
- Reversión de transacciones funciona y respeta permisos
- Outbox events se publican en `event_publication`

---

## M4 — `libs/domains/ledger`
**Duración estimada: 3 semanas**
**Objetivo: Cada transacción COMPLETED genera su JournalEntry de partida doble automáticamente.**

### Semana 10 — Dominio ledger

| Tarea | Horas | Descripción |
|---|---|---|
| `ChartOfAccount` entity | 2h | Plan de cuentas, categorías |
| `JournalEntry` aggregate | 4h | Cabecera, tipo AUTOMATIC/MANUAL |
| `JournalEntryLine` entity | 3h | DEBIT/CREDIT, validación DEBIT=CREDIT |
| Invariante de integridad contable | 3h | Dominio rechaza si suma no cuadra |
| Domain Events ledger | 1h | `JournalEntryCreated`, `JournalEntryReversed` |
| Unit tests `JournalEntryTest.kt` | 4h | Balanceo, mínimo 2 líneas, tipos de asiento |

**Total semana 10: ~17h (~3 días)**

### Semana 11 — Persistencia + asientos automáticos

| Tarea | Horas | Descripción |
|---|---|---|
| Migraciones 007-008 | 4h | `chart_of_accounts` + `journal_entries` + `journal_entry_lines` |
| Seed data plan de cuentas | 2h | 11 cuentas del plan de cuentas MVP |
| `JournalEntryMapper.kt` + XML | 4h | Insert cabecera + líneas, queries con filtros |
| `AutomaticJournalEntryService` | 5h | Genera asiento correcto por cada tipo de TX: DEPOSIT, WITHDRAWAL, TRANSFER mono, REVERSAL |
| Link `transaction.journal_entry_id` | 2h | Atómico con la TX — misma transacción de BD |

**Total semana 11: ~17h (~3 días)**

### Semana 12 — Asientos manuales + API ledger

| Tarea | Horas | Descripción |
|---|---|---|
| `ManualJournalEntryService` | 4h | Solo FINANCE/ADMIN, validación DEBIT=CREDIT |
| `LedgerController` | 3h | GET chart-of-accounts, GET journal-entries, POST manual, GET by ID |
| Autorización por rol en ledger | 2h | FINANCE y ADMIN para escritura, OPERATOR para plan de cuentas |
| Integration tests `LedgerFlowIT.kt` | 5h | Asiento automático al completar TX, manual correcto/incorrecto |
| Security tests ledger | 3h | CUSTOMER no accede, OPERATOR no crea asientos |

**Total semana 12: ~17h (~3 días)**

### ✅ Criterio de salida M4
- Cada DEPOSIT/WITHDRAWAL/TRANSFER COMPLETED tiene su `journal_entry_id`
- Suma DEBIT = suma CREDIT en todos los asientos
- Asiento manual con DEBIT ≠ CREDIT retorna 422
- `GET /ledger/journal-entries` retorna historial con líneas
- Acceso denegado correctamente por rol

---

## M5 — `libs/domains/fx` + Cross-Currency
**Duración estimada: 2 semanas**
**Objetivo: TRANSFER cross-currency USD→BTC y BTC→USD funcionando con snapshot de tasa.**

### Semana 13 — Puerto FX + adaptador

| Tarea | Horas | Descripción |
|---|---|---|
| `ExchangeRatePort` interfaz | 1h | Puerto puro en `libs/domains/fx` |
| `ExchangeRate` value object | 2h | from, to, rate, fetchedAt |
| `ExchangeRateService` application | 2h | Orquesta el puerto |
| `CoinGeckoExchangeRateAdapter` | 5h | HTTP client, parsing, manejo de errores, fallback |
| Custom health indicator FX | 2h | `fxProvider` en `/actuator/health` |
| `FxController` | 2h | `GET /fx/rates?from=USD&to=BTC` |
| Unit tests FX | 3h | Mock del adaptador, comportamiento ante errores |

**Total semana 13: ~17h (~3 días)**

### Semana 14 — TRANSFER cross-currency + asiento contable

| Tarea | Horas | Descripción |
|---|---|---|
| `InitiateTransactionCommand` — cross-currency | 5h | Consulta FX, snapshot rate, debita origen, acredita destino en moneda diferente |
| `AutomaticJournalEntryService` — cross-currency | 3h | Asiento con dos monedas distintas |
| Validaciones cross-currency | 2h | Moneda origen ≠ destino, ambas activas en jurisdicción |
| `GET /currencies/{code}/deactivate` | 2h | Solo ADMIN, afecta cuentas a REVIEW, bloquea nuevas TX |
| Integration tests cross-currency | 5h | USD→BTC, BTC→USD, FX provider down retorna 503 |

**Total semana 14: ~17h (~3 días)**

### ✅ Criterio de salida M5
- TRANSFER USD→BTC ejecuta, snapshot de tasa guardado en `transactions.fx_rate`
- Asiento contable cross-currency cuadra con dos monedas distintas
- `FX_RATE_UNAVAILABLE` retorna 503 correctamente
- Desactivar BTC mueve cuentas con saldo BTC a `REVIEW`

---

## M6 — Seguridad + Hardening + Testing final
**Duración estimada: 2 semanas**
**Objetivo: El backend es seguro, observable y resistente. Listo para demo con Postman.**

### Semana 15 — Seguridad completa

| Tarea | Horas | Descripción |
|---|---|---|
| Spring Security config completa | 4h | Todas las rutas protegidas, matriz de roles aplicada |
| `SecurityIT.kt` completo | 5h | 401 sin token, 403 por rol, todos los endpoints críticos |
| Rate limiting end-to-end | 3h | Verificar límites por rol en tests de integración |
| Bean Validation completo | 3h | Validaciones en todos los request DTOs |
| Audit trail review | 2h | Verificar `created_by` en todas las operaciones de escritura |

**Total semana 15: ~17h (~3 días)**

### Semana 16 — Hardening + observabilidad + Postman

| Tarea | Horas | Descripción |
|---|---|---|
| Revisión de errores 5xx | 3h | Ningún stack trace expuesto al cliente |
| Smoke tests E2E con Docker Compose | 4h | Flujo completo: crear customer → cuenta → deposit → transfer → ledger |
| Importar `openapi.yml` en Postman | 2h | Colección generada, environments configurados (`dev`) |
| Postman Collection Scripts | 3h | Captura automática de IDs en variables de entorno |
| Performance básico | 2h | 50 transacciones concurrentes sin race condition |
| Documentación final | 3h | Actualizar ARCHITECTURE.md si hay cambios, README de arranque rápido |

**Total semana 16: ~17h (~3 días)**

### ✅ Criterio de salida M6 — MVP Completo

- [ ] Todos los endpoints del `openapi.yml` responden correctamente
- [ ] Matriz de autorización cumplida al 100%
- [ ] `created_by` presente en todas las operaciones de escritura
- [ ] Partida doble cuadra en el 100% de las transacciones COMPLETED
- [ ] Sin stack traces en respuestas de error
- [ ] Rate limiting activo y verificado
- [ ] Postman collection funcional contra `localhost:8080`
- [ ] CI pasa: unit + integration + security tests
- [ ] Docker Compose levanta todo en `docker compose up`

---

## 📊 Resumen de tiempos

| Milestone | Descripción | Semanas | Horas estimadas |
|---|---|---|---|
| M0 | Fundaciones | 1-2 | ~34h |
| M1 | Shared + Identity | 3-4 | ~36h |
| M2 | Account | 5-6 | ~34h |
| M3 | Transaction | 7-9 | ~58h |
| M4 | Ledger | 10-12 | ~51h |
| M5 | FX + Cross-currency | 13-14 | ~34h |
| M6 | Seguridad + Hardening | 15-16 | ~34h |
| **Total** | | **~16 semanas** | **~281h** |

> A 6h productivas/día y 5 días/semana = 30h/semana.
> 281h ÷ 30h = **~9.4 semanas de trabajo puro**.
> Con el factor +25% de incertidumbre = **~12 semanas**.
> Sumando onboarding al stack (MyBatis, Spring Modulith) = **~16 semanas reales**.

---

## 🚨 Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Curva de aprendizaje MyBatis (vs JPA) | Alta | M2-M3 +1 semana | Prototipo de mapper antes de M1 |
| Spring Modulith Outbox — configuración compleja | Media | M3 +3 días | Spike dedicado en M0 |
| Cross-currency con precisión BTC | Media | M5 +1 semana | Unit tests exhaustivos en M1 para `Money` |
| Auth0 JWKS config en dev | Baja | M1 +1 día | Usar JWT mock desde el día 1 en tests |
| Partida doble con múltiples monedas | Alta | M4 +1 semana | Formalizar asientos en papel antes de codificar |

---

## 🔮 Post-MVP — Deuda Técnica priorizada

Una vez entregado M6, el orden sugerido para atacar la deuda técnica:

| Orden | ID | Descripción |
|---|---|---|
| 1 | TD-LED-001 | Reportes contables: Balance General + Estado de Resultados |
| 2 | TD-OBS-001 | Plataforma de logs centralizada |
| 3 | TD-SEC-001 | Gestión de usuarios via Auth0 Management API |
| 4 | TD-SEC-002 | RBAC granular (permissions por scope) |
| 5 | TD-INFRA-001 | Rate limiting en API Gateway |
| 6 | TD-TEST-001 | Contract tests OpenAPI |
| 7 | TD-PERF-001 | Materialización de vistas read-side |
| 8 | TD-ARCH-001 | Evaluación de extracción a microservicios |

---

*Documento generado en fase de diseño. Las estimaciones son aproximadas para un dev individual senior.*
*Actualizar al finalizar cada milestone con tiempos reales.*
