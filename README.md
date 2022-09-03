# Spring pragmático

> Pragmático es un término de origen griego "pragmatikus" y latín "pragmaticu", que significa ser “práctico.”



El proyecto usa Gradle 7.5 con Kotlin DSL, es probable que tarde en descargar lo necesario dependiendo de la velocidad de tu internet, y en indexarse dependiendo de la velocidad de tu computadora.

## Requerimientos

- Docker
- Java 8 & 18
- MySQL 8
- IntelliJ
- Cliente SQL

Requerimientos mínimos (Omitiendo NoSQL)

- Java 18
- MySQL 8
- Cliente SQL

https://aws.amazon.com/corretto/?filtered-posts.sort-by=item.additionalFields.createdDate&filtered-posts.sort-order=desc

## MySQL

Dependencia:

```kotlin
runtimeOnly("mysql:mysql-connector-java")
```

Agrega el siguiente código a `application.yml` para configurar la conexión a MySQL.

El script se encuentra en la carpeta sql.

```yaml
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1:3306/database_name
    username: root
    password:
```

Reemplaza `database_name` por el nombre de tu base de datos.

Error relacionado:

```yaml
Failed to configure a DataSource: 'url' attribute is not specified and no embedded datasource could be configured.
```


**Tip:** Ejecuta la aplicación para asegurar que se conecta a MySQL

## JOOQ

Dependencia:

```kotlin
implementation("org.springframework.boot:spring-boot-starter-jooq")
```

Para generar el "mappeo" de tu base de datos es necesario que especifiques las variables de entorno ó bien en el archivo **build.gradle.kts** cambia los valores por tus credenciales de MySQL

```kotlin
 val DB_NAME = System.getenv("DB_NAME") ?: "spring"
 val DB_USER = System.getenv("DB_USER") ?: "root"
 val DB_PASS = System.getenv("DB_PASS") ?: ""
```

Comandos relacionado:

```shell
export DB_NAME=spring
```

```shell
gradle generateJooq
```

**Hint:**

```shell
DB_NAME=spring DB_USER=root gradle generateJooq
```

### Script de Gradle

Plugin

```kotlin
id("nu.studer.jooq") version "7.1.1"
```

Dependencias

```kotlin
jooqGenerator("mysql:mysql-connector-java:8.0.30")
jooqGenerator("jakarta.xml.bind:jakarta.xml.bind-api:4.0.0")
```

Configuración

```kotlin
jooq {
    version.set("3.17.3")
    edition.set(nu.studer.gradle.jooq.JooqEdition.OSS)

    configurations {

        val DB_NAME = System.getenv("DB_NAME") ?: "spring"
        val DB_USER = System.getenv("DB_USER") ?: "root"
        val DB_PASS = System.getenv("DB_PASS") ?: ""

        create("main") {
            generateSchemaSourceOnCompilation.set(true)

            jooqConfiguration.apply {
                logging = org.jooq.meta.jaxb.Logging.WARN

                jdbc.apply {
                    driver = "com.mysql.cj.jdbc.Driver"
                    url = "jdbc:mysql://127.0.0.1:3306/$DB_NAME"
                    user = DB_USER
                    password = DB_PASS
                }

                generator.apply {
                    name = "org.jooq.codegen.DefaultGenerator"
                    strategy.name = "org.jooq.codegen.DefaultGeneratorStrategy"

                    database.apply {
                        inputSchema = DB_NAME
                    }

                    generate.apply {
                        isJavaTimeTypes = true
                        isPojos = true
                    }

                    target.apply {
                        packageName = "com.ezpc.mysql"
                    }
                }
            }
        }
    }
```

## DynamoDB

**Documentación:** https://docs.aws.amazon.com/es_es/amazondynamodb/latest/developerguide/DynamoDBMapper.CRUDExample1.html

```kotlin
    implementation("software.amazon.awssdk:dynamodb:2.17.261")
    implementation("com.amazonaws:aws-java-sdk-core:1.12.290")
    implementation("com.amazonaws:aws-java-sdk-dynamodb:1.12.290")
```

Configuración en spring

