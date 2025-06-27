# Remeetner - Arquitectura Escalable

## Estructura del Proyecto

La aplicación ha sido refactorizada siguiendo las mejores prácticas de Apple para crear una arquitectura escalable, mantenible y testeable.

### Arquitectura General

```
AppDelegate (Punto de entrada)
    ↓
AppCoordinator (Coordinador principal)
    ↓
Managers (Gestión de funcionalidades específicas)
    ├── WindowManager (Ventanas)
    ├── MenuBarManager (Menu bar)
    ├── BreakManager (Descansos)
    ├── EventScheduler (Eventos del calendario)
    └── AudioManager (Sonidos)
```

## Componentes Principales

### 1. AppCoordinator
- **Responsabilidad**: Coordinación principal de la aplicación
- **Patrón**: Coordinator Pattern
- **Ubicación**: `Coordinators/AppCoordinator.swift`

### 2. Managers

#### WindowManager
- **Responsabilidad**: Gestión de todas las ventanas (overlay, settings, events)
- **Patrón**: Singleton + Window Management
- **Ubicación**: `Managers/WindowManager.swift`

#### MenuBarManager
- **Responsabilidad**: Gestión del status item y menu bar
- **Patrón**: Delegate Pattern
- **Ubicación**: `Managers/MenuBarManager.swift`

#### BreakManager
- **Responsabilidad**: Gestión de descansos y timers
- **Ubicación**: `Managers/BreakManager.swift`

#### EventScheduler
- **Responsabilidad**: Programación y seguimiento de eventos del calendario
- **Ubicación**: `Managers/EventScheduler.swift`

#### AudioManager
- **Responsabilidad**: Gestión de sonidos de la aplicación
- **Ubicación**: `Managers/BreakManager.swift`

### 3. Utilities

#### DateParser
- **Responsabilidad**: Parsing de fechas con múltiples formatos
- **Ubicación**: `Utils/DateParser.swift`

#### Logger
- **Responsabilidad**: Sistema de logging centralizado
- **Ubicación**: `Utils/Logger.swift`

#### AppConfiguration
- **Responsabilidad**: Configuración centralizada de la aplicación
- **Ubicación**: `Utils/AppConfiguration.swift`

#### RemeetnerError
- **Responsabilidad**: Manejo de errores específicos de la aplicación
- **Ubicación**: `Utils/RemeetnerError.swift`

#### Protocols
- **Responsabilidad**: Protocolos para mejorar testabilidad
- **Ubicación**: `Utils/Protocols.swift`

## Principios de Diseño Aplicados

### 1. Single Responsibility Principle (SRP)
- Cada clase tiene una responsabilidad específica y bien definida
- Los managers se encargan de una funcionalidad específica

### 2. Dependency Injection
- Los objetos reciben sus dependencias a través del constructor
- Facilita testing y reduce acoplamiento

### 3. Protocol-Oriented Programming
- Uso extensivo de protocolos para definir contratos
- Mejora la testabilidad y permite mocking

### 4. Coordinator Pattern
- Separación de la lógica de navegación
- Control centralizado del flujo de la aplicación

### 5. Observer Pattern
- Uso de Combine para comunicación reactiva
- Publishers y subscribers para actualizaciones de estado

## Beneficios de la Nueva Arquitectura

### 1. Escalabilidad
- Fácil agregar nuevas funcionalidades
- Estructura modular y organizada

### 2. Mantenibilidad
- Código más legible y organizado
- Responsabilidades claramente separadas

### 3. Testabilidad
- Protocolos permiten mocking
- Dependency injection facilita unit testing
- Managers pueden ser testeados independientemente

### 4. Configurabilidad
- Configuración centralizada en `AppConfiguration`
- Fácil cambiar valores sin buscar en todo el código

### 5. Debugging
- Sistema de logging centralizado
- Diferentes niveles de log según el entorno

## Flujo de Datos

```
GoogleOAuthManager → EventScheduler → BreakManager → WindowManager
                ↓                  ↓              ↓
            EventStore      StatusModel    OverlayView
```

## Testing Strategy

### Unit Tests
- Cada manager puede ser testeado independientemente
- Uso de protocolos para mocking de dependencias

### Integration Tests
- Testing del flujo completo de eventos
- Verificación de la comunicación entre managers

### UI Tests
- Testing de las ventanas y overlays
- Verificación de la experiencia de usuario

## Extensibilidad

### Agregar Nuevas Funcionalidades
1. Crear un nuevo manager en `Managers/`
2. Definir un protocolo en `Protocols.swift`
3. Registrar en `AppCoordinator`
4. Configurar dependencias

### Agregar Nuevas Configuraciones
1. Agregar en `AppConfiguration.swift`
2. Usar desde los managers correspondientes

### Agregar Nuevo Logging
1. Usar `Logger.shared` con el nivel apropiado
2. Configurar nivel de log en `Environment`

## Mejores Prácticas Aplicadas

1. **Immutable Data**: Uso de `let` donde sea posible
2. **Memory Management**: Uso de `weak self` en closures
3. **Error Handling**: Errores tipados con `RemeetnerError`
4. **Resource Management**: Timer cleanup y window management
5. **SwiftUI Integration**: Proper use of `@Published` y `ObservableObject`

## Futuras Mejoras

1. **Core Data**: Para persistencia de datos
2. **CloudKit**: Para sincronización entre dispositivos
3. **Notification Center**: Para comunicación entre componentes
4. **Background Processing**: Para mejor gestión de timers
5. **Testing Framework**: Setup completo de unit y integration tests
