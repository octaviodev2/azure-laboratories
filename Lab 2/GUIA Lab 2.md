# Lab 2: Guía paso a paso (proyecto integrador en Azure)

Esta guía se reconstruyó a partir de los 13 videos de la carpeta. Todo se hace en el **Azure Portal** (en español), con la suscripción **Azure for Students** y la región **Mexico Central**.

**Requisito previo (Lab 1):** el grupo de recursos `rg-utvt-integradora-dev-mxc-001`, con Log Analytics, Application Insights, App Service Plan y Web App ya creados.

**Etiquetas para todos los recursos:**

| Clave | Valor |
|---|---|
| `cost_center` | `utvt` |
| `environment` | `dev` |
| `managed_by` | `portal` |
| `owner` | `equipo-integradora` |

---

## 1. Arquitectura objetivo (video 1)

Diagrama: *Arquitectura de referencia – Azure for Students (Landing Zone + Well-Architected)*.

| Subred | CIDR | Qué contiene |
|---|---|---|
| snet-app | 10.0.1.0/24 | App Service Linux B1 con *VNet Integration* (subred delegada a `Microsoft.Web/serverFarms`) |
| snet-db | 10.0.2.0/24 | Private Endpoint de PostgreSQL (10.0.2.4) |
| snet-vm | 10.0.3.0/24 | VM *worker* |
| snet-pe / endpoints | 10.0.4.0/24 | Private Endpoint de Blob (10.0.4.4) |
| AzureBastionSubnet | 10.0.5.0 | Azure Bastion |

- **Servicios PaaS sin acceso público:** PostgreSQL Flexible Server (Burstable B1ms) y Storage Account (Blob, Standard LRS). Solo se llega a ellos por Private Link.
- **Zonas DNS privadas:** `privatelink.postgres.database.azure.com` y `privatelink.blob.core.windows.net`.
- **Acceso del administrador:** Portal (TLS 443) → Bastion → VM. La VM no tiene puertos abiertos a Internet.

**Nombres del Excel `Red y subredes.xlsx`:**

| Recurso | Nombre | CIDR |
|---|---|---|
| Red virtual | `vnet-utvt-integradora-dev-mxc-001` | 10.0.0.0/16 |
| Subred App Service | `snet-utvt-integradora-app-dev-mxc-001` | 10.0.1.0/24 |
| Subred BD | `snet-utvt-integradora-db-dev-mxc-001` | 10.0.2.0/24 |
| Subred VM | `snet-utvt-integradora-vm-dev-mxc-001` | 10.0.3.0/24 |
| Subred Private Endpoints | `snet-utvt-integradora-pe-dev-mxc-001` | 10.0.4.0/24 |
| Subred Bastion | `AzureBastionSubnet` | 10.0.5.0/24 en el Excel (en el video se usa /26) |
| PostgreSQL | `psql-utvt-integradora-dev-mxc-001` | |
| PE PostgreSQL | `pep-utvt-integradora-db-dev-mxc-001` | |
| NIC del PE PostgreSQL | `nic-utvt-integradora-pe-db-dev-mxc-001` | |
| Storage account | `stutvtintdevmxc001` | |
| PE Blob | `pep-utvt-integradora-blob-dev-mxc-001` | |
| NIC del PE Blob | `nic-utvt-integradora-pe-blob-dev-mxc-001` | |
| Zona DNS Blob | `privatelink.blob.core.windows.net` | |

---

## 2. VNet y subredes (video 2)

En **Inicio**, selecciona **Red virtual** → **Crear**.

1. **Datos básicos**
   - Suscripción: Azure for Students
   - Grupo de recursos: `rg-utvt-integradora-dev-mxc-001`
   - Nombre: `vnet-utvt-integradora-dev-mxc-001`
   - Región: **Mexico Central**
