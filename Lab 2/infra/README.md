# Lab 2: Infraestructura como código

Este directorio contiene el código del Lab 2, que despliega la red y los servicios privados del proyecto integrador en el ambiente *dev*. Hay dos formas equivalentes de desplegar lo mismo que se hace en el portal (ver [`../GUIA Lab 2.md`](../GUIA%20Lab%202.md)):

| Carpeta | Herramienta | Uso |
|---|---|---|
| `cli/` | Azure CLI (bash) | Un script por cada video/componente, para ejecutarlos paso a paso |
| `bicep/` | Bicep (IaC declarativa) | `main.bicep` y un módulo por componente, desplegados con un solo comando |

## Requisitos

- Azure CLI 2.6x o superior con sesión iniciada (`az login`) en la suscripción **Azure for Students**.
- Grupo de recursos `rg-utvt-integradora-dev-mxc-001` y Log Analytics `log-utvt-integradora-dev-mxc-001` creados en el Lab 1.
- Bash: Git Bash, WSL o Cloud Shell.

> **Plan y app del Lab 1:** si ya existen con el plan F1 o con Windows, hay que eliminarlos antes. F1 no admite integración con red virtual.

## Azure CLI

```bash
cd cli
./deploy-all.sh            # todo en orden; pide las contraseñas de la VM y de PostgreSQL
# o paso a paso:
./01-vnet.sh
./02-vm.sh
./03-bastion.sh
./04-postgresql.sh
./05-pe-postgresql.sh
./06-database.sh
./08-storage.sh
./09-pe-blob.sh
./10-app-service.sh
./07-stop-start.sh stop    # al terminar, para no consumir créditos
```

| Script | Video | Recursos |
|---|---|---|
| `01-vnet.sh` | 2 | `vnet-utvt-integradora-dev-mxc-001` y subredes app/db/vm/pe/AzureBastionSubnet |
| `02-vm.sh` | 3-4 | `vm-utvt-integradora-dev-mxc-001`: Windows Server 2025, B2als_v2, sin puertos abiertos |
| `03-bastion.sh` | 5 | Bastion SKU Developer |
| `04-postgresql.sh` | 6 | `psql-utvt-integradora-dev-mxc-001`: PG 18, B1ms, sin acceso público |
| `05-pe-postgresql.sh` | 7 | `pep-utvt-integradora-db-dev-mxc-001` y zona `privatelink.postgres.database.azure.com` |
| `06-database.sh` | 8 | Base de datos `integradora` |
| `07-stop-start.sh` | 9 | Detener o iniciar la VM y PostgreSQL |
| `08-storage.sh` | 11 | `stutvtintdevmxc001`: Standard LRS, sin acceso público |
| `09-pe-blob.sh` | 12 | `pep-utvt-integradora-blob-dev-mxc-001` y zona `privatelink.blob.core.windows.net` |
| `10-app-service.sh` | 13 | Plan B1 Linux y Web App Node 24 con VNet Integration y Application Insights |

## Bicep

```bash
cd bicep
./deploy.sh what-if   # vista previa de los cambios
./deploy.sh           # despliegue
```

## Seguridad

Las contraseñas **no** se guardan en el repositorio: los scripts las piden al ejecutarse o las leen de las variables de entorno `VM_ADMIN_PASSWORD` y `PSQL_ADMIN_PASSWORD`.
