# Sandbox network decision

**Status:** proposed, needs security sign-off.
**Applies to:** the DNA ML sandbox only. Dev and prod will use private networking.

| Setting | Sandbox choice | What it means |
|---|---|---|
| Endpoints | **Public** | Services have internet addresses. No VNet, subnets, private endpoints or private DNS. No network team needed. |
| Login | **Entra only** | API keys, shared keys and admin passwords are off. Nobody gets in without an account in one of the DNA groups. This is the main protection. |
| Azure ML compute | **Managed network** (`AllowInternetOutbound`) | Microsoft runs an isolated network for the training computers. |
| IP restrictions | Optional | Where a service supports it, allow only the corporate network or VPN ranges. |
| Data allowed | **Synthetic or masked only** | This condition is what makes public endpoints acceptable. |

## How the templates apply it

| Resource | Setting in `infra/` |
|---|---|
| Azure ML workspace | `publicNetworkAccess: 'Enabled'`, `managedNetwork.isolationMode: 'AllowInternetOutbound'` |
| Azure ML compute clusters | `disableLocalAuth: true` |
| Container registry | `adminUserEnabled: false` |
| Foundry resource | `publicNetworkAccess: 'Enabled'`, `disableLocalAuth: true` (no API keys) |
| Key Vaults | RBAC (Entra) access only |
| Azure ML storage | Shared keys **on** by default. See below. |

## Storage shared keys

`disableStorageSharedKey` is `false` by default. Turning shared keys off also needs the Azure ML workspace to use identity-based access to its own storage, otherwise Azure ML studio can stop showing files. Before setting it to `true`, follow Microsoft's current "disable shared key access" guidance for Azure ML and test it with a data scientist account. The audit policy in `policies/` reports the storage account as non-compliant until then.

## Foundry data residency

A `GlobalStandard` model deployment may process prompts in any Azure region. `Standard` keeps processing in the resource's region. Agree the deployment type with security before adding models to `infra/sandbox.bicepparam`.

## When to switch to private networking

Switch to private endpoints, private DNS and Fabric managed private endpoints when either happens:

1. Real patient or personal data needs to come into the sandbox. Under POPIA, health data is special personal information.
2. We build dev or prod.

Until then, **real patient data is not allowed in the sandbox.** The DNA team must be told this clearly.
