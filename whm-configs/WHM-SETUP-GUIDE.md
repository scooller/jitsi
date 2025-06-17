# Configuración de Jitsi Meet en WHM/cPanel - Guía Paso a Paso

## 📋 Prerrequisitos

- Acceso a WHM como root
- Docker y Docker Compose instalados
- Jitsi Meet corriendo en contenedores Docker
- Dominio `meet.scooller.work.gd` apuntando al servidor

## 🔧 Paso 1: Configurar Apache en WHM

### 1.1 Pre VirtualHost Include

1. Accede a **WHM** → **Apache Configuration** → **Pre VirtualHost Include**
2. Pega el contenido del archivo `whm-configs/pre-virtualhost-include.conf`
3. Haz clic en **Save**

### 1.2 Verificar Módulos de Apache

1. Ve a **WHM** → **Apache Configuration** → **Apache Modules**
2. Asegúrate de que estos módulos estén habilitados:
   - ✅ `mod_proxy`
   - ✅ `mod_proxy_http`
   - ✅ `mod_proxy_wstunnel`
   - ✅ `mod_headers`
   - ✅ `mod_rewrite`
   - ✅ `mod_ssl`
   - ✅ `mod_deflate`
   - ✅ `mod_expires`

## 🌐 Paso 2: Crear Subdominio

### 2.1 Crear Subdominio en cPanel

1. Accede al **cPanel** de la cuenta principal
2. Ve a **Subdominios**
3. Crear subdominio:
   - **Subdominio**: `meet`
   - **Dominio**: `scooller.work.gd`
   - **Carpeta**: `public_html/meet` (se crea automáticamente)

### 2.2 Configurar DNS (si es necesario)

Asegúrate de que el DNS tenga un registro A:

```
meet.scooller.work.gd → 198.12.251.248
```

## ⚙️ Paso 3: Configurar Virtual Host

### 3.1 Método Manual (Recomendado)

1. Ve a **WHM** → **Apache Configuration** → **Virtual Hosts**
2. Selecciona el dominio `meet.scooller.work.gd`
3. Reemplaza la configuración con el contenido de `whm-configs/virtualhost-config.conf`
4. **IMPORTANTE**: Cambia `USERNAME` por el nombre de usuario real de cPanel
5. Guarda los cambios

### 3.2 Método por Include (Alternativo)

1. Ve a **WHM** → **Apache Configuration** → **Include Editor**
2. Selecciona **Pre VirtualHost Include**
3. Añade la configuración del virtual host

## 🔒 Paso 4: Configurar SSL

### 4.1 Usando AutoSSL (Recomendado)

1. Ve a **WHM** → **SSL/TLS** → **Manage AutoSSL**
2. Asegúrate de que AutoSSL esté habilitado
3. Añade `meet.scooller.work.gd` a la lista de dominios
4. AutoSSL generará automáticamente el certificado

### 4.2 Usando Let's Encrypt Manual

```bash
# Si AutoSSL falla, usa certbot manualmente
/root/.acme.sh/acme.sh --issue -d meet.scooller.work.gd --webroot /home/USERNAME/public_html/meet
```

## 🐳 Paso 5: Ajustar Configuración Docker

### 5.1 Actualizar .env

Asegúrate de que el archivo `.env` tenga:

```env
# Usar puerto 8081 para evitar conflictos con cPanel
HTTP_PORT=8081
HTTPS_PORT=8444

# Configuración del dominio
PUBLIC_URL=https://meet.scooller.work.gd
LETSENCRYPT_DOMAIN=meet.scooller.work.gd
LETSENCRYPT_EMAIL=admin@scooller.work.gd

# IP del servidor
DOCKER_HOST_ADDRESS=198.12.251.248
```

### 5.2 Reiniciar Servicios Docker

```bash
cd /opt/jitsi-meet
docker-compose down
docker-compose up -d
```

## 🔍 Paso 6: Verificar Configuración

### 6.1 Comprobar Puertos

```bash
# Verificar que los servicios estén corriendo en los puertos correctos
netstat -tlnp | grep -E "(8081|5280|10000|4443)"
```

### 6.2 Probar Conectividad

```bash
# Probar conexión local
curl -I http://127.0.0.1:8081

# Probar desde el exterior
curl -I http://meet.scooller.work.gd
```

### 6.3 Verificar WebSockets

```bash
# Verificar que los módulos de proxy WebSocket estén cargados
httpd -M | grep proxy
```

## 🚨 Solución de Problemas

### Problema: "502 Bad Gateway"

**Causa**: Apache no puede conectar con los contenedores Docker

**Solución**:

1. Verificar que Docker esté corriendo: `docker-compose ps`
2. Comprobar puertos: `netstat -tlnp | grep 8081`
3. Revisar logs: `docker-compose logs web`

### Problema: WebSockets no funcionan

**Causa**: `mod_proxy_wstunnel` no está habilitado

**Solución**:

1. Ve a **WHM** → **Apache Configuration** → **Apache Modules**
2. Habilita `mod_proxy_wstunnel`
3. Reinicia Apache: `systemctl restart httpd`

### Problema: CSS/JS no cargan

**Causa**: Problemas de proxy con archivos estáticos

**Solución**:

1. Verificar la configuración de `ProxyPass`
2. Comprobar permisos en `/home/USERNAME/public_html/meet`
3. Revisar logs de Apache: `tail -f /var/log/httpd/error_log`

## 📊 Monitoreo

### Logs Importantes

```bash
# Logs de Apache
tail -f /var/log/httpd/meet.scooller.work.gd.error.log
tail -f /var/log/httpd/meet.scooller.work.gd.access.log

# Logs de Docker
docker-compose logs -f web
docker-compose logs -f apache
```

### Comandos Útiles

```bash
# Reiniciar Apache
systemctl restart httpd

# Reiniciar servicios Docker
docker-compose restart

# Verificar configuración Apache
httpd -t

# Ver configuración activa
httpd -S
```

## ✅ Lista de Verificación Final

- [ ] Pre VirtualHost Include configurado
- [ ] Módulos de Apache habilitados
- [ ] Subdominio creado en cPanel
- [ ] Virtual Host configurado con usuario correcto
- [ ] SSL configurado (AutoSSL o manual)
- [ ] Docker corriendo en puerto 8081
- [ ] Firewall configurado (puertos 80, 443, 10000/udp, 4443/tcp)
- [ ] DNS apuntando correctamente
- [ ] Sitio accesible en https://meet.scooller.work.gd

¡Una vez completados todos estos pasos, tu Jitsi Meet debería estar funcionando perfectamente integrado con WHM/cPanel!