2. **Seguridad**: deja todo desmarcado (cifrado de VNet, Azure Firewall, DDoS y **Azure Bastion**). El Bastion se crea después, desde la VM.
3. **Espacio de direcciones**
   - Espacio: `10.0.0.0/16`.
   - En el video se conservó la subred `default` 10.0.0.0/24. No se usa.
   - Con **+ Agregar una subred**, agrega cada una con *Propósito = Default*, tamaño **/24** y "Habilitar subred privada" marcado (es el valor por defecto):

     | Nombre | Dirección inicial |
     |---|---|
     | `snet-utvt-integradora-app-dev-mxc-001` | 10.0.1.0 |
     | `snet-utvt-integradora-db-dev-mxc-001` | 10.0.2.0 |
     | `snet-utvt-integradora-vm-dev-mxc-001` | 10.0.3.0 |
     | `snet-utvt-integradora-pe-dev-mxc-001` | 10.0.4.0 |

   - Agrega una subred más con **Propósito = Azure Bastion**. El nombre queda fijo como `AzureBastionSubnet`. Dirección inicial `10.0.5.0`; en el video el tamaño fue **/26**, que es el mínimo que exige Azure.
4. **Etiquetas**: agrega las 4 etiquetas.
5. **Revisar y crear** → **Crear**.

Al terminar, la VNet debe tener 6 subredes.

---

## 3. Máquina virtual (videos 3, 4 y 5)

Ve a **Máquinas virtuales** → **+ Crear** → **Máquina virtual**.

### Datos básicos (video 3)

- **Grupo de recursos y nombre**
  - Grupo de recursos: `rg-utvt-integradora-dev-mxc-001`
  - Nombre: `vm-utvt-integradora-dev-mxc-001`
  - Región: Mexico Central
- **Disponibilidad y seguridad**
  - Opciones de disponibilidad: **No se requiere redundancia de la infraestructura**
  - Tipo de seguridad: **Máquinas virtuales de inicio seguro**
- **Imagen y tamaño**
  - Imagen: **Windows Server 2025 Datacenter – x64 Gen2**. El diagrama dice Linux, pero en el video se usó Windows.
  - Tamaño: el valor por defecto (DS1_v2) no está disponible en la suscripción. Usa **Ver todos los tamaños** → **Standard_B2als_v2** (2 vCPU, 4 GiB).
- **Cuenta de administrador**
  - Usuario: `adminazureuser`
  - Contraseña: la que tú elijas. **Guárdala**, porque la vas a necesitar en Bastion.
- **Acceso y licencia**
  - Puertos de entrada públicos: **Ninguno**
  - Licencias: marca **Usar una licencia de Windows Server existente** y **Confirmo**. Azure for Students la incluye; puedes verificarlo en *Education → Software*.

### Discos (video 4)

- Disco del SO: tamaño predeterminado (127 GiB), **SSD prémium (LRS)**
- Eliminar con la VM: marcado
- Sin discos de datos

### Redes (video 4)

- **Red y subred**
  - Red virtual: `vnet-utvt-integradora-dev-mxc-001`
  - Subred: `snet-utvt-integradora-vm-dev-mxc-001 (10.0.3.0/24)`
- **IP pública**
  - En el video se dejó la que se crea nueva (`vm-utvt-integradora-dev-mxc-001-ip`).
  - Con Bastion no hace falta, así que puedes poner *Ninguno*.
- **Seguridad**
  - NSG de NIC: **Básico**
  - Puertos de entrada: **Ninguno**
- **Otras opciones**
  - Eliminar IP pública y NIC al eliminar la VM: marcado
  - Redes aceleradas: marcado
  - Equilibrio de carga: Ninguno

### Administración, supervisión, avanzado y etiquetas (video 4)

- **Administración**
  - Todo por defecto.
  - Identidad administrada desmarcada.
  - "Habilitar evaluación periódica" marcado.
- **Supervisión**
  - Alertas recomendadas desmarcadas.
  - Diagnósticos de arranque: *Habilitar con cuenta de almacenamiento administrada*.
