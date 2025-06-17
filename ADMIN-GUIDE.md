# 🔐 Administración de Jitsi Meet - Guía Completa

Esta guía te explica cómo configurar y usar el sistema de administración para tu instancia de Jitsi Meet.

## 🎯 Opciones de Control de Acceso

### 1. **Modo Público (Por Defecto)**

- Cualquier persona puede crear y unirse a reuniones
- No requiere autenticación
- Ideal para uso general

### 2. **Modo Privado/Administrado**

- Solo usuarios registrados pueden crear reuniones
- Requiere autenticación
- Control total sobre quién puede usar el sistema

## 🛠️ Configuración de Autenticación

### Opción A: Usar Script de Gestión de Usuarios

```bash
# Hacer el script ejecutable
chmod +x scripts/user-management.sh

# Crear usuario administrador
./scripts/user-management.sh create_admin admin mipassword123

# Habilitar autenticación (modo privado)
./scripts/user-management.sh enable_auth

# Reiniciar servicios
docker-compose restart
```

### Opción B: Configuración Manual

1. **Editar archivo .env:**

```bash
# Cambiar estas líneas:
ENABLE_AUTH=1
ENABLE_GUESTS=0
ENABLE_ROOM_CREATION_RESTRICTION=1
```

2. **Reiniciar servicios:**

```bash
docker-compose restart
```

3. **Crear usuarios:**

```bash
# Crear usuario administrador
docker exec -it jitsi_prosody_1 prosodyctl --config /config/prosody.cfg.lua register admin auth.meet.jitsi mipassword123

# Crear usuario normal
docker exec -it jitsi_prosody_1 prosodyctl --config /config/prosody.cfg.lua register usuario1 auth.meet.jitsi password456
```

## 🌐 Panel de Administración Web

### Instalación del Panel Web

1. **Copiar archivos del panel:**

```bash
# El panel está en la carpeta admin/
# Acceso web: https://tu-dominio.com/admin/
```

2. **Configurar Apache (WHM):**

Agregar en "Pre VirtualHost Include":

```apache
# Admin panel configuration
<Location "/admin">
    # Restringir acceso por IP (opcional)
    Require ip 192.168.1.0/24
    Require ip TU_IP_PUBLICA

    # Habilitar PHP
    <FilesMatch "\.php$">
        SetHandler application/x-httpd-php
    </FilesMatch>
</Location>
```

3. **Configurar contraseña del panel:**

Editar `admin/index.php`:

```php
$ADMIN_PASSWORD = 'tu_password_seguro_aqui';
```

### Funciones del Panel Web

- **📊 Estado del Sistema**: Monitoreo en tiempo real
- **👥 Gestión de Usuarios**: Crear, eliminar, cambiar contraseñas
- **🔒 Control de Acceso**: Activar/desactivar autenticación
- **🔄 Gestión de Servicios**: Reiniciar componentes
- **📝 Logs de Actividad**: Historial de acciones

## 🔧 Comandos de Gestión

### Gestión de Usuarios

```bash
# Listar usuarios
./scripts/user-management.sh list_users

# Crear usuario
./scripts/user-management.sh create_user juan password123

# Eliminar usuario
./scripts/user-management.sh delete_user juan

# Cambiar contraseña
./scripts/user-management.sh change_password juan nuevapassword
```

### Control de Acceso

```bash
# Activar modo privado
./scripts/user-management.sh enable_auth

# Volver a modo público
./scripts/user-management.sh disable_auth
```

### Verificación de Estado

```bash
# Ver estado de contenedores
docker-compose ps

# Ver logs de autenticación
docker-compose logs prosody | grep auth

# Verificar usuarios registrados
docker exec -it jitsi_prosody_1 prosodyctl --config /config/prosody.cfg.lua mod_listusers auth.meet.jitsi
```

## 🔐 Niveles de Seguridad

### Nivel 1: Básico (Público)

```bash
ENABLE_AUTH=0
ENABLE_GUESTS=1
```

- Acceso público
- Cualquiera puede crear reuniones

### Nivel 2: Moderado (Semi-privado)

