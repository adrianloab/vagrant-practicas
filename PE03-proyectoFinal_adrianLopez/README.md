# PE03 - Cluster Kubernetes con k3s

## Proyecto Final | Opción D (Avanzado)

**Alumno:** Adrián López  
**Asignatura:** Virtualización y Cloud (CENY)  
**Curso:** ASIR2 - 2025/2026  
**Unidad:** UT6  

---

## 📋 Descripción del Proyecto

Este proyecto implementa un **cluster Kubernetes de alta disponibilidad** usando **k3s** (versión ligera de Kubernetes) con un nodo master y dos nodos worker. La infraestructura se despliega automáticamente con **Vagrant** y se provisiona con **Ansible**.

Dentro del cluster se despliega una aplicación web accesible desde el navegador, un panel de monitorización y certificados SSL autofirmados.

---

## 🏗️ Diagrama de Arquitectura

```
                    ┌─────────────────────────────┐
                    │      Host (tu ordenador)    │
                    │                             │
                    │  localhost:8080  → App HTTP │
                    │  localhost:8443  → App HTTPS│
                    │  localhost:9090  → Monitor  │
                    │  localhost:6443  → API K8s  │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────-─┐
                    │     Master (192.168.56.10)    │
                    │     k3s server + kubectl      │
                    │     RAM: 2048 MB | 2 CPUs     │
                    │                               │
                    │  ┌──────────────────────────┐ │
                    │  │   Kubernetes API Server  │ │
                    │  │   Control Plane          │ │
                    │  │   Ansible Controller     │ │
                    │  └──────────────────────────┘ │
                    └────────┬──────────┬───────────┘
                             │          │
                ┌────────────▼──┐  ┌───-▼────────────┐
                │    Worker 1    │  │    Worker 2    │
                │ 192.168.56.11  │  │ 192.168.56.12  │
                │ k3s agent      │  │ k3s agent      │
                │ RAM: 1024 MB   │  │ RAM: 1024 MB   │
                │                │  │                │
                │  ┌──────────┐  │  │  ┌──────────┐  │
                │  │ Pod:     │  │  │  │ Pod:     │  │
                │  │ webapp   │  │  │  │ webapp   │  │
                │  │ (nginx)  │  │  │  │ (nginx)  │  │
                │  └──────────┘  │  │  └──────────┘  │
                │  ┌──────────┐  │  │  ┌──────────┐  │
                │  │ Pod:     │  │  │  │ Pod:     │  │
                │  │ monitor  │  │  │  │ webapp   │  │
                │  └──────────┘  │  │  └──────────┘  │
                └────────────────┘  └────────────────┘
```

---

## 📁 Estructura del Proyecto

```
PE03-proyectoFinal_adrianLopez/
├── README.md                       # Este archivo
├── Vagrantfile                     # Configuración de las 3 VMs
├── config.yaml                     # Variables externas (+0.5 pts)
├── scripts/                        # Scripts de shell
│   ├── common.sh                   # Configuración común (hosts, swap, kernel)
│   ├── install-ansible.sh          # Instalación de Ansible en master
│   ├── run-ansible.sh              # Ejecuta los playbooks
│   └── health-check.sh             # Script de health-check (+0.5 pts)
├── ansible/                        # Provisioning con Ansible (+1.0 pts)
│   ├── site.yml                    # Playbook principal (orquestador)
│   └── roles/
│       ├── k3s-master/             # Instalación k3s server
│       │   ├── tasks/main.yml
│       │   └── defaults/main.yml
│       ├── k3s-worker/             # Instalación k3s agent
│       │   ├── tasks/main.yml
│       │   └── defaults/main.yml
│       ├── ssl-certs/              # Certificados SSL (+0.5 pts)
│       │   ├── tasks/main.yml
│       │   └── defaults/main.yml
│       ├── k8s-app/                # Despliegue de la aplicación
│       │   └── tasks/main.yml
│       └── monitoring/             # Monitorización (+0.5 pts)
│           └── tasks/main.yml
└── k8s/                            # Manifiestos de Kubernetes
    ├── namespace.yml               # Namespace
    ├── configmap-webapp.yml        # HTML + nginx config de la app
    ├── deployment-webapp.yml       # Deployment (3 réplicas)
    ├── service-webapp.yml          # Service HTTP (NodePort 30080)
    ├── service-webapp-https.yml    # Service HTTPS (NodePort 30443)
    ├── monitoring-configmap.yml    # Dashboard de monitorización
    ├── monitoring-deployment.yml   # Deployment del monitor
    └── monitoring-service.yml      # Service del monitor (NodePort 30090)
```

---

## 🖥️ Máquinas Virtuales