- **Avanzado**: nada.
- **Etiquetas**: las 4 etiquetas.
- **Revisar y crear** → **Crear**.

### Conectarse por Bastion (video 5)

1. **Ir al recurso**. La IP privada de la VM debe ser **10.0.3.4**.
2. *(Demostración)* Intenta conectarte por RDP (`mstsc`) a la IP pública. **No conecta**, porque no hay puertos abiertos. Eso es lo esperado.
3. En la VM, abre **Conectar → Bastión**. El portal crea un **Bastion SKU Developer** (`vnet-utvt-integradora-dev-mxc-001-bastion`). Configura:
   - Idioma del teclado: Latinoamericano
   - Autenticación: *Contraseña de máquina virtual*
   - Usuario: `adminazureuser`
   - Contraseña: la tuya
   - Marca *Abrir en una nueva pestaña*
   - Pulsa **Conectar**
4. Dentro de Windows, abre **Terminal** y ejecuta `ipconfig`. Debe mostrar **IPv4 10.0.3.4** y **gateway 10.0.3.1**.
5. *(Opcional)* Revisa **Bastion → Configuración**. El SKU debe ser **Developer**.

---

## 4. PostgreSQL Flexible Server (video 6)

Busca **Azure Database for PostgreSQL flexible server** → **Crear**.

### Básico

- **Proyecto y servidor**
  - Grupo de recursos: `rg-utvt-integradora-dev-mxc-001`
  - Nombre del servidor: `psql-utvt-integradora-dev-mxc-001`
  - Región: **Mexico Central**. Si aparece otra (por ejemplo, Canada Central), cámbiala; la política de la suscripción la rechaza.
  - Versión de PostgreSQL: **18**
  - Tipo de carga de trabajo: **Desarrollo/pruebas**
- **Proceso y almacenamiento → Configurar servidor**
  - Nivel: **Ampliable (Burstable)**, tamaño **Standard_B1ms** (1 vCore, 2 GiB)
  - Almacenamiento: SSD Premium, **32 GiB**, P4
  - Crecimiento automático: desmarcado
  - Alta disponibilidad: **Deshabilitada**
  - Retención de copias de seguridad: **7 días**
  - Pulsa **Guardar**. El costo estimado es de unos USD 20/mes, pero entra en las horas gratuitas.
- Zona de disponibilidad: Sin preferencias
- **Autenticación**
  - Método: **PostgreSQL y autenticación de Microsoft Entra**
  - Administrador de Entra: *Establecer administrador* → tu cuenta de la escuela
  - Usuario administrador: `adminpgdev`
  - Contraseña: la tuya. **Guárdala**.

### Redes

- Método de conectividad: **Acceso público (direcciones IP permitidas) y puntos de conexión privados**. Esta opción permite agregar el Private Endpoint después.
- **Desmarca** "Permitir acceso público…". En el resumen debe aparecer *Acceso público: No*.
- No agregues reglas de firewall ni tu IP.

### Seguridad, etiquetas y creación

- **Seguridad**: Clave administrada por el servicio.
- **Etiquetas**: las 4 etiquetas.
- **Revisar y crear** → **Crear**. Si aparece el aviso de firewall, elige **Crear servidor sin reglas de firewall**.
- Tarda unos 7 minutos.

---

## 5. Private Endpoint de PostgreSQL (video 7)

Abre `psql-utvt-integradora-dev-mxc-001` → **Configuración → Redes** → **+ Creación de un punto de conexión privado**.

1. **Datos básicos**
   - Nombre: `pep-utvt-integradora-db-dev-mxc-001`
   - Nombre de la interfaz de red: el portal propone `…-nic`. Reemplázalo por **`nic-utvt-integradora-pe-db-dev-mxc-001`**.
   - Región: Mexico Central
