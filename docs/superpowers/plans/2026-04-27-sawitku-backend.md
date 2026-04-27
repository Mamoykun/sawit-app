# SawitKu Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Spring Boot REST API backend untuk SawitKu — multi-lahan palm oil management dengan JWT auth, Claude AI analisa, dan subscription system.

**Architecture:** Layered Spring Boot 3.5 (Controller → Service → Repository → Entity). JWT stateless auth. Claude API dipanggil async setelah panen disimpan. Redis cache hasil analisa 7 hari.

**Tech Stack:** Java 21, Spring Boot 3.5, PostgreSQL 16, Redis 7, Flyway, JJWT 0.12.3, Lombok, MapStruct, Docker

**Working Directory:** `D:\sawit_app\backend\`

---

## Task 1: Maven Project Setup

**Files:**
- Create: `pom.xml`
- Create: `src/main/java/com/sawitku/SawitkuApplication.java`
- Create: `src/main/resources/application.yml`
- Create: `src/main/resources/application-dev.yml`

- [ ] **Step 1: Create directory structure**

```bash
cd /d/sawit_app/backend
mkdir -p src/main/java/com/sawitku
mkdir -p src/main/java/com/sawitku/{config,controller,service,repository,entity,dto/request,dto/response,mapper,security,exception,util}
mkdir -p src/main/resources/db/migration
mkdir -p src/test/java/com/sawitku/{util,service,integration}
```

- [ ] **Step 2: Create pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.5</version>
        <relativePath/>
    </parent>
    <groupId>com.sawitku</groupId>
    <artifactId>sawitku</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>sawitku</name>
    <description>Platform manajemen kebun sawit</description>
    <properties>
        <java.version>21</java.version>
        <mapstruct.version>1.5.5.Final</mapstruct.version>
    </properties>
    <dependencies>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-redis</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
        <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-core</artifactId></dependency>
        <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-database-postgresql</artifactId></dependency>
        <dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId><scope>runtime</scope></dependency>
        <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
        <dependency><groupId>org.mapstruct</groupId><artifactId>mapstruct</artifactId><version>${mapstruct.version}</version></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-api</artifactId><version>0.12.3</version></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-impl</artifactId><version>0.12.3</version><scope>runtime</scope></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-jackson</artifactId><version>0.12.3</version><scope>runtime</scope></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
        <dependency><groupId>org.testcontainers</groupId><artifactId>postgresql</artifactId><scope>test</scope></dependency>
        <dependency><groupId>org.testcontainers</groupId><artifactId>junit-jupiter</artifactId><scope>test</scope></dependency>
        <dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.6.0</version></dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration><excludes><exclude><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId></exclude></excludes></configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId></path>
                        <path><groupId>org.mapstruct</groupId><artifactId>mapstruct-processor</artifactId><version>${mapstruct.version}</version></path>
                        <path><groupId>org.projectlombok</groupId><artifactId>lombok-mapstruct-binding</artifactId><version>0.2.0</version></path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 3: Create SawitkuApplication.java**

```java
package com.sawitku;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableJpaAuditing
@EnableAsync
public class SawitkuApplication {
    public static void main(String[] args) {
        SpringApplication.run(SawitkuApplication.class, args);
    }
}
```

- [ ] **Step 4: Create application.yml**

```yaml
server:
  port: 8080

spring:
  profiles:
    active: dev
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/sawitku_db}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
    hikari:
      maximum-pool-size: 10
      minimum-idle: 2
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
  flyway:
    enabled: true
    locations: classpath:db/migration
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}

jwt:
  secret: ${JWT_SECRET:sawitku-dev-secret-key-minimum-256-bits-ganti-di-production-ya}
  expiration: 86400000

claude:
  api-key: ${CLAUDE_API_KEY:}
  model: claude-sonnet-4-20250514
  max-tokens: 1000

management:
  endpoints:
    web:
      exposure:
        include: health,info
```

- [ ] **Step 5: Create docker-compose.yml (dev)**

File: `D:\sawit_app\docker-compose.yml`

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: sawitku_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

- [ ] **Step 6: Start Docker services**

```bash
cd /d/sawit_app
docker-compose up -d
```

Expected: postgres dan redis running di port 5432 dan 6379.

- [ ] **Step 7: Commit**

```bash
cd /d/sawit_app
git init
git add backend/pom.xml backend/src docker-compose.yml
git commit -m "feat: initial Spring Boot project setup"
```

---

## Task 2: Flyway Database Migration

**Files:**
- Create: `src/main/resources/db/migration/V1__init_schema.sql`

- [ ] **Step 1: Create V1__init_schema.sql**

```sql
-- Users
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    phone       VARCHAR(20),
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT REFERENCES users(id) ON DELETE CASCADE,
    paket       VARCHAR(20) NOT NULL DEFAULT 'GRATIS',
    status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expired_at  TIMESTAMP,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Lahan