```bash
ENABLE_AUTH=1
ENABLE_GUESTS=1
```

- Usuarios registrados pueden crear reuniones
- Invitados pueden unirse

### Nivel 3: Restringido (Privado)

```bash
ENABLE_AUTH=1
ENABLE_GUESTS=0
ENABLE_ROOM_CREATION_RESTRICTION=1
```

- Solo usuarios registrados
- Control total de acceso

### Nivel 4: Máximo (Corporativo)

```bash
ENABLE_AUTH=1
ENABLE_GUESTS=0
ENABLE_ROOM_CREATION_RESTRICTION=1
ENABLE_LOBBY_MODE=1
```

- Autenticación requerida
- Salas de espera
- Aprobación de participantes

## 🛡️ Configuración de Seguridad Avanzada

### Restricción por IP

Agregar en Apache (WHM):

```apache
<Location "/">
    # Permitir solo desde estas IPs
    Require ip 192.168.1.0/24
    Require ip 10.0.0.0/8
    Require ip TU_IP_PUBLICA
</Location>
```

### Autenticación Adicional con .htaccess

```apache
# Crear archivo .htpasswd
htpasswd -c /path/to/.htpasswd admin

# Configurar en Apache
<Location "/admin">
    AuthType Basic
    AuthName "Área Administrativa"
    AuthUserFile /path/to/.htpasswd
    Require valid-user
</Location>
```

### Firewall Interno

```bash
# Bloquear acceso directo a puertos de Docker
iptables -A INPUT -p tcp --dport 8081 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 8081 -j DROP
iptables -A INPUT -p tcp --dport 5280 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 5280 -j DROP
```

## 📊 Monitoreo y Logs

### Logs de Autenticación

```bash
# Ver intentos de autenticación
docker-compose logs prosody | grep "authentication"

# Ver conexiones WebSocket
docker-compose logs jitsi-web | grep "websocket"

# Logs del panel admin
tail -f logs/admin.log
```

### Métricas de Uso

```bash
# Usuarios activos
docker exec -it jitsi_prosody_1 prosodyctl --config /config/prosody.cfg.lua mod_listusers auth.meet.jitsi | wc -l

# Salas activas
docker-compose logs jvb | grep "Conference" | tail -10
```

## 🚨 Solución de Problemas

### Error: "Cannot authenticate"

1. Verificar que ENABLE_AUTH=1
2. Comprobar que el usuario existe:

```bash
docker exec -it jitsi_prosody_1 prosodyctl --config /config/prosody.cfg.lua mod_listusers auth.meet.jitsi
```

### Error: "User creation failed"

1. Verificar que Prosody está ejecutándose:

```bash
docker-compose ps prosody
```

2. Revisar logs de Prosody:

```bash
docker-compose logs prosody
```

### Panel Admin No Accesible

1. Verificar configuración Apache
2. Comprobar permisos de archivos PHP
3. Revisar logs de Apache:

```bash
tail -f /usr/local/apache/logs/error_log
```

## 📋 Checklist de Implementación

### Para Modo Privado:

- [ ] Editar .env con ENABLE_AUTH=1
- [ ] Crear usuario administrador
- [ ] Probar autenticación
- [ ] Configurar panel web (opcional)
- [ ] Configurar restricciones IP (opcional)
- [ ] Reiniciar servicios
- [ ] Probar acceso restringido

### Para Modo Público:

- [ ] Editar .env con ENABLE_AUTH=0
- [ ] Reiniciar servicios
- [ ] Probar acceso público
- [ ] Configurar monitoreo básico

## 🎯 Recomendaciones

1. **Para Uso Empresarial**: Usar Nivel 3 o 4 de seguridad
2. **Para Comunidades**: Usar Nivel 2 (semi-privado)
3. **Para Uso Personal**: Cualquier nivel según necesidad
4. **Siempre**: Configurar contraseñas seguras
5. **Siempre**: Monitorear logs de acceso
6. **Siempre**: Hacer backups regulares de configuración

---

Con esta configuración tendrás control completo sobre quién puede acceder y usar tu instancia de Jitsi Meet. 🎉