| VM | Hostname | IP | RAM | CPUs | Función |
|---|---|---|---|---|---|
| Master | `master` | 192.168.56.10 | 2048 MB | 2 | Nodo master k3s + API Server + Ansible |
| Worker 1 | `worker1` | 192.168.56.11 | 1024 MB | 1 | Nodo worker k3s (ejecuta pods) |
| Worker 2 | `worker2` | 192.168.56.12 | 1024 MB | 1 | Nodo worker k3s (redundancia) |

**RAM total necesaria:** ~4 GB (recomendado 8-16 GB en el host)

---

## 🌐 Puertos y Servicios

| Servicio | Puerto Host | Puerto VM | Descripción |
|---|---|---|---|
| App Web HTTP | `localhost:8080` | 30080 | Aplicación web principal |
| App Web HTTPS | `localhost:8443` | 30443 | Aplicación con SSL |
| Monitor | `localhost:9090` | 30090 | Dashboard de monitorización |
| K8s API | `localhost:6443` | 6443 | API Server de Kubernetes |

---

## 🚀 Instrucciones de Uso

### Requisitos Previos
- **VirtualBox** 6.1+ instalado
- **Vagrant** 2.3+ instalado
- Mínimo **8 GB de RAM** disponible
- Conexión a Internet (para descargar k3s y la imagen de nginx)

### Despliegue Completo

```bash
# 1. Clonar/descargar el proyecto
cd PE03-proyectoFinal_adrianLopez

# 2. Levantar toda la infraestructura (automático)
vagrant up

# 3. Esperar ~10-15 minutos a que se complete el provisioning
# Todo se configura automáticamente: k3s, Ansible, SSL, app, monitor

# 4. Verificar que todo funciona
vagrant status
```

### Acceso a los Servicios

```bash
# Aplicación web
curl http://localhost:8080

# Aplicación web con HTTPS (certificado autofirmado)
curl -k https://localhost:8443

# Dashboard de monitorización
curl http://localhost:9090
```

### Comandos de Kubernetes (desde el master)

```bash
# Conectarse al master
vagrant ssh master

# Ver nodos del cluster
kubectl get nodes

# Ver pods y en qué worker están
kubectl get pods -o wide

# Ver servicios
kubectl get svc

# Ver todos los recursos
kubectl get all

# Ejecutar health-check manual
./health-check.sh
```

---

## 🏆 Puntos Extra Implementados

| Extra | Puntos | Implementación |
|---|---|---|
| **Ansible** | +1.0 | Provisioning completo con Ansible (5 roles: k3s-master, k3s-worker, ssl-certs, k8s-app, monitoring) |
| **Variables externas** | +0.5 | Archivo `config.yaml` con toda la configuración parametrizada |
| **SSL/HTTPS** | +0.5 | Certificados autofirmados generados con OpenSSL, Secret TLS en K8s |
| **Monitorización** | +0.5 | Dashboard web + script health-check.sh con cron cada 5 min |
| **README excelente** | +0.5 | Este README con diagrama, instrucciones completas y troubleshooting |

**Total puntos extra: +3.0**

---

## 🔧 Troubleshooting

### Las VMs no arrancan
```bash
# Verificar que VirtualBox está instalado
VBoxManage --version

# Verificar que Vagrant está instalado
vagrant --version

# Destruir y recrear si hay problemas
vagrant destroy -f
vagrant up
```

### k3s no se instala correctamente
```bash
# Ver logs del master
vagrant ssh master
sudo journalctl -u k3s -f

# Ver logs de un worker
vagrant ssh worker1
sudo journalctl -u k3s-agent -f
```

### Los pods no arrancan
```bash
vagrant ssh master

# Ver estado de los pods
kubectl get pods -o wide

# Ver eventos
kubectl get events --sort-by='.lastTimestamp'

# Ver logs de un pod específico
kubectl logs <nombre-del-pod>

# Describir un pod para ver errores
kubectl describe pod <nombre-del-pod>
```

### No puedo acceder a la app desde el host
```bash
# Verificar que el servicio está creado
vagrant ssh master
kubectl get svc

# Verificar que los pods están Running
kubectl get pods

# Probar desde dentro del master
curl http://localhost:30080
```

### Problemas de RAM
```bash
# Si tu PC tiene poca RAM, modifica config.yaml:
# - Reduce master a 1536 MB
# - Reduce workers a 768 MB

# Verificar uso de RAM en VirtualBox
VBoxManage list runningvms
```

### Resetear el cluster completo
```bash
vagrant destroy -f
vagrant up
```

---

## � Incidencias y Resolución

Durante el desarrollo del proyecto se encontraron varias incidencias que requirieron investigación y corrección. Se documentan aquí como referencia.

### Incidencia 1: Workers no se unen al cluster

**Síntoma:** Al ejecutar `kubectl get nodes` en el master, solo aparecía el nodo master. Los workers no se unían al cluster.

