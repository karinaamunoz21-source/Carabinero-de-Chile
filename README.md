# Carabineros de Chile - Mapa Estilo Pandilla (Roblox Studio)

Juego de roleplay estilo pandilla para Roblox Studio con sistemas completos de policía, criminales, robos, tiendas y más.

## Características Principales

### Equipos
- **Policía (PD)** - Taser, Esposas, patrullaje
- **SWAT** - Colt M4, HK MP5, Francotirador, Ariete, Camión Blindado (requiere GamePass)
- **Civil** - Vida normal, trabajo, compras
- **Criminal** - Robos, luteo, mercado negro

### Mapa
- **2 Bases de Pandilla** con interior (casillero, bolso de ropa, puerta vinculada a grupo de Roblox)
- **Departamento de Policía** con armería y escritorios
- **Prisión** con 3 celdas y sistema de escape
- **8 Tiendas** con iconos flotantes

### Tiendas (con iconos flotantes)
| Tienda | Descripción |
|--------|-------------|
| Tienda de Ropa | Camisetas, chaquetas, hoodies |
| Tienda de Zapatos | Zapatillas, botas, jordans |
| Tienda de Pantalón | Jeans, cargo, SWAT |
| Tienda de Accesorios | Gorras, lentes, cadenas |
| Joyería | Robable - Loot aleatorio (relojes, cadenas) |
| Banco | Robable - Requiere C4 ($500,000) |
| Mercado Negro | Bolso de robo, C4, lockpick |
| Tienda de Tatuajes | Tatuajes para cara y manos |

### Sistema de Robos
- **Joyería** - Loot aleatorio (Reloj de Oro, Reloj de Diamante, Cadena de Oro, Cadena de Platino)
- **Banco** - Requiere C4 del mercado negro, recompensa $500,000
- **Camión Blindado** - Aparece cada hora, recompensa $1,000,000
- Notificación automática al chat privado de policías cuando alguien roba

### Sistema de Bolso
- Capacidad base: 5 items
- Expandible a 20 con GamePass "Expandir Bolso"
- Tecla **B** para abrir el bolso
- Vender contenido por dinero

### Sistema de Luteo
- Requiere GamePass "Luteo"
- Lutear jugadores eliminados (50% de su dinero + items del bolso)
- Cooldown de 30 segundos

### Armas
| Equipo | Armas |
|--------|-------|
| PD | Pistola Taser, Esposas |
| SWAT | Colt M4, HK MP5, Rifle Francotirador, Ariete |
| Criminal | C4 Explosivo (mercado negro) |
| /sg (GamePass) | Golden Gun, Revólver Tambor, ARP Christmas |

### Comandos por Chat

#### Spawn Commands (requiere GamePass Generar Armas)
```
/sg golden        - Golden Gun
/sg tambor        - Revólver Tambor
/sg arp christmas - ARP Christmas
```

#### SWAT
```
spawn swat   - Generar camión blindado SWAT (requiere GamePass SWAT)
join swat    - Unirse al equipo SWAT (requiere GamePass SWAT)
```

#### Comandos de Moderador (rango Moderador en grupo)
```
/fly [ID]              - Activar vuelo
/unfly [ID]            - Desactivar vuelo
/nuke [ID]             - Nuke en jugador
/h [mensaje]           - Anuncio global
/timer [segundos]      - Temporizador global
/ban [ID] [razón]      - Banear jugador
/unban [ID]            - Desbanear jugador
/kick [ID] [razón]     - Kickear jugador
```

#### Comandos Admin Abuse (solo Owner/Co-Owner)
```
/god [ID]              - Inmortalidad
/ungod [ID]            - Quitar inmortalidad
/kill [ID]             - Eliminar jugador
/tp [ID]               - Teletransportarse a jugador
/bring [ID]            - Traer jugador
/speed [ID] [valor]    - Cambiar velocidad
/jump [ID] [valor]     - Cambiar salto
/respawn [ID]          - Respawnear jugador
/freeze [ID]           - Congelar jugador
/unfreeze [ID]         - Descongelar jugador
```