CREATE TABLE lahan (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    nama_lahan      VARCHAR(100) NOT NULL,
    luas_ha         DECIMAL(8,2) NOT NULL,
    usia_pohon      INTEGER NOT NULL,
    jumlah_pohon    INTEGER,
    lokasi          VARCHAR(255),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    catatan         TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- Panen
CREATE TABLE panen (
    id              BIGSERIAL PRIMARY KEY,
    lahan_id        BIGINT REFERENCES lahan(id) ON DELETE CASCADE NOT NULL,
    bulan           VARCHAR(20) NOT NULL,
    tahun           INTEGER NOT NULL,
    bulan_angka     INTEGER NOT NULL,
    ton_aktual      DECIMAL(8,2) NOT NULL,
    target_min      DECIMAL(8,2) NOT NULL,
    target_max      DECIMAL(8,2) NOT NULL,
    target_mid      DECIMAL(8,2) NOT NULL,
    status_panen    VARCHAR(20) NOT NULL,
    persen_kurang   DECIMAL(5,2) DEFAULT 0,
    harga_per_ton   DECIMAL(12,2) DEFAULT 2400000,
    catatan         TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(lahan_id, tahun, bulan_angka)
);

-- Analisa
CREATE TABLE analisa (
    id              BIGSERIAL PRIMARY KEY,
    panen_id        BIGINT REFERENCES panen(id) ON DELETE CASCADE NOT NULL,
    lahan_id        BIGINT REFERENCES lahan(id) ON DELETE CASCADE NOT NULL,
    penyebab_json   JSONB NOT NULL,
    rekomendasi     TEXT,
    ai_response_raw TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_lahan_user ON lahan(user_id);
CREATE INDEX idx_lahan_active ON lahan(user_id, is_active);
CREATE INDEX idx_panen_lahan ON panen(lahan_id);
CREATE INDEX idx_panen_tahun ON panen(lahan_id, tahun);
CREATE INDEX idx_analisa_panen ON analisa(panen_id);
CREATE INDEX idx_analisa_lahan ON analisa(lahan_id);
```

- [ ] **Step 2: Verify migration akan jalan (compile check)**

```bash
cd /d/sawit_app/backend
mvn compile -q
```

Expected: BUILD SUCCESS (belum ada Java errors karena belum ada entity).

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/resources/db/migration/
git commit -m "feat: add flyway schema migration V1"
```

---

## Task 3: Enums

**Files:**
- Create: `src/main/java/com/sawitku/entity/StatusPanen.java`
- Create: `src/main/java/com/sawitku/entity/PaketSubscription.java`

- [ ] **Step 1: Create StatusPanen.java**

```java
package com.sawitku.entity;

public enum StatusPanen {
    NORMAL, WARN, DANGER
}
```

- [ ] **Step 2: Create PaketSubscription.java**

```java
package com.sawitku.entity;

public enum PaketSubscription {
    GRATIS, PETANI, PRO
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/sawitku/entity/
git commit -m "feat: add entity enums"
```

---

## Task 4: JPA Entities

**Files:**
- Create: `src/main/java/com/sawitku/entity/User.java`
- Create: `src/main/java/com/sawitku/entity/Subscription.java`
- Create: `src/main/java/com/sawitku/entity/Lahan.java`
- Create: `src/main/java/com/sawitku/entity/Panen.java`
- Create: `src/main/java/com/sawitku/entity/Analisa.java`

- [ ] **Step 1: Create User.java**

```java
package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class User implements UserDetails {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(unique = true, nullable = false, length = 100)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(length = 20)
    private String phone;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Lahan> lahans;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    private Subscription subscription;

    @Override public Collection<? extends GrantedAuthority> getAuthorities() { return List.of(); }
    @Override public String getUsername() { return email; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return true; }
}
```

- [ ] **Step 2: Create Subscription.java**

```java
package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "subscriptions")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Subscription {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PaketSubscription paket;

    @Column(nullable = false)
    private String status;

    @Column(name = "expired_at")
    private LocalDateTime expiredAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
```

- [ ] **Step 3: Create Lahan.java**

```java
package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "lahan")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Lahan {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "nama_lahan", nullable = false, length = 100)
    private String namaLahan;

    @Column(name = "luas_ha", nullable = false, precision = 8, scale = 2)
    private BigDecimal luasHa;

    @Column(name = "usia_pohon", nullable = false)
    private Integer usiaPohon;

    @Column(name = "jumlah_pohon")
    private Integer jumlahPohon;

    @Column(length = 255)
    private String lokasi;

    @Column(precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(columnDefinition = "TEXT")
    private String catatan;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "lahan", cascade = CascadeType.ALL)
    private List<Panen> panens;
}
```

- [ ] **Step 4: Create Panen.java**

```java
package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "panen")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Panen {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lahan_id", nullable = false)
    private Lahan lahan;

    @Column(nullable = false, length = 20)
    private String bulan;

    @Column(nullable = false)
    private Integer tahun;

    @Column(name = "bulan_angka", nullable = false)
    private Integer bulanAngka;

    @Column(name = "ton_aktual", nullable = false, precision = 8, scale = 2)
    private BigDecimal tonAktual;

    @Column(name = "target_min", nullable = false, precision = 8, scale = 2)
    private BigDecimal targetMin;

    @Column(name = "target_max", nullable = false, precision = 8, scale = 2)
    private BigDecimal targetMax;

    @Column(name = "target_mid", nullable = false, precision = 8, scale = 2)
    private BigDecimal targetMid;

    @Enumerated(EnumType.STRING)
    @Column(name = "status_panen", nullable = false)
    private StatusPanen statusPanen;

    @Column(name = "persen_kurang", precision = 5, scale = 2)
    private BigDecimal persenKurang;

    @Column(name = "harga_per_ton", precision = 12, scale = 2)
    private BigDecimal hargaPerTon;

    @Column(columnDefinition = "TEXT")
    private String catatan;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @OneToOne(mappedBy = "panen", cascade = CascadeType.ALL)
    private Analisa analisa;
}
```

- [ ] **Step 5: Create Analisa.java**

```java
package com.sawitku.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "analisa")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Analisa {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "panen_id", nullable = false)
    private Panen panen;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lahan_id", nullable = false)
    private Lahan lahan;

    @Column(name = "penyebab_json", columnDefinition = "JSONB")
    private String penyebabJson;

    @Column(columnDefinition = "TEXT")
    private String rekomendasi;

    @Column(name = "ai_response_raw", columnDefinition = "TEXT")
    private String aiResponseRaw;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
```

- [ ] **Step 6: Compile check**

```bash
cd /d/sawit_app/backend
mvn compile -q
```

Expected: BUILD SUCCESS

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/sawitku/entity/
git commit -m "feat: add JPA entities (User, Subscription, Lahan, Panen, Analisa)"
```

---

## Task 5: Repositories

**Files:**
- Create: `src/main/java/com/sawitku/repository/UserRepository.java`
- Create: `src/main/java/com/sawitku/repository/SubscriptionRepository.java`
- Create: `src/main/java/com/sawitku/repository/LahanRepository.java`
- Create: `src/main/java/com/sawitku/repository/PanenRepository.java`
- Create: `src/main/java/com/sawitku/repository/AnalisaRepository.java`

- [ ] **Step 1: Create all repositories**

```java
// UserRepository.java
package com.sawitku.repository;
import com.sawitku.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
```

```java
// SubscriptionRepository.java
package com.sawitku.repository;
import com.sawitku.entity.Subscription;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
    Optional<Subscription> findByUserId(Long userId);
}
```

```java
// LahanRepository.java
package com.sawitku.repository;
import com.sawitku.entity.Lahan;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
public interface LahanRepository extends JpaRepository<Lahan, Long> {
    List<Lahan> findByUserIdAndIsActiveTrue(Long userId);
    long countByUserIdAndIsActiveTrue(Long userId);
    Optional<Lahan> findByIdAndUserId(Long id, Long userId);
}
```

```java
// PanenRepository.java
package com.sawitku.repository;
import com.sawitku.entity.Panen;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
public interface PanenRepository extends JpaRepository<Panen, Long> {
    List<Panen> findByLahanIdOrderByTahunDescBulanAngkaDesc(Long lahanId, Pageable pageable);
    List<Panen> findByLahanIdAndTahunOrderByBulanAngkaDesc(Long lahanId, Integer tahun);
    boolean existsByLahanIdAndTahunAndBulanAngka(Long lahanId, Integer tahun, Integer bulanAngka);
    Optional<Panen> findFirstByLahanIdOrderByTahunDescBulanAngkaDesc(Long lahanId);
    Optional<Panen> findByIdAndLahanId(Long id, Long lahanId);
}
```

```java
// AnalisaRepository.java
package com.sawitku.repository;
import com.sawitku.entity.Analisa;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface AnalisaRepository extends JpaRepository<Analisa, Long> {
    Optional<Analisa> findByPanenId(Long panenId);
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/sawitku/repository/
git commit -m "feat: add JPA repositories"
```

---

## Task 6: DTOs & Exception Classes

**Files:**
- Create: `src/main/java/com/sawitku/dto/request/RegisterRequest.java`
- Create: `src/main/java/com/sawitku/dto/request/LoginRequest.java`
- Create: `src/main/java/com/sawitku/dto/request/LahanRequest.java`
- Create: `src/main/java/com/sawitku/dto/request/PanenRequest.java`
- Create: `src/main/java/com/sawitku/dto/response/ApiResponse.java`
- Create: `src/main/java/com/sawitku/dto/response/AuthResponse.java`
- Create: `src/main/java/com/sawitku/dto/response/LahanResponse.java`
- Create: `src/main/java/com/sawitku/dto/response/PanenResponse.java`
- Create: `src/main/java/com/sawitku/dto/response/AnalisaResponse.java`
- Create: `src/main/java/com/sawitku/exception/ResourceNotFoundException.java`
- Create: `src/main/java/com/sawitku/exception/BusinessException.java`
- Create: `src/main/java/com/sawitku/exception/GlobalExceptionHandler.java`
- Create: `src/main/java/com/sawitku/util/ResponseUtil.java`

- [ ] **Step 1: Create request DTOs**

```java
// RegisterRequest.java
package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
@Data
public class RegisterRequest {
    @NotBlank @Size(max=100) public String name;
    @NotBlank @Email @Size(max=100) public String email;
    @NotBlank @Size(min=6, max=100) public String password;
    @Size(max=20) public String phone;
}
```

```java
// LoginRequest.java
package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
@Data
public class LoginRequest {
    @NotBlank @Email public String email;
    @NotBlank public String password;
}
```

```java
// LahanRequest.java
package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class LahanRequest {
    @NotBlank @Size(max=100) public String namaLahan;
    @NotNull @Positive public BigDecimal luasHa;
    @NotNull @Min(1) @Max(50) public Integer usiaPohon;
    public Integer jumlahPohon;
    @Size(max=255) public String lokasi;
    public BigDecimal latitude;
    public BigDecimal longitude;
    public String catatan;
}
```

```java
// PanenRequest.java
package com.sawitku.dto.request;
import jakarta.validation.constraints.*;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class PanenRequest {
    @NotBlank @Size(max=20) public String bulan;
    @NotNull @Min(2020) @Max(2100) public Integer tahun;
    @NotNull @Min(1) @Max(12) public Integer bulanAngka;
    @NotNull @Positive public BigDecimal tonAktual;
    public BigDecimal hargaPerTon;
    public String catatan;
}
```

- [ ] **Step 2: Create ApiResponse.java**

```java
package com.sawitku.dto.response;
import lombok.*;
import java.time.LocalDateTime;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private String code;
    private LocalDateTime timestamp;
}
```

- [ ] **Step 3: Create response DTOs**

```java
// AuthResponse.java
package com.sawitku.dto.response;
import lombok.*;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AuthResponse {
    private String token;
    private UserInfo user;
    private SubscriptionInfo subscription;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class UserInfo {
        private Long id;
        private String name;
        private String email;
        private String phone;
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class SubscriptionInfo {
        private String paket;
        private String status;
        private String expiredAt;
    }
}
```

```java
// LahanResponse.java
package com.sawitku.dto.response;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class LahanResponse {
    private Long id;
    private String namaLahan;
    private BigDecimal luasHa;
    private Integer usiaPohon;
    private Integer jumlahPohon;
    private String lokasi;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String catatan;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private PanenSummary panenTerakhir;
    private String statusTerkini;
    private String faseProduksi;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class PanenSummary {
        private Long id;
        private String bulan;
        private Integer tahun;
        private BigDecimal tonAktual;
        private BigDecimal targetMid;
        private String statusPanen;
        private BigDecimal persenKurang;
    }
}
```

```java
// PanenResponse.java
package com.sawitku.dto.response;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PanenResponse {
    private Long id;
    private Long lahanId;
    private String namaLahan;
    private String bulan;
    private Integer tahun;
    private Integer bulanAngka;
    private BigDecimal tonAktual;
    private BigDecimal targetMin;
    private BigDecimal targetMax;
    private BigDecimal targetMid;
    private String statusPanen;
    private BigDecimal persenKurang;
    private BigDecimal hargaPerTon;
    private BigDecimal nilaiEstimasi;
    private String catatan;
    private LocalDateTime createdAt;
    private AnalisaResponse analisa;
}
```

```java
// AnalisaResponse.java
package com.sawitku.dto.response;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AnalisaResponse {
    private Long id;
    private String status; // DONE, PROCESSING, FAILED
    private List<PenyebabItem> penyebab;
    private String ringkasan;
    private String prioritasTindakan;
    private LocalDateTime createdAt;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class PenyebabItem {
        private String icon;
        private String title;
        private String detail;
        private String severity;
        private String estimasiDampak;
    }
}
```

- [ ] **Step 4: Create exception classes**

```java
// ResourceNotFoundException.java
package com.sawitku.exception;
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) { super(message); }
}
```

```java
// BusinessException.java
package com.sawitku.exception;
import lombok.Getter;
@Getter
public class BusinessException extends RuntimeException {
    private final String code;
    public BusinessException(String message, String code) {
        super(message);
        this.code = code;
    }
}
```

- [ ] **Step 5: Create GlobalExceptionHandler.java**

```java
package com.sawitku.exception;