```java
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;

@Configuration
public class DynamoDBConfig {

    @Bean
    public AmazonDynamoDB amazonDynamoDB() {
        return AmazonDynamoDBClientBuilder.standard()
                .withEndpointConfiguration(new AwsClientBuilder
                        .EndpointConfiguration("http://localhost:8000/", Region.US_WEST_1.toString()))
                .build();
    }

    @Bean
    public DynamoDBMapper dynamoDBMapper(AmazonDynamoDB client) {
        return new DynamoDBMapper(client);
    }
}

```

> **NOTA:** No es necesario el usuario y contraseña cuando se esta utilizando en modo local.

### Local

**Requerimiento:** Java 8

Descarga el Jar: https://s3.us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.zip

```shell
export JAVA_HOME=path/to/java8
```

Asegura que se aplique el cambio, debe especificar que la versión es java 8

```shell
java -version
```

Si todo esta correcto debería imprimir algo similar a esto:

```shell
penJDK Runtime Environment Corretto-8.322.06.1 (build 1.8.0_322-b06)
OpenJDK 64-Bit Server VM Corretto-8.322.06.1 (build 25.322-b06, mixed mode)
```

```shell
java -jar DynamoDBLocal.jar -sharedDb -dbPath ./data
```

ó

```shell
java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb
```

**Tip:** Para diseñar tablas, realizar operaciones o ver la información podemos utilizar el NoSQL Workbench
https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/workbench.settingup.html

### Docker

**Requerimientos:** docker & docker-compose

`dynamodb-compose.yml`

```yaml
version: '3.8'
services:
  dynamodb-local:
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```

```
docker-compose -f dynamodb-compose.yaml up -d
```

## Tests

La siguiente configuración es requerida para que Spring boot configure el entorno para poder realizar las pruebas.

Java

```java
@ExtendWith(SpringExtension.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class Tests {
//tus tests
}
```

Kotlin

```kotlin
@ExtendWith(SpringExtension::class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class Tests {
//Tus tests
}
```

TestRestTemplate

con el testRestTemplate realizaremos las peticiones a nuestra aplicación cuando estemos creando las pruebas.

```java
@Autowired
private TestRestTemplate testRestTemplate;
```

```java
ResponseEntity<T> response = testRestTemplate.exchange(uri, HttpMethod.GET, new HttpEntity<>(body, headers), responseType);
```

> Donde T es tipo responseType

```java
    public static <T> ResponseEntity<T> handleBody(String uri, Object body, HttpMethod method, Class<T> responseType) {

        try {
            System.out.println(method + " {{host}}" + uri);
            System.out.println("Content-Type: application/json");
            System.out.println();
            System.out.println(new ObjectMapper().writeValueAsString(body));
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

        return testRestTemplate.exchange(uri, method, new HttpEntity<>(body, headers), responseType);
    }
```

> Cuando se llame el método se imprimirá su equivalente usando el estándar RFC 2616

### JUnit

La versión que se debe usar de JUnit es la 5 (Jupiter).

Habilita las anotaciones @Order(n)

resources / `junit-platform.properties`

```properties
junit.jupiter.testmethod.order.default = \
    org.junit.jupiter.api.MethodOrderer$OrderAnnotation
junit.jupiter.testclass.order.default = \
    org.junit.jupiter.api.ClassOrderer$OrderAnnotation
junit.jupiter.testinstance.lifecycle.default = per_class

```


## Spring

### Auto configuración

La magia de spring, con spring puedes agregar nuevas *features* y spring se hace cargo del resto. no tienes que programar absolutamente nada, y todo lo configuras desde un mismo lugar.

Cuando registras un nuevo controller, no tienes que hacer circo maroma y teatro para agrupar rutas (Controller) como en otros frameworks.

 ```swift
 app.group("users") { users in
    // GET /users
    users.get { req in
        ...
    }
    // POST /users
    users.post { req in
        ...
    }
    // GET /users/:id
    users.get(":id") { req in
        let id = req.parameters.get("id")!
        ...
    }
}
 ```

Simplemente crea una clase, anótala correctamente y listo, no hay de necesidad de especificarle a spring que agregaste un nuevo controller.

 ```java
 @RestController
 @RequestMapping("/controller")
 class Controller {
 
 @GetMapping("/hello")
  String hello(){ 
	  return "That's all folks"
  }
 }
 ```