2. **Recurso**: subrecurso de destino **postgresqlServer**.
3. **Virtual Network**
   - VNet: `vnet-utvt-integradora-dev-mxc-001`
   - Subred: **`snet-utvt-integradora-db-dev-mxc-001`**. Así lo indica el diagrama (10.0.2.4) y así se lee en el resumen del video.
   - IP: dinámica
4. **DNS**
   - Integrar con zona DNS privada: **Sí**
   - Zona: **(nuevo) `privatelink.postgres.database.azure.com`** en el mismo grupo de recursos
5. **Etiquetas**: las 4 etiquetas.
6. **Crear**.

**Comprobación:** en psql → Redes, el endpoint debe aparecer con estado **Approved** y el acceso público desmarcado.

---

## 6. Crear la base de datos `integradora` (video 8)

**Opción portal (demostración):**

1. Ve a psql → **Configuración → Bases de datos** → **+ Agregar**.
2. Escribe el nombre `test` → **Guardar**.
3. Después **elimínala** (Eliminar → confirmar).

**Opción CLI (la que vale):** abre **Cloud Shell (Bash)** y ejecuta:

```bash
az postgres flexible-server db create \
  --resource-group rg-utvt-integradora-dev-mxc-001 \
  --server-name psql-utvt-integradora-dev-mxc-001 \
  -n integradora
```

> ⚠️ La primera versión del `.txt`, con `--database-name`, **falla** con el error `the following arguments are required: --name/-n`. Usa `-n` (o `--name`).

**Resultado esperado:** `"Creating database with utf8 charset and en_US.utf8 collation"` y un JSON con `"name": "integradora"`. En Bases de datos deben quedar `azure_maintenance`, `azure_sys`, `postgres` e **`integradora`**.

---

## 7. Detener VM y servidor de BD para ahorrar créditos (video 9)

- **VM:** `vm-utvt-integradora-dev-mxc-001` → **Detener**. Espera a que el estado sea **Detenido (desasignado)**.
- **PostgreSQL:** `psql-utvt-integradora-dev-mxc-001` → **Detener**. El estado pasa por *Stopping* hasta *Stopped*.

> PostgreSQL se vuelve a encender solo después de 7 días detenido.

---

## 8. Revisión de componentes (video 10)

Comprueba en el diagrama qué ya está creado:

- **Ya creado:** App Service, PE de PostgreSQL, VM, Bastion, PostgreSQL y zona DNS de postgres.
- **Falta:** Storage Account, PE de Blob y zona DNS de blob. Se crean en los pasos 9 y 10.

---

## 9. Storage Account / Blob (video 11)

Ve a **Cuentas de almacenamiento** (o *Centro de almacenamiento → Blob Storage*) → **Crear**.

1. **Datos básicos**
   - Grupo de recursos: `rg-utvt-integradora-dev-mxc-001`
   - Nombre: `stutvtintdevmxc001`
   - Región: Mexico Central
   - Servicio principal: Azure Blob Storage o Azure Data Lake Storage
   - Rendimiento: **Estándar**
   - Redundancia: **LRS**
2. **Avanzado**: valores por defecto. Espacio de nombres jerárquico desmarcado; nivel de acceso **Frecuente (Hot)**.
3. **Redes**
   - Acceso a la red pública: **Deshabilitar**
   - No agregues un endpoint aquí; se crea en el paso 10.
4. **Protección de datos**
   - Eliminación temporal de blobs: 7 días
   - Eliminación temporal de contenedores: 7 días
   - Lo demás desmarcado
5. **Seguridad**: valores por defecto. TLS mínimo 1.2; acceso anónimo a blobs deshabilitado.
6. **Cifrado**: claves administradas por Microsoft.
7. **Etiquetas**: las etiquetas.
8. **Revisar y crear** → **Crear**.

---

## 10. Private Endpoint de Blob (video 12)

Abre `stutvtintdevmxc001` → **Seguridad y redes → Redes** → pestaña **Puntos de conexión privados** → **+ Create private endpoint**.