**Causa:** El token de k3s se leía en el rol del master pero no se propagaba correctamente a los workers. El rol `k3s-worker` usaba `delegate_to: localhost` y el módulo `slurp` para leer el token del master, un patrón frágil que fallaba silenciosamente.

**Solución:** Se reestructuró la comunicación del token entre roles:
1. En el rol `k3s-master`, tras leer el token, se guarda como fact con `set_fact: master_k3s_token`
2. En `site.yml`, el play de los workers recibe el token via `hostvars`: 
   ```yaml
   vars:
     k3s_token: "{{ hostvars[groups['master'][0]]['master_k3s_token'] }}"
   ```
3. Se añadió un play intermedio que espera a que los 3 nodos estén en estado Ready antes de desplegar la aplicación

### Incidencia 2: SSH deniega la conexión por contraseña a los workers

**Síntoma:** Ansible no podía conectar con los workers. El error era:
```
fatal: [192.168.56.11]: UNREACHABLE! => Permission denied (publickey)
```

**Causa:** La box `ubuntu/focal64` es una cloud image que incluye el fichero `/etc/ssh/sshd_config.d/60-cloudimg-settings.conf` con `PasswordAuthentication no`. Este fichero se carga con `Include /etc/ssh/sshd_config.d/*.conf` al inicio de `sshd_config` y tiene prioridad sobre cualquier cambio que se haga en el fichero principal.

**Solución:**
1. En `common.sh`, se comenta la directiva `PasswordAuthentication no` en todos los archivos de `/etc/ssh/sshd_config.d/`
2. Se crea un fichero propio `99-allow-password.conf` con máxima prioridad que habilita la autenticación por contraseña
3. En el inventario de Ansible, se añadió `ansible_ssh_common_args='-o PubkeyAuthentication=no'` a los workers para forzar la autenticación por contraseña

### Incidencia 3: Red entre nodos rota (HTTPS y Monitoring inaccesibles)

**Síntoma:** `http://localhost:8080` funcionaba pero `https://localhost:8443` daba `ERR_SSL_PROTOCOL_ERROR` y `http://localhost:9090` no cargaba. Desde el master, los pods en los workers no eran accesibles.

**Causa:** Flannel (la red overlay de k3s) usaba la interfaz NAT de VirtualBox (`enp0s3` con IP `10.0.2.15`) en lugar de la red privada (`enp0s8` con IPs `192.168.56.x`). Como todas las VMs comparten la misma IP NAT, el tráfico entre nodos nunca llegaba. HTTP funcionaba "por suerte" porque una réplica del pod existía en el propio master.

**Solución:** Se añadió el flag `--flannel-iface enp0s8` tanto en la instalación del servidor k3s (master) como en los agentes (workers), forzando a Flannel a usar la red privada de VirtualBox.

### Incidencia 4: HTTPS devuelve error SSL

**Síntoma:** `curl -k https://localhost:30443` devolvía `error:1408F10B:SSL routines:ssl3_get_record:wrong version number`.

**Causa:** El servicio `webapp-https` enviaba el tráfico al `targetPort: 80` del contenedor nginx, que solo servía HTTP plano. El cliente esperaba una conexión TLS pero recibía HTTP.

**Solución:**
1. Se añadió un bloque `server` SSL en la configuración de nginx (configmap) que escucha en el puerto 443 con los certificados TLS
2. Se montó el Secret `webapp-tls` como volumen en el Deployment para que nginx tenga acceso a los certificados
3. Se corrigió el `targetPort` del servicio HTTPS de 80 a 443

---

## �📚 Tecnologías Utilizadas

- **Vagrant** - Gestión de máquinas virtuales
- **VirtualBox** - Hipervisor
- **Ubuntu 20.04 (Focal)** - Sistema operativo de las VMs
- **k3s** - Distribución ligera de Kubernetes
- **Ansible** - Automatización del provisioning
- **Kubernetes** - Orquestación de contenedores
- **Nginx** - Servidor web (contenedor)
- **OpenSSL** - Generación de certificados SSL

---

## 📝 Notas

- El proyecto está diseñado para funcionar con un solo `vagrant up`
- Todos los scripts son idempotentes (se pueden ejecutar múltiples veces sin errores)
- El health-check se ejecuta automáticamente cada 5 minutos vía cron
- Los certificados SSL son autofirmados (el navegador mostrará una advertencia de seguridad)

---

## Autor

- Nombre: **Adrián López**
- LinkedIn: https://www.linkedin.com/in/adrián-lópez-10b7b2398
- Ciclo: **Administración de Sistemas Informáticos en Red (2º ASIR)**
- Video del proyecto: https://youtu.be/wXAQCQ9v_f8 