import com.sawitku.dto.response.ApiResponse;
import org.springframework.http.*;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.<Void>builder()
            .success(false).message(ex.getMessage()).code("NOT_FOUND")
            .timestamp(LocalDateTime.now()).build());
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusiness(BusinessException ex) {
        return ResponseEntity.badRequest().body(ApiResponse.<Void>builder()
            .success(false).message(ex.getMessage()).code(ex.getCode())
            .timestamp(LocalDateTime.now()).build());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage).collect(Collectors.joining(", "));
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(ApiResponse.<Void>builder()
            .success(false).message(msg).code("VALIDATION_ERROR")
            .timestamp(LocalDateTime.now()).build());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGeneral(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiResponse.<Void>builder()
            .success(false).message("Terjadi kesalahan internal").code("INTERNAL_ERROR")
            .timestamp(LocalDateTime.now()).build());
    }
}
```

- [ ] **Step 6: Create ResponseUtil.java**

```java
package com.sawitku.util;

import com.sawitku.dto.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import java.time.LocalDateTime;

public class ResponseUtil {
    public static <T> ResponseEntity<ApiResponse<T>> ok(T data, String message) {
        return ResponseEntity.ok(ApiResponse.<T>builder()
            .success(true).message(message).data(data)
            .timestamp(LocalDateTime.now()).build());
    }

    public static <T> ResponseEntity<ApiResponse<T>> ok(T data) {
        return ok(data, "Berhasil");
    }
}
```

- [ ] **Step 7: Compile check**

```bash
cd /d/sawit_app/backend
mvn compile -q
```

Expected: BUILD SUCCESS

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/com/sawitku/
git commit -m "feat: add DTOs, exceptions, and response utilities"
```

---

## Task 7: AnalisaCalculator Utility

**Files:**
- Create: `src/main/java/com/sawitku/util/AnalisaCalculator.java`
- Create: `src/test/java/com/sawitku/util/AnalisaCalculatorTest.java`

- [ ] **Step 1: Write failing tests first**

```java
// AnalisaCalculatorTest.java
package com.sawitku.util;

import com.sawitku.entity.StatusPanen;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class AnalisaCalculatorTest {

    @Test
    void getTarget_usiaBelumProduksi() {
        var result = AnalisaCalculator.getTarget(2.0, 2);
        assertThat(result.min()).isEqualByComparingTo(new java.math.BigDecimal("0.60"));
        assertThat(result.max()).isEqualByComparingTo(new java.math.BigDecimal("1.60"));
        assertThat(result.fase()).isEqualTo("Belum Produksi");
    }

    @Test
    void getTarget_usiaPuncakProduktif() {
        var result = AnalisaCalculator.getTarget(2.0, 12);
        assertThat(result.min()).isEqualByComparingTo(new java.math.BigDecimal("3.60"));
        assertThat(result.max()).isEqualByComparingTo(new java.math.BigDecimal("4.60"));
        assertThat(result.fase()).isEqualTo("Puncak Produktif");
    }

    @Test
    void getStatusPanen_normal() {
        assertThat(AnalisaCalculator.getStatus(
            new java.math.BigDecimal("3.0"),
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        )).isEqualTo(StatusPanen.NORMAL);
    }

    @Test
    void getStatusPanen_warn() {
        assertThat(AnalisaCalculator.getStatus(
            new java.math.BigDecimal("1.5"),
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        )).isEqualTo(StatusPanen.WARN);
    }

    @Test
    void getStatusPanen_danger() {
        assertThat(AnalisaCalculator.getStatus(
            new java.math.BigDecimal("1.0"),
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        )).isEqualTo(StatusPanen.DANGER);
    }

    @Test
    void hitungPersenKurang_positif() {
        var result = AnalisaCalculator.hitungPersenKurang(
            new java.math.BigDecimal("2.0"),
            new java.math.BigDecimal("2.5")
        );
        assertThat(result).isEqualByComparingTo(new java.math.BigDecimal("20.00"));
    }

    @Test
    void hitungPersenKurang_nolKalauMelebihiTarget() {
        var result = AnalisaCalculator.hitungPersenKurang(
            new java.math.BigDecimal("3.0"),
            new java.math.BigDecimal("2.5")
        );
        assertThat(result).isEqualByComparingTo(java.math.BigDecimal.ZERO);
    }
}
```

