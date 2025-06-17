# Solución al Error de Docker Compose

## ✅ Problema Resuelto

El error `service volume services.certbot.volumes.[1] is missing a mount target` se ha corregido. Aquí están los pasos para completar la instalación:

## 🚀 Pasos para Completar la Instalación

### 1. Verificar que los servicios están funcionando

```bash
cd /opt/jitsi-meet
docker-compose ps
```

Deberías ver los servicios corriendo (excepto certbot que está deshabilitado temporalmente).

### 2. Probar acceso HTTP

Visita: `http://meet.scooller.work.gd`

Si funciona, continúa con el paso 3.

### 3. Configurar SSL (HTTPS)

```bash
cd /opt/jitsi-meet
./scripts/setup-ssl.sh
```

Este script:

- ✅ Obtiene certificados SSL de Let's Encrypt
- ✅ Configura Apache para HTTPS
- ✅ Configura renovación automática
- ✅ Reinicia los servicios

### 4. Verificar funcionamiento completo

Después del setup SSL, visita: `https://meet.scooller.work.gd`

## 🔧 Comandos Útiles

### Ver logs de servicios

```bash
# Logs de Apache
docker-compose logs apache

# Logs de Jitsi Web
docker-compose logs web

# Logs de todos los servicios
docker-compose logs
```

### Reiniciar servicios

```bash
# Reiniciar todo
docker-compose restart

# Reiniciar Apache solamente
docker-compose restart apache
```

### Verificar certificados SSL

```bash
# Ver certificados disponibles
ls -la /opt/jitsi-meet/ssl/live/

# Verificar expiración del certificado
openssl x509 -in /opt/jitsi-meet/ssl/live/meet.scooller.work.gd/cert.pem -text -noout | grep "Not After"
```

## 🛠 Configuración de Firewall

Asegúrate de que estos puertos estén abiertos:

```bash
# Verificar puertos abiertos
firewall-cmd --list-all

# Si necesitas abrir puertos manualmente:
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=10000/udp
firewall-cmd --permanent --add-port=4443/tcp
firewall-cmd --reload
```

## 🔍 Solución de Problemas

### Si no puedes acceder por HTTP:

1. Verifica que el dominio apunta a tu IP: `nslookup meet.scooller.work.gd`
2. Verifica que Apache está corriendo: `docker-compose ps apache`
3. Revisa los logs: `docker-compose logs apache`

### Si SSL falla:

1. Asegúrate de que el sitio HTTP funciona primero
2. Verifica que el dominio es accesible desde internet
3. Ejecuta el script SSL con más verbosidad: `bash -x ./scripts/setup-ssl.sh`

### Si hay problemas de video/audio:

1. Verifica que los puertos UDP están abiertos
2. Configura STUN/TURN servers si es necesario
3. Revisa la configuración de JVB

## 📝 Archivos de Configuración

- **Principal**: `/opt/jitsi-meet/.env`
- **Apache**: `/opt/jitsi-meet/apache/conf.d/`
- **SSL**: `/opt/jitsi-meet/ssl/`
- **Logs**: `/opt/jitsi-meet/logs/`

## 🎯 Próximos Pasos

1. **Primero**: Verifica HTTP funciona
2. **Segundo**: Ejecuta setup SSL
3. **Tercero**: Prueba video llamadas
4. **Cuarto**: Configura opciones avanzadas si es necesario

¡Tu instalación de Jitsi Meet debería estar funcionando correctamente ahora!