1. **Datos básicos**
   - Nombre: `pep-utvt-integradora-blob-dev-mxc-001`
   - NIC: **`nic-utvt-integradora-pe-blob-dev-mxc-001`**. Reemplaza el nombre que propone el portal.
   - Región: Mexico Central
2. **Recurso**: tipo `Microsoft.Storage/storageAccounts`, recurso `stutvtintdevmxc001`, subrecurso **blob**.
3. **Virtual Network**
   - VNet: `vnet-utvt-integradora-dev-mxc-001`
   - Subred: **`snet-utvt-integradora-pe-dev-mxc-001` (10.0.4.0/24)**
   - IP: dinámica
4. **DNS**: integrar con zona DNS privada **Sí**, zona **`privatelink.blob.core.windows.net`**.
5. **Etiquetas** → **Revisar y crear** → **Crear**.

---

## 11. Nuevo App Service con VNet Integration (video 13)

### A. Plan de App Service

Ve a **Planes de App Service** → **Crear**.

- Nombre: `asp-utvt-integradora-dev-mxc-001`
- Sistema operativo: **Linux**
- Región: **Mexico Central**. El valor por defecto es West US 3; cámbialo.
- Plan de precios: en **Explorar planes de precios** elige **Básico B1** (1.75 GB, 1 vCPU). *F1 Gratis no permite integración con VNet.*
- Etiquetas: las 4 etiquetas → **Crear**.

### B. Aplicación web

Ve a **App Services** → **Crear** → **Aplicación web**.

1. **Datos básicos**
   - Nombre: `app-utvt-integradora-web-dev-mxc-001`
   - Publicar: **Código**
   - Pila: **Node 24 LTS**
   - SO: Linux
   - Región: **Mexico Central**
   - Plan: `asp-utvt-integradora-dev-mxc-001` (B1)
2. **Implementación**: implementación continua **Deshabilitar**; autenticación básica **Deshabilitar**.
3. **Redes**
   - Habilitar acceso público: **Activado**
   - Habilitar integración de red virtual: **Activado**
   - Virtual Network: `vnet-utvt-integradora-dev-mxc-001`
   - Subred de salida: **`snet-utvt-integradora-app-dev-mxc-001`**
   - Las demás subredes aparecen como "No disponible" porque ya tienen recursos o delegación.
4. **Etiquetas**: las 4 etiquetas → **Revisar y crear** → **Crear**.

**Comprobación** en la información general de la app:

- Estado *En ejecución*
- Pila Node 24-lts
- Integración de red virtual: `vnet-utvt-integradora-dev-mxc-001/snet-utvt-integradora-app-dev-mxc-001`
- Abre el dominio predeterminado: la página debe cargar.

### C. Application Insights

En la app → **Supervisión → Application Insights** → **Habilitar**.

- Crear nuevo recurso. En el video se dejó el nombre propuesto (`app-utvt-integradora-web-dev-mxc-001`).
  - *Alternativa coherente con la nomenclatura:* elige **Seleccionar recurso existente** → `appi-utvt-integradora-dev-mxc-001`.
- Área de trabajo de Log Analytics: cámbiala de *DefaultWorkspace…* a **`log-utvt-integradora-dev-mxc-001`**.
- Pulsa **Aplicar**.

---

## Diferencias entre el diagrama y lo que se hizo en los videos

| Tema | Diagrama o Excel | Video |
|---|---|---|
| SO de la VM | Linux, B2ats_v2 | Windows Server 2025, B2als_v2 |
| Identidad administrada de la VM | Sí (MI) | No se habilitó |
| AzureBastionSubnet | /24 | /26 |
| Bastion | Dedicado | SKU Developer, creado desde la VM |
| NSG por subred | nsg-app, nsg-db, etc. | Solo el NSG básico de la NIC de la VM |
| Subred `default` | No existe | Se conservó 10.0.0.0/24 |

Al terminar, **detén la VM y el servidor PostgreSQL** (paso 7) para no gastar créditos.