- [ ] **Step 2: Run test — expected FAIL**

```bash
cd /d/sawit_app/backend
mvn test -pl . -Dtest=AnalisaCalculatorTest -q 2>&1 | tail -5
```

Expected: FAILED (AnalisaCalculator not found)

- [ ] **Step 3: Implement AnalisaCalculator.java**

```java
package com.sawitku.util;

import com.sawitku.entity.StatusPanen;
import java.math.BigDecimal;
import java.math.RoundingMode;

public class AnalisaCalculator {

    public record TargetPanen(BigDecimal min, BigDecimal max, BigDecimal mid, String fase) {}

    public static TargetPanen getTarget(double luasHa, int usia) {
        double minPerHa, maxPerHa;
        String fase;
        if (usia < 3)        { minPerHa = 0.3; maxPerHa = 0.8; fase = "Belum Produksi"; }
        else if (usia <= 5)  { minPerHa = 0.8; maxPerHa = 1.4; fase = "Produksi Awal"; }
        else if (usia <= 10) { minPerHa = 1.5; maxPerHa = 2.0; fase = "Puncak Awal"; }
        else if (usia <= 15) { minPerHa = 1.8; maxPerHa = 2.3; fase = "Puncak Produktif"; }
        else if (usia <= 20) { minPerHa = 1.5; maxPerHa = 1.9; fase = "Produksi Stabil"; }
        else                 { minPerHa = 1.0; maxPerHa = 1.5; fase = "Produksi Menurun"; }

        BigDecimal min = BigDecimal.valueOf(minPerHa * luasHa).setScale(2, RoundingMode.HALF_UP);
        BigDecimal max = BigDecimal.valueOf(maxPerHa * luasHa).setScale(2, RoundingMode.HALF_UP);
        BigDecimal mid = min.add(max).divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP);
        return new TargetPanen(min, max, mid, fase);
    }

    public static StatusPanen getStatus(BigDecimal tonAktual, BigDecimal targetMin, BigDecimal targetMid) {
        if (tonAktual.compareTo(targetMin) >= 0) return StatusPanen.NORMAL;
        BigDecimal persen = hitungPersenKurang(tonAktual, targetMid);
        return persen.compareTo(BigDecimal.valueOf(20)) <= 0 ? StatusPanen.WARN : StatusPanen.DANGER;
    }

    public static BigDecimal hitungPersenKurang(BigDecimal tonAktual, BigDecimal targetMid) {
        if (targetMid.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.ZERO;
        BigDecimal diff = targetMid.subtract(tonAktual);
        if (diff.compareTo(BigDecimal.ZERO) <= 0) return BigDecimal.ZERO;
        return diff.divide(targetMid, 4, RoundingMode.HALF_UP)
                   .multiply(BigDecimal.valueOf(100))
                   .setScale(2, RoundingMode.HALF_UP);
    }
}
```

- [ ] **Step 4: Run tests — expected PASS**

```bash
mvn test -Dtest=AnalisaCalculatorTest -q
```

Expected: BUILD SUCCESS, 7 tests passed

- [ ] **Step 5: Commit**

```bash
git add backend/src/
git commit -m "feat: add AnalisaCalculator with TDD"
```

---

## Task 8: JWT Security

**Files:**
- Create: `src/main/java/com/sawitku/security/JwtUtil.java`
- Create: `src/main/java/com/sawitku/security/UserDetailsServiceImpl.java`
- Create: `src/main/java/com/sawitku/security/JwtAuthFilter.java`
- Create: `src/main/java/com/sawitku/config/SecurityConfig.java`
- Create: `src/main/java/com/sawitku/config/RedisConfig.java`

- [ ] **Step 1: Create JwtUtil.java**

```java
package com.sawitku.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    private SecretKey getKey() {
        byte[] bytes = Decoders.BASE64.decode(
            java.util.Base64.getEncoder().encodeToString(secret.getBytes())
        );
        return Keys.hmacShaKeyFor(bytes);
    }

    public String generateToken(UserDetails user) {
        return Jwts.builder()
            .subject(user.getUsername())
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(getKey())
            .compact();
    }

    public String extractUsername(String token) {
        return Jwts.parser().verifyWith(getKey()).build()
            .parseSignedClaims(token).getPayload().getSubject();
    }

    public boolean validateToken(String token, UserDetails user) {
        try {
            String username = extractUsername(token);
            return username.equals(user.getUsername()) &&
                   !Jwts.parser().verifyWith(getKey()).build()
                        .parseSignedClaims(token).getPayload().getExpiration().before(new Date());
        } catch (JwtException e) {
            return false;
        }
    }
}
```

- [ ] **Step 2: Create UserDetailsServiceImpl.java**

```java
package com.sawitku.security;

import com.sawitku.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userRepository.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("User tidak ditemukan: " + email));
    }
}
```

- [ ] **Step 3: Create JwtAuthFilter.java**

```java
package com.sawitku.security;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserDetailsServiceImpl userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res,
                                    FilterChain chain) throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(req, res);
            return;
        }
        String token = header.substring(7);
        try {
            String email = jwtUtil.extractUsername(token);
            if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails user = userDetailsService.loadUserByUsername(email);
                if (jwtUtil.validateToken(token, user)) {
                    var auth = new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(req));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        } catch (Exception ignored) {}
        chain.doFilter(req, res);
    }
}
```

- [ ] **Step 4: Create SecurityConfig.java**

```java
package com.sawitku.config;

import com.sawitku.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.*;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.*;
import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final UserDetailsService userDetailsService;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**", "/actuator/health", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .anyRequest().authenticated()
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        var provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        var config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

- [ ] **Step 5: Create RedisConfig.java**

```java
package com.sawitku.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.*;

@Configuration
public class RedisConfig {
    @Bean
    public RedisTemplate<String, String> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, String> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new StringRedisSerializer());
        return template;
    }
}
```

- [ ] **Step 6: Compile check**

```bash
cd /d/sawit_app/backend
mvn compile -q
```

Expected: BUILD SUCCESS

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/sawitku/security/ backend/src/main/java/com/sawitku/config/
git commit -m "feat: add JWT security (JwtUtil, JwtAuthFilter, SecurityConfig)"
```

---

## Task 9: AuthService & AuthController

**Files:**
- Create: `src/main/java/com/sawitku/service/AuthService.java`
- Create: `src/main/java/com/sawitku/controller/AuthController.java`

- [ ] **Step 1: Create AuthService.java**