### GamePasses
| Pase | Función |
|------|---------|
| Luteo | Permite lutear jugadores eliminados |
| Expandir Bolso | Expande bolso de 5 a 20 items |
| SWAT | Acceso al equipo SWAT y camión blindado |
| Barra | Comandos especiales de barra |
| Generar Armas | Acceso a /sg (spawn gun) |
| Servidor Privado | Servidor privado mensual (100 Robux/mes) |

### Servidor Privado
- Costo mensual: 100 Robux
- Límite: 20 jugadores
- Renovación automática requerida cada mes

---

## Instalación en Roblox Studio

### Método 1: Rojo (Recomendado)

1. Instalar [Rojo](https://rojo.space/)

2. Clonar este repositorio:
   ```bash
   git clone https://github.com/karinaamunoz21-source/Carabinero-de-Chile.git
   ```

3. Iniciar el servidor Rojo:
   ```bash
   cd Carabinero-de-Chile
   rojo serve
   ```

4. En Roblox Studio, instalar el plugin de Rojo y conectarse al servidor.

### Método 2: Manual (Copiar y Pegar)

1. Abre Roblox Studio y crea un nuevo lugar.

2. **ReplicatedStorage** - Crear ModuleScripts:
   - `GameConfig` - Copiar contenido de `src/ReplicatedStorage/GameConfig.lua`
   - `RemoteEvents` - Copiar contenido de `src/ReplicatedStorage/RemoteEvents.lua`
   - `DataManager` - Copiar contenido de `src/ReplicatedStorage/DataManager.lua`

3. **ServerScriptService** - Crear Scripts (servidor):
   - Copiar cada archivo `.server.lua` de `src/ServerScriptService/`

4. **StarterGui** - Crear LocalScripts (cliente):
   - Copiar cada archivo `.client.lua` de `src/StarterGui/`

---

## Configuración Requerida

### 1. ID del Grupo de Roblox
En `src/ReplicatedStorage/GameConfig.lua`, cambiar:
```lua
GameConfig.GROUP_ID = 0 -- Cambia por tu ID de grupo
```

### 2. IDs de GamePasses
Crear los GamePasses en la página de tu juego en Roblox y actualizar los IDs en GameConfig.

### 3. Rangos del Grupo
Configurar los rangos de tu grupo de Roblox en GameConfig.Ranks.

### 4. Iconos de Tiendas
Subir iconos personalizados a Roblox y actualizar los `rbxassetid://` en GameConfig.

---

## Estructura del Proyecto

```
src/
├── ReplicatedStorage/          # Módulos compartidos
│   ├── GameConfig.lua          # Configuración central
│   ├── RemoteEvents.lua        # Comunicación cliente-servidor
│   └── DataManager.lua         # Datos persistentes
├── ServerScriptService/        # Scripts del servidor (12 scripts)
│   ├── GameInit.server.lua     # Inicialización del juego
│   ├── GroupDoorSystem.server.lua
│   ├── RobberySystem.server.lua
│   ├── ShopSystem.server.lua
│   ├── LootingSystem.server.lua
│   ├── WeaponSystem.server.lua
│   ├── PrisonSystem.server.lua
│   ├── AdminCommands.server.lua
│   ├── SWATSystem.server.lua
│   ├── PrivateServerSystem.server.lua
│   ├── ChatCommands.server.lua
│   └── MapBuilder.server.lua
└── StarterGui/                 # Scripts del cliente (6 scripts)
    ├── MainHUD.client.lua
    ├── ShopUI.client.lua
    ├── TeamSelectUI.client.lua
    ├── FloatingIcons.client.lua
    ├── RobberyUI.client.lua
    └── BagUI.client.lua
```

## Licencia
Proyecto privado - Carabineros de Chile Roleplay