Ejemplo: Ya tienes tu aplicación pero quieres monitorear tu aplicación para ver si rendimiento.

Solo agrega esto

 ```java
  implementation("org.springframework.boot:spring-boot-starter-actuator")
  runtimeOnly("io.micrometer:micrometer-registry-prometheus")
 ```

y automáticamente se expondrá un endpoint con toda la información que necesitas.

```http
/actuator/prometheus
```


### OpenAPI

Quieres documentar tu aplicación con OpenAPI?

 ```java
 implementation("org.springdoc:springdoc-openapi-ui:1.6.11")
 ```

 ```http
 http://localhost:8080/v3/api-docs/
 ```

Te mostrará un JSON, copia ese json y pégalo aquí:

```
https://editor.swagger.io/
```

También lo puedes ver en IntelliJ

### Endpoints

```java
@ + HttpMethod + 'Mapping'
```

- @GetMapping
- @PatchMapping
- @PostMapping
- @PutMapping
- @DeleteMapping

```java
@GetMapping("/path")
```

```java
@GetMapping("/path/{pathVariable}")
```

```java
@GetMapping({"/path1","/path2"})
```


### Endpoint

```java
@PostMapping("/hello")
public String postExample(@RequestBody String message){
	return message
}
```

### PathVariables

```
/hello/snow
```

```java
@GetMapping("/hello/{name}")
public String postExample(@PathVariable("name") String message){
	return message;
}
```

### RequestParams A.K.A QueryParams

Generalmente se utilizan como filtros, y van especificados después del símbolo `?`

```
GET /usuarios
GET /usuarios?rol=admin
```

Los RequestParam son obligatorios por defecto

```java
@PostMapping("/hello")
public String postExample(@RequestParam("name") String name){
	return name;
}
```

```
/hello?name=snow
```

RequestParam no obligatorio

```java
@RequestParam(value = "name", required = false)
```

RequestParam no obligatorio con valor por defecto

```java
@RequestParam(value = "name",defaultValue = "hola", required = false)
```

`/hello` imprimirá `hola` ya que se tomará un valor por defecto.

### Headers

Acceder a todos los headers

```java
public String headersExample(@RequestHeader HttpHeaders headers)
```

Solo un header

```java
@RequestHeader("Authorization") String contentLength
```

### Excepciones

Generalmente queremos utilizar excepciones para expresar que a ocurrido un error o un evento excepcional.

Ejemplo:

```java
if(request.isNotValid()){
 throw new IllegalArgumentException("Not a valid request");
}
```

Pero al momento de utilizarla, nos damos cuenta que el resultado de esta acción es un 500.

Solución

```java
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ControllerAdvice;
```

```java

@ControllerAdvice
public class EntityExceptionHandler extends ResponseEntityExceptionHandler {
@ExceptionHandler({Exception.class})
    protected ResponseEntity<Object> handleConflict(@NotNull RuntimeException ex, WebRequest request) {
    //Tu código
    }
}
```

Así que probablemente quieras hacer esto:

```java
if(ex instanceOf BadRequestException badRequest){
	return ResponseEntity.status(HttpStatus.BAD_REQUEST)
	.body(badRequest.getMessage())
}
```

Para una excepción en específico

```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
public class EntityExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<String> handleNotFound(RuntimeException ex, WebRequest request) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ex.getMessage());
    }
}

```


**PRO TIP:** Esta es una excelente solución para ocultar excepciones del cliente final que puedan mostrar información que no queramos.

- org.springframework.jdbc.BadSqlGrammarException
- SQLSyntaxErrorException
- org.springframework.dao*Exception

### CORS

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableWebMvc
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**");
    }
}

```


### Actuator & Prometheus

Requerimiento: Docker

```kotlin
implementation("org.springframework.boot:spring-boot-starter-actuator")
implementation("io.micrometer:micrometer-registry-prometheus")
```

`application.yaml`

```yaml
management:
  metrics:
    tags:
      application: ${spring.application.name}
  endpoints:
    web:
      exposure:
        include: "*"
      cors:
        allowed-origins: "*"
        allowed-methods: "*"