```java
package com.sawitku.service;

import com.sawitku.dto.request.*;
import com.sawitku.dto.response.AuthResponse;
import com.sawitku.entity.*;
import com.sawitku.exception.BusinessException;
import com.sawitku.repository.*;
import com.sawitku.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authManager;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByEmail(req.getEmail()))
            throw new BusinessException("Email sudah digunakan", "EMAIL_EXISTS");

        User user = User.builder()
            .name(req.getName()).email(req.getEmail())
            .password(passwordEncoder.encode(req.getPassword()))
            .phone(req.getPhone()).build();
        userRepository.save(user);

        Subscription sub = Subscription.builder()
            .user(user).paket(PaketSubscription.GRATIS)
            .status("ACTIVE").createdAt(LocalDateTime.now()).build();
        subscriptionRepository.save(sub);

        String token = jwtUtil.generateToken(user);
        return buildAuthResponse(token, user, sub);
    }

    public AuthResponse login(LoginRequest req) {
        authManager.authenticate(new UsernamePasswordAuthenticationToken(req.getEmail(), req.getPassword()));
        User user = userRepository.findByEmail(req.getEmail()).orElseThrow();
        Subscription sub = subscriptionRepository.findByUserId(user.getId()).orElseThrow();
        return buildAuthResponse(jwtUtil.generateToken(user), user, sub);
    }

    private AuthResponse buildAuthResponse(String token, User user, Subscription sub) {
        return AuthResponse.builder()
            .token(token)
            .user(AuthResponse.UserInfo.builder()
                .id(user.getId()).name(user.getName())
                .email(user.getEmail()).phone(user.getPhone()).build())
            .subscription(AuthResponse.SubscriptionInfo.builder()
                .paket(sub.getPaket().name()).status(sub.getStatus())
                .expiredAt(sub.getExpiredAt() != null ? sub.getExpiredAt().toString() : null).build())
            .build();
    }
}
```

- [ ] **Step 2: Create AuthController.java**

```java
package com.sawitku.controller;

import com.sawitku.dto.request.*;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.repository.SubscriptionRepository;
import com.sawitku.service.AuthService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final SubscriptionRepository subscriptionRepository;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest req) {
        return ResponseUtil.ok(authService.register(req), "Registrasi berhasil");
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest req) {
        return ResponseUtil.ok(authService.login(req), "Login berhasil");
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse.UserInfo>> me(@AuthenticationPrincipal User user) {
        return ResponseUtil.ok(AuthResponse.UserInfo.builder()
            .id(user.getId()).name(user.getName())
            .email(user.getEmail()).phone(user.getPhone()).build());
    }
}
```

- [ ] **Step 3: Start app dan test manual**

```bash
cd /d/sawit_app/backend
mvn spring-boot:run &
```

Tunggu "Started SawitkuApplication", lalu:

```bash
curl -s -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@sawitku.id","password":"password123"}' | python -m json.tool
```

Expected: `{"success":true,"data":{"token":"eyJ..."}}`

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/sawitku/service/AuthService.java
git add backend/src/main/java/com/sawitku/controller/AuthController.java
git commit -m "feat: add auth register/login endpoints"
```

---

## Task 10: SubscriptionService

**Files:**
- Create: `src/main/java/com/sawitku/service/SubscriptionService.java`

- [ ] **Step 1: Create SubscriptionService.java**

```java
package com.sawitku.service;

import com.sawitku.entity.PaketSubscription;
import com.sawitku.exception.BusinessException;
import com.sawitku.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import java.time.YearMonth;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepository;
    private final LahanRepository lahanRepository;
    private final RedisTemplate<String, String> redisTemplate;

    public PaketSubscription getPaket(Long userId) {
        return subscriptionRepository.findByUserId(userId)
            .map(s -> s.getPaket())
            .orElse(PaketSubscription.GRATIS);
    }

    public void checkLimitLahan(Long userId) {
        PaketSubscription paket = getPaket(userId);
        long count = lahanRepository.countByUserIdAndIsActiveTrue(userId);
        int max = switch (paket) {
            case GRATIS -> 2;
            case PETANI -> 10;
            case PRO -> Integer.MAX_VALUE;
        };
        if (count >= max)
            throw new BusinessException(
                "Batas lahan untuk paket " + paket.name() + " adalah " + max + " lahan. Upgrade paket untuk menambah lebih banyak lahan.",
                "LAHAN_LIMIT_EXCEEDED"
            );
    }

    public void checkLimitAnalisaAI(Long userId) {
        PaketSubscription paket = getPaket(userId);
        int max = switch (paket) {
            case GRATIS -> 5;
            case PETANI -> 30;
            case PRO -> Integer.MAX_VALUE;
        };
        if (max == Integer.MAX_VALUE) return;

        String key = "analisa_count:" + userId + ":" + YearMonth.now();
        String val = redisTemplate.opsForValue().get(key);
        int count = val != null ? Integer.parseInt(val) : 0;
        if (count >= max)
            throw new BusinessException(
                "Batas analisa AI bulan ini untuk paket " + paket.name() + " adalah " + max + " kali.",
                "ANALISA_LIMIT_EXCEEDED"
            );
    }

    public void incrementAnalisaCount(Long userId) {
        String key = "analisa_count:" + userId + ":" + YearMonth.now();
        redisTemplate.opsForValue().increment(key);
        redisTemplate.expire(key, 35, TimeUnit.DAYS);
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/sawitku/service/SubscriptionService.java
git commit -m "feat: add SubscriptionService with Redis-based AI limit tracking"
```

---

## Task 11: LahanService & LahanController

**Files:**
- Create: `src/main/java/com/sawitku/service/LahanService.java`
- Create: `src/main/java/com/sawitku/controller/LahanController.java`

- [ ] **Step 1: Create LahanService.java**

```java
package com.sawitku.service;

import com.sawitku.dto.request.LahanRequest;
import com.sawitku.dto.response.LahanResponse;
import com.sawitku.entity.Lahan;
import com.sawitku.entity.User;
import com.sawitku.exception.*;
import com.sawitku.repository.*;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LahanService {

    private final LahanRepository lahanRepository;
    private final UserRepository userRepository;
    private final PanenRepository panenRepository;
    private final SubscriptionService subscriptionService;

    @Transactional
    public LahanResponse createLahan(Long userId, LahanRequest req) {
        subscriptionService.checkLimitLahan(userId);
        User user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User tidak ditemukan"));
        Lahan lahan = Lahan.builder()
            .user(user).namaLahan(req.getNamaLahan())
            .luasHa(req.getLuasHa()).usiaPohon(req.getUsiaPohon())
            .jumlahPohon(req.getJumlahPohon()).lokasi(req.getLokasi())
            .latitude(req.getLatitude()).longitude(req.getLongitude())
            .catatan(req.getCatatan()).isActive(true).build();
        lahanRepository.save(lahan);
        return toResponse(lahan);
    }

    @Transactional
    public LahanResponse updateLahan(Long userId, Long lahanId, LahanRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        lahan.setNamaLahan(req.getNamaLahan());
        lahan.setLuasHa(req.getLuasHa());
        lahan.setUsiaPohon(req.getUsiaPohon());
        lahan.setJumlahPohon(req.getJumlahPohon());
        lahan.setLokasi(req.getLokasi());
        lahan.setLatitude(req.getLatitude());
        lahan.setLongitude(req.getLongitude());
        lahan.setCatatan(req.getCatatan());
        lahanRepository.save(lahan);
        return toResponse(lahan);
    }

    @Transactional
    public void deleteLahan(Long userId, Long lahanId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        lahan.setIsActive(false);
        lahanRepository.save(lahan);
    }

    public List<LahanResponse> getMyLahan(Long userId) {
        return lahanRepository.findByUserIdAndIsActiveTrue(userId)
            .stream().map(this::toResponse).toList();
    }

    public LahanResponse getLahanById(Long userId, Long lahanId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return toResponse(lahan);
    }

    private LahanResponse toResponse(Lahan lahan) {
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        LahanResponse.PanenSummary panenSummary = panenRepository
            .findFirstByLahanIdOrderByTahunDescBulanAngkaDesc(lahan.getId())
            .map(p -> LahanResponse.PanenSummary.builder()
                .id(p.getId()).bulan(p.getBulan()).tahun(p.getTahun())
                .tonAktual(p.getTonAktual()).targetMid(p.getTargetMid())
                .statusPanen(p.getStatusPanen().name()).persenKurang(p.getPersenKurang()).build())
            .orElse(null);

        return LahanResponse.builder()
            .id(lahan.getId()).namaLahan(lahan.getNamaLahan())
            .luasHa(lahan.getLuasHa()).usiaPohon(lahan.getUsiaPohon())
            .jumlahPohon(lahan.getJumlahPohon()).lokasi(lahan.getLokasi())
            .latitude(lahan.getLatitude()).longitude(lahan.getLongitude())
            .catatan(lahan.getCatatan()).isActive(lahan.getIsActive())
            .createdAt(lahan.getCreatedAt()).faseProduksi(target.fase())
            .panenTerakhir(panenSummary)
            .statusTerkini(panenSummary != null ? panenSummary.getStatusPanen() : null)
            .build();
    }
}
```

- [ ] **Step 2: Create LahanController.java**

```java
package com.sawitku.controller;

import com.sawitku.dto.request.LahanRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.service.LahanService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/lahan")
@RequiredArgsConstructor
public class LahanController {

    private final LahanService lahanService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<LahanResponse>>> getMyLahan(@AuthenticationPrincipal User user) {
        return ResponseUtil.ok(lahanService.getMyLahan(user.getId()));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<LahanResponse>> create(@AuthenticationPrincipal User user,
                                                              @Valid @RequestBody LahanRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(lahanService.createLahan(user.getId(), req), "Lahan berhasil dibuat").getBody());
    }

    @GetMapping("/{lahanId}")
    public ResponseEntity<ApiResponse<LahanResponse>> getById(@AuthenticationPrincipal User user,
                                                               @PathVariable Long lahanId) {
        return ResponseUtil.ok(lahanService.getLahanById(user.getId(), lahanId));
    }

    @PutMapping("/{lahanId}")
    public ResponseEntity<ApiResponse<LahanResponse>> update(@AuthenticationPrincipal User user,
                                                              @PathVariable Long lahanId,
                                                              @Valid @RequestBody LahanRequest req) {
        return ResponseUtil.ok(lahanService.updateLahan(user.getId(), lahanId, req), "Lahan berhasil diupdate");
    }

    @DeleteMapping("/{lahanId}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal User user, @PathVariable Long lahanId) {
        lahanService.deleteLahan(user.getId(), lahanId);
        return ResponseEntity.noContent().build();
    }
}
```

- [ ] **Step 3: Compile dan restart**

```bash
cd /d/sawit_app/backend
mvn compile -q && echo "OK"
```

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/sawitku/service/LahanService.java
git add backend/src/main/java/com/sawitku/controller/LahanController.java
git commit -m "feat: add lahan CRUD endpoints with subscription limit check"
```

---

## Task 12: ClaudeService (AI Integration)

**Files:**
- Create: `src/main/java/com/sawitku/service/ClaudeService.java`

- [ ] **Step 1: Create ClaudeService.java**

```java
package com.sawitku.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.response.AnalisaResponse;
import com.sawitku.entity.*;
import com.sawitku.repository.AnalisaRepository;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class ClaudeService {

    private final AnalisaRepository analisaRepository;
    private final RedisTemplate<String, String> redisTemplate;
    private final SubscriptionService subscriptionService;
    private final ObjectMapper objectMapper;

    @Value("${claude.api-key}")
    private String apiKey;

    @Value("${claude.model}")
    private String model;

    @Value("${claude.max-tokens}")
    private int maxTokens;

    private static final String CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";

    @Async
    public void analyzePanen(Panen panen, Lahan lahan) {
        String cacheKey = "analisa:" + panen.getId();
        try {
            subscriptionService.checkLimitAnalisaAI(lahan.getUser().getId());
            String prompt = buildPrompt(panen, lahan);
            String rawResponse = callClaudeApi(prompt);
            AnalisaResult result = parseResponse(rawResponse);
            saveAnalisa(panen, lahan, result, rawResponse);
            subscriptionService.incrementAnalisaCount(lahan.getUser().getId());
            redisTemplate.opsForValue().set(cacheKey, "DONE", 7, TimeUnit.DAYS);
        } catch (Exception e) {
            log.error("Claude API error untuk panen {}: {}", panen.getId(), e.getMessage());
            saveFallbackAnalisa(panen, lahan);
            redisTemplate.opsForValue().set(cacheKey, "DONE", 7, TimeUnit.DAYS);
        }
    }

    private String buildPrompt(Panen panen, Lahan lahan) {
        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        return """
            Kamu adalah ahli agronomi perkebunan sawit Indonesia berpengalaman 20 tahun.
            
            Data kebun:
            - Nama lahan: %s
            - Luas: %s hektar
            - Usia pohon: %d tahun
            - Fase produksi: %s
            - Lokasi: %s
            
            Data panen %s %d:
            - Hasil aktual: %s ton
            - Target normal: %s - %s ton
            - Kekurangan: %s%% dari target
            
            Analisa penyebab mengapa panen di bawah target dan berikan rekomendasi spesifik.
            Balas HANYA dengan JSON valid (tanpa markdown/backtick):
            {"penyebab":[{"icon":"emoji","title":"judul singkat","detail":"penjelasan + rekomendasi 2-3 kalimat","severity":"high|medium|low","estimasi_dampak":"X-Y%% penurunan"}],"ringkasan":"ringkasan 1 kalimat","prioritas_tindakan":"tindakan paling penting minggu ini"}
            """.formatted(
                lahan.getNamaLahan(), lahan.getLuasHa(), lahan.getUsiaPohon(),
                target.fase(), lahan.getLokasi() != null ? lahan.getLokasi() : "Tidak diketahui",
                panen.getBulan(), panen.getTahun(),
                panen.getTonAktual(), panen.getTargetMin(), panen.getTargetMax(),
                panen.getPersenKurang()
            );
    }

    private String callClaudeApi(String prompt) {
        RestTemplate rest = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = Map.of(
            "model", model,
            "max_tokens", maxTokens,
            "messages", List.of(Map.of("role", "user", "content", prompt))
        );

        ResponseEntity<Map> response = rest.exchange(
            CLAUDE_API_URL, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);

        List<Map<String, Object>> content = (List<Map<String, Object>>) response.getBody().get("content");
        return (String) content.get(0).get("text");
    }

    private record AnalisaResult(List<AnalisaResponse.PenyebabItem> penyebab, String ringkasan, String prioritas) {}

    private AnalisaResult parseResponse(String raw) throws Exception {
        Map<String, Object> parsed = objectMapper.readValue(raw.trim(), Map.class);
        List<Map<String, Object>> penyebabList = (List<Map<String, Object>>) parsed.get("penyebab");
        List<AnalisaResponse.PenyebabItem> items = penyebabList.stream()
            .map(p -> AnalisaResponse.PenyebabItem.builder()
                .icon((String) p.get("icon")).title((String) p.get("title"))
                .detail((String) p.get("detail")).severity((String) p.get("severity"))
                .estimasiDampak((String) p.getOrDefault("estimasi_dampak", "")).build())
            .toList();
        return new AnalisaResult(items, (String) parsed.get("ringkasan"), (String) parsed.get("prioritas_tindakan"));
    }

    private void saveAnalisa(Panen panen, Lahan lahan, AnalisaResult result, String raw) throws Exception {
        String penyebabJson = objectMapper.writeValueAsString(result.penyebab());
        Analisa analisa = Analisa.builder()
            .panen(panen).lahan(lahan)
            .penyebabJson(penyebabJson)
            .rekomendasi(result.prioritas())
            .aiResponseRaw(raw)
            .createdAt(LocalDateTime.now()).build();
        analisaRepository.save(analisa);
    }

    private void saveFallbackAnalisa(Panen panen, Lahan lahan) {
        try {
            double persen = panen.getPersenKurang().doubleValue();
            List<AnalisaResponse.PenyebabItem> items = getFallbackPenyebab(persen);
            String penyebabJson = objectMapper.writeValueAsString(items);
            Analisa analisa = Analisa.builder()
                .panen(panen).lahan(lahan)
                .penyebabJson(penyebabJson)
                .rekomendasi("Periksa kondisi lahan dan lakukan tindakan pemupukan rutin.")
                .aiResponseRaw("FALLBACK")
                .createdAt(LocalDateTime.now()).build();
            analisaRepository.save(analisa);
        } catch (Exception e) {
            log.error("Fallback analisa gagal: {}", e.getMessage());
        }
    }

    private List<AnalisaResponse.PenyebabItem> getFallbackPenyebab(double persen) {
        List<AnalisaResponse.PenyebabItem> list = new ArrayList<>();
        if (persen > 8) list.add(item("🌿", "Defisiensi Kalium (K)", "Aplikasikan pupuk MOP 0.5–1 kg per pohon. Kalium meningkatkan bobot tandan dan kualitas minyak sawit.", "high", "8-15%"));
        if (persen > 15) list.add(item("💧", "Stres Kekeringan", "Pasang mulsa pelepah di piringan pohon radius 2 meter untuk menjaga kelembaban tanah di musim kering.", "high", "10-20%"));
        if (persen > 20) list.add(item("🐛", "Serangan Hama / Penyakit", "Periksa tanda ulat api, kumbang badak, atau gejala Ganoderma di pangkal batang pohon.", "medium", "5-15%"));
        if (list.isEmpty()) list.add(item("🌡️", "Faktor Musiman Normal", "Fluktuasi 1–8% masih dalam batas wajar akibat perubahan cuaca dan siklus alami tanaman sawit.", "low", "1-8%"));
        return list;
    }

    private AnalisaResponse.PenyebabItem item(String icon, String title, String detail, String severity, String dampak) {
        return AnalisaResponse.PenyebabItem.builder()
            .icon(icon).title(title).detail(detail).severity(severity).estimasiDampak(dampak).build();
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/main/java/com/sawitku/service/ClaudeService.java
git commit -m "feat: add ClaudeService with async AI analysis and fallback"
```

---

## Task 13: PanenService & PanenController

**Files:**
- Create: `src/main/java/com/sawitku/service/PanenService.java`
- Create: `src/main/java/com/sawitku/controller/PanenController.java`
- Create: `src/main/java/com/sawitku/controller/BerandaController.java`

- [ ] **Step 1: Create PanenService.java**

```java
package com.sawitku.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sawitku.dto.request.PanenRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.*;
import com.sawitku.exception.*;
import com.sawitku.repository.*;
import com.sawitku.util.AnalisaCalculator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class PanenService {

    private final PanenRepository panenRepository;
    private final LahanRepository lahanRepository;
    private final AnalisaRepository analisaRepository;
    private final ClaudeService claudeService;
    private final ObjectMapper objectMapper;

    @Transactional
    public PanenResponse inputPanen(Long userId, Long lahanId, PanenRequest req) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));

        if (panenRepository.existsByLahanIdAndTahunAndBulanAngka(lahanId, req.getTahun(), req.getBulanAngka()))
            throw new BusinessException("Data panen " + req.getBulan() + " " + req.getTahun() + " sudah ada", "DUPLICATE_PANEN");

        var target = AnalisaCalculator.getTarget(lahan.getLuasHa().doubleValue(), lahan.getUsiaPohon());
        BigDecimal persen = AnalisaCalculator.hitungPersenKurang(req.getTonAktual(), target.mid());
        StatusPanen status = AnalisaCalculator.getStatus(req.getTonAktual(), target.min(), target.mid());

        Panen panen = Panen.builder()
            .lahan(lahan).bulan(req.getBulan()).tahun(req.getTahun()).bulanAngka(req.getBulanAngka())
            .tonAktual(req.getTonAktual()).targetMin(target.min()).targetMax(target.max()).targetMid(target.mid())
            .statusPanen(status).persenKurang(persen)
            .hargaPerTon(req.getHargaPerTon() != null ? req.getHargaPerTon() : BigDecimal.valueOf(2400000))
            .catatan(req.getCatatan()).createdAt(LocalDateTime.now()).build();
        panenRepository.save(panen);

        claudeService.analyzePanen(panen, lahan);

        return toResponse(panen, lahan.getNamaLahan(), null);
    }

    public List<PanenResponse> getRiwayat(Long userId, Long lahanId, int limit) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        return panenRepository.findByLahanIdOrderByTahunDescBulanAngkaDesc(lahanId, PageRequest.of(0, limit))
            .stream().map(p -> toResponse(p, null, getAnalisa(p))).toList();
    }

    public PanenResponse getPanenDetail(Long userId, Long lahanId, Long panenId) {
        Lahan lahan = lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));
        return toResponse(panen, lahan.getNamaLahan(), getAnalisa(panen));
    }

    public AnalisaResponse getAnalisaByPanen(Long userId, Long lahanId, Long panenId) {
        lahanRepository.findByIdAndUserId(lahanId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Lahan tidak ditemukan"));
        Panen panen = panenRepository.findByIdAndLahanId(panenId, lahanId)
            .orElseThrow(() -> new ResourceNotFoundException("Data panen tidak ditemukan"));
        AnalisaResponse analisa = getAnalisa(panen);
        if (analisa == null) return AnalisaResponse.builder().status("PROCESSING").build();
        return analisa;
    }

    private AnalisaResponse getAnalisa(Panen panen) {
        return analisaRepository.findByPanenId(panen.getId()).map(a -> {
            try {
                List<AnalisaResponse.PenyebabItem> items = objectMapper.readValue(
                    a.getPenyebabJson(), new TypeReference<>() {});
                return AnalisaResponse.builder()
                    .id(a.getId()).status("DONE").penyebab(items)
                    .ringkasan(null).prioritasTindakan(a.getRekomendasi())
                    .createdAt(a.getCreatedAt()).build();
            } catch (Exception e) { return null; }
        }).orElse(null);
    }

    private PanenResponse toResponse(Panen p, String namaLahan, AnalisaResponse analisa) {
        return PanenResponse.builder()
            .id(p.getId()).lahanId(p.getLahan().getId()).namaLahan(namaLahan)
            .bulan(p.getBulan()).tahun(p.getTahun()).bulanAngka(p.getBulanAngka())
            .tonAktual(p.getTonAktual()).targetMin(p.getTargetMin())
            .targetMax(p.getTargetMax()).targetMid(p.getTargetMid())
            .statusPanen(p.getStatusPanen().name()).persenKurang(p.getPersenKurang())
            .hargaPerTon(p.getHargaPerTon())
            .nilaiEstimasi(p.getTonAktual().multiply(p.getHargaPerTon()))
            .catatan(p.getCatatan()).createdAt(p.getCreatedAt()).analisa(analisa).build();
    }
}
```

- [ ] **Step 2: Create PanenController.java**

```java
package com.sawitku.controller;

import com.sawitku.dto.request.PanenRequest;
import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.service.PanenService;
import com.sawitku.util.ResponseUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/lahan/{lahanId}/panen")
@RequiredArgsConstructor
public class PanenController {

    private final PanenService panenService;

    @PostMapping
    public ResponseEntity<ApiResponse<PanenResponse>> input(@AuthenticationPrincipal User user,
                                                             @PathVariable Long lahanId,
                                                             @Valid @RequestBody PanenRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ResponseUtil.ok(panenService.inputPanen(user.getId(), lahanId, req), "Panen berhasil dicatat").getBody());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PanenResponse>>> getRiwayat(@AuthenticationPrincipal User user,
                                                                         @PathVariable Long lahanId,
                                                                         @RequestParam(defaultValue = "7") int limit) {
        return ResponseUtil.ok(panenService.getRiwayat(user.getId(), lahanId, limit));
    }

    @GetMapping("/{panenId}")
    public ResponseEntity<ApiResponse<PanenResponse>> getDetail(@AuthenticationPrincipal User user,
                                                                  @PathVariable Long lahanId,
                                                                  @PathVariable Long panenId) {
        return ResponseUtil.ok(panenService.getPanenDetail(user.getId(), lahanId, panenId));
    }

    @GetMapping("/{panenId}/analisa")
    public ResponseEntity<ApiResponse<AnalisaResponse>> getAnalisa(@AuthenticationPrincipal User user,
                                                                     @PathVariable Long lahanId,
                                                                     @PathVariable Long panenId) {
        return ResponseUtil.ok(panenService.getAnalisaByPanen(user.getId(), lahanId, panenId));
    }
}
```

- [ ] **Step 3: Create BerandaController.java**

```java
package com.sawitku.controller;

import com.sawitku.dto.response.*;
import com.sawitku.entity.User;
import com.sawitku.service.LahanService;
import com.sawitku.util.ResponseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/beranda")
@RequiredArgsConstructor
public class BerandaController {

    private final LahanService lahanService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getBeranda(@AuthenticationPrincipal User user) {
        List<LahanResponse> lahans = lahanService.getMyLahan(user.getId());
        long normal = lahans.stream().filter(l -> l.getPanenTerakhir() != null && "NORMAL".equals(l.getStatusTerkini())).count();
        long bermasalah = lahans.stream().filter(l -> l.getPanenTerakhir() != null && !"NORMAL".equals(l.getStatusTerkini())).count();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("totalLahan", lahans.size());
        data.put("lahanNormal", normal);
        data.put("lahanBermasalah", bermasalah);
        data.put("lahan", lahans);
        return ResponseUtil.ok(data);
    }
}
```

- [ ] **Step 4: Full compile dan run**

```bash
cd /d/sawit_app/backend
mvn spring-boot:run
```

Test endpoint panen:
```bash
# Ambil token dulu
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@sawitku.id","password":"password123"}' | python -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")

# Buat lahan
curl -s -X POST http://localhost:8080/api/lahan \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"namaLahan":"Lahan A","luasHa":2.0,"usiaPohon":8,"lokasi":"Padang Pariaman"}' | python -m json.tool
```

Expected: lahan berhasil dibuat dengan response JSON lengkap.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/sawitku/service/PanenService.java
git add backend/src/main/java/com/sawitku/controller/
git commit -m "feat: add panen endpoints and beranda summary"
```

---

## Task 14: Integration Tests

**Files:**
- Create: `src/test/java/com/sawitku/integration/AuthIntegrationTest.java`
- Create: `src/test/java/com/sawitku/integration/LahanIntegrationTest.java`
- Modify: `src/test/resources/application-test.yml`

- [ ] **Step 1: Create application-test.yml**

```yaml
spring:
  datasource:
    url: jdbc:tc:postgresql:16:///sawitku_test
    driver-class-name: org.testcontainers.jdbc.ContainerDatabaseDriver
  jpa:
    hibernate:
      ddl-auto: validate
  flyway:
    enabled: true
  data:
    redis:
      host: localhost
      port: 6379
jwt:
  secret: test-secret-key-minimum-256-bits-for-testing-purposes-only
  expiration: 86400000
claude:
  api-key: test-key
```

- [ ] **Step 2: Create AuthIntegrationTest.java**

```java
package com.sawitku.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Testcontainers;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers
class AuthIntegrationTest {

    @Autowired MockMvc mvc;

    @Test
    void register_sukses() throws Exception {
        mvc.perform(post("/api/auth/register")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"name":"Petani Test","email":"petani@test.id","password":"password123"}
                """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.token").isNotEmpty());
    }

    @Test
    void register_emailDuplikat_gagal() throws Exception {
        String body = """{"name":"A","email":"dup@test.id","password":"pass123"}""";
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(body));
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("EMAIL_EXISTS"));
    }

    @Test
    void login_sukses() throws Exception {
        mvc.perform(post("/api/auth/register")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""{"name":"Login Test","email":"login@test.id","password":"password123"}"""));

        mvc.perform(post("/api/auth/login")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""{"email":"login@test.id","password":"password123"}"""))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.token").isNotEmpty());
    }
}
```

- [ ] **Step 3: Run integration tests**

```bash
cd /d/sawit_app/backend
mvn test -Dtest=AuthIntegrationTest -q
```

Expected: 3 tests passed (memerlukan Docker untuk Testcontainers)

- [ ] **Step 4: Commit**

```bash
git add backend/src/test/
git commit -m "test: add auth integration tests with Testcontainers"
```

---

## Task 15: Dockerfile & Production Config

**Files:**
- Create: `backend/Dockerfile`
- Create: `docker-compose.prod.yml`
- Create: `nginx/nginx.conf`
- Create: `.env.prod.example`

- [ ] **Step 1: Create backend/Dockerfile**

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --quiet --tries=1 http://localhost:8080/actuator/health -O /dev/null || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- [ ] **Step 2: Create docker-compose.prod.yml**

```yaml
services:
  app:
    build: ./backend
    env_file: .env.prod
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped
    expose:
      - "8080"

  postgres:
    image: postgres:16-alpine
    env_file: .env.prod
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $POSTGRES_USER"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
```

- [ ] **Step 3: Create nginx/nginx.conf**

```nginx
events { worker_connections 1024; }

http {
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    gzip on;
    gzip_types application/json text/plain;

    upstream backend { server app:8080; }

    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name api.sawitku.id;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";

        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

- [ ] **Step 4: Create .env.prod.example**

```env
# Database
DB_URL=jdbc:postgresql://postgres:5432/sawitku_db
DB_USERNAME=sawitku_user
DB_PASSWORD=GANTI_PASSWORD_KUAT_DISINI

# PostgreSQL container
POSTGRES_DB=sawitku_db
POSTGRES_USER=sawitku_user
POSTGRES_PASSWORD=GANTI_PASSWORD_KUAT_DISINI

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# JWT — generate dengan: openssl rand -base64 64
JWT_SECRET=GANTI_DENGAN_STRING_RANDOM_MINIMAL_64_KARAKTER

# Claude AI
CLAUDE_API_KEY=sk-ant-XXXXX
```

- [ ] **Step 5: Test production build**

```bash
cd /d/sawit_app
docker-compose -f docker-compose.prod.yml build app
```

Expected: image berhasil build (beberapa menit)

- [ ] **Step 6: Final commit**

```bash
git add backend/Dockerfile docker-compose.prod.yml nginx/ .env.prod.example
git commit -m "feat: add Dockerfile and production docker-compose with nginx"
```

---

## Checklist Backend Complete

- [ ] Docker dev (postgres + redis) berjalan
- [ ] Flyway migration V1 applied
- [ ] POST /api/auth/register berhasil
- [ ] POST /api/auth/login berhasil + return JWT
- [ ] GET /api/lahan dengan JWT berhasil
- [ ] POST /api/lahan buat lahan baru
- [ ] POST /api/lahan/{id}/panen input panen + trigger AI async
- [ ] GET /api/lahan/{id}/panen/{id}/analisa return hasil atau PROCESSING
- [ ] GET /api/beranda return summary
- [ ] Integration tests pass
- [ ] Production Dockerfile build success