```

`prometheus.yml`

```yml
global:
  scrape_interval:  15s

scrape_configs:
  - job_name: prometheus
    scrape_interval: 15s
    scrape_timeout: 15s
    metrics_path: /metrics
    static_configs:
    - targets:
      - localhost:9090
  - job_name: 'spring'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['192.168.68.120:8080']
```

La IP es el host:

```
ipconfig getifaddr en0
```

Crea un container de prometheus

```shell
docker run \
    -p 9090:9090 \
    -v /Users/snow/Desktop/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
```

y entramos a la siguiente URL para verificar que funcionó

```
http://localhost:9090/targets
```

Si todo funcionó todos los targets estarán "up"

Ahora podremos dirigirnos a consultar la información del uso del CPU

```
http://localhost:9090/graph
```

```
process_cpu_usage{}
```

### @Autowired

## Diseño

Las siguientes reglas pueden variar dependiendo de la empresa dónde estes trabajando, lo importante es que en todos los servicios se comporten de la misma manera.

Basado en mi experiencia y en el libro *REST API Design Rulebook de Mark Massé*

### Códigos de respuesta

- 2xx Indica que la petición fue exitosa
- 3xx Indica que redirecciónes
- 4xx Indica problemas del lado del cliente
- 5xx Indica problemas del lado del servidor

| Código | Nombre | Uso |
|:--|:--|:--|
| 200 | OK | Indicamos que la acción fue exitosa |
| 201 | Created | Indicamos que el recurso fue creado|
| 204 | No Content | Indicamos que la respuesta es **intencionalmente** vacía|
| 400 | Bad Request | Indicamos que la petición es incorrecta |
| 401 | Unauthorized | Indicamos que hay un problema con las credenciales del cliente|
| 403 | Forbidden | Indicamos que no tiene acceso|
| 404 | NotFound | Indicamos que la URI no puede ser "mappeada" a un recurso|
| 409 | Conflict | Indicamos que hay un conflicto con la petición|
| 500 | Internal Server Error | Indicamos que hubo un error en el servidor|

**Tip:** Si al momento de realizar tu consulta obtienes un código **405 Method Not Allowed** posiblemente te equivocaste de método HTTP.

### Metodos HTTP


**PRO TIP:** Sigue las siguientes reglas para tu aplicación.

No deben contener body:

- GET
- DELETE

> Aunque DELETE puede contener `request body`, algunas plataformas y clientes http no lo permiten.

Pueden contener body:

- POST
- PUT
- PATCH

#### GET

Es utilizado para obtener información, puede o no contener una respuesta con body.

#### PUT

Debe ser utilizado para crear **201** y editar/remplazar **200**

#### POST

Utilizado para llamar funciones ejem: `POST /alerts/245743/resend`

### DELETE

Remueve un recurso, no debe llevar un `Request Body`, para los casos donde debas eliminar varias entidades en una sola petición, deberías utilizar **POST**

## JSON Jackson

### Nulls

Muchas veces no es necesario serializar los valores nulos.

```json
{
	"name": "snow",
	"realName" : null
}
```

```json
{
	"name": "snow"
}
```


```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SomeDto {
//code
}
```

ó globalmente

```java
mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL)
```

y en spring:

```java
@Configuration
public class ObjectMapperConfiguration {

	@Autowired
	public void configure(ObjectMapper mapper){
		mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL)
	}
}
```

## JAVA

### Nulls

Si tienes problemas con los NullPointerException y estas utilizando alguna versión de IntelliJ puedes hacer lo siguiente:

Agrega la siguiente dependencia

```kotlin
compileOnly("org.jetbrains:annotations:23.0.0")
```

Ahora anota las variables que no pueden ser nulas


```java
public void example(@NotNull String value)
```

Cuando llames la función `example(null)` el IDE te marcará una advertencia visual mostrando que el parámetro no puede ser nulo.

También puedes marcar que valores pueden ser nulos.

```java
public @Nullable String example(@Nullable String value)
```

Si crees que ya es mucho código verbose, puedes utilizar Kotlin :)
