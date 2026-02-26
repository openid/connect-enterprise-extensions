%%%
title = "OpenID Connect Enterprise Extensions 1.0 - draft 02"
abbrev = "openid-connect-enterprise-extensions"
ipr = "none"
workgroup = "OpenID Connect"
keyword = ["security", "openid", "enterprise"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-connect-enterprise-extensions-1_0"
status = "standard"

[[author]]
initials="D."
surname="Hardt"
fullname="Dick Hardt"
organization="Hellō"
    [author.address]
    email = "dick.hardt@gmail.com"

[[author]]  
initials="K."
surname="McGuinness"
fullname="Karl McGuinness"
organization="Independent"
    [author.address]
    email = "me@karlmcguinness.com"

%%%

.# Abstract

OpenID Connect 1.0 has become a popular choice for single sign-on in enterprise use cases. To improve interoperability, OpenID Connect Enterprise Extensions specifies a number of common or desirable extensions to OpenID Connect.

{mainmatter}

# Introduction

OpenID Connect 1.0 is a widely adopted identity protocol that enables client applications, known as relying parties (RPs), to verify the identity of end-users based on authentication performed by a trusted service, the OpenID Provider (OP). 

Initial adoption of OpenID Connect was by sites providing personal identity to applications. OpenID Connect has become a popular choice in enterprise use cases, and implementors have defined their own extensions for use cases that were not addressed in the original specification. 

To improve interoperability between systems, OpenID Connect Enterprise Extensions specifies optional claims that may be included in an ID Token, optional parameters that may be included in an authentication request, optional client registration parameters, and optional parameters that may be included when initiating login from a third party.

Enterprise deployments of OpenID Connect often involve multi-tenancy on both sides of the protocol. An OpenID Provider (OP) may serve multiple organizations, each with their own users and policies. Similarly, a Relying Party (RP) may be a SaaS application serving multiple customer organizations, each requiring isolation of their users and data.

This specification addresses three key challenges in multi-tenant deployments:

**OP Tenant Identification**: When an OP serves multiple tenants using a single issuer identifier, the standard `iss` and `sub` claims are insufficient to uniquely identify a user across tenants. This specification defines the `tenant` claim to disambiguate users and the `tenant` and `domain_hint` authentication request parameters to allow RPs to specify which OP tenant to authenticate against.

**RP Tenant Identification**: When an RP serves multiple tenants using a shared client registration, the OP has no standard way to know which RP tenant initiated the authentication request. This specification defines the `client_tenant` authentication request parameter and the `aud_tenant` ID Token claim to enable RPs to communicate their tenant context to the OP, allowing the OP to apply tenant-specific policies and echo the tenant identifier back in the token.

**Account Linking**: When an OP maintains account linkages to RP accounts, the standard claims do not provide a mechanism to communicate the RP's account identifier. This specification defines the `aud_sub` claim to allow the OP to include the RP's account identifier in the ID Token, and the `aud_tenant` claim to scope that identifier to a specific RP tenant when applicable.

## Requirements Notation and Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [RFC2119](#RFC2119).

In the .txt version of this specification,
values are quoted to indicate that they are to be taken literally.
When using these values in protocol messages,
the quotes MUST NOT be used as part of the value.
In the HTML version of this specification,
values to be taken literally are indicated by
the use of *this fixed-width font*.

## Terminology

This specification defines the following terms:

- **Account**: A set of claims about a user.

- **Tenant**: A logically isolated entity that represents a distinct organizational or administrative boundary. A tenant may contain accounts managed by individuals or by an organization. Both an OpenID Provider (OP) and a Relying Party (RP) may have a single tenant or multiple tenants. When referring to a tenant within an OP, it is called an "OP tenant". When referring to a tenant within an RP, it is called an "RP tenant".

# ID Token Claims

An ID Token is defined in Section 2 of [OpenID Connect Core 1.0](#OpenID Connect Core 1.0). 

Following are OPTIONAL claims that may be included in an ID Token:

## session_expiry

The `session_expiry` claim is a JSON integer that represents the Unix timestamp (seconds since epoch) indicating when a session created from the ID Token MUST expire. 

## tenant

The `tenant` claim is a JSON string that represents an OP tenant identifier. This claim is OPTIONAL and MAY be included in ID Tokens.

The following well-known values are defined for the `tenant` claim:

- `personal`: Indicates that accounts are managed by individuals rather than by a specific organizational tenant.
- `organization`: Indicates that accounts are managed by an organization.

- **Single-tenant OPs**: Single-tenant OPs MAY include the `tenant` claim. If included, the value MUST be `personal` or `organization`.

- **Multi-tenant OPs using a single issuer**: Multi-tenant OPs using a single issuer identifier SHOULD include the `tenant` claim to identify the OP tenant. The value MUST be `personal` or a stable, opaque to the RP, OP unique tenant identifier.

  - The combination of `iss`, `tenant`, and `sub` MUST be unique across all OP tenants.
  - If the OP uses `pairwise` subject identifiers, the same user MAY have the same `sub` for the same `client_id` regardless of OP tenant. The `tenant` claim SHOULD be included in the uniqueness requirement (`iss` + `tenant` + `sub`) to disambiguate subjects across tenants.
  - If the OP uses `public` subject identifiers, the `sub` value MUST be the same across all RPs/clients and all OP tenants. The `tenant` claim MUST be included in the uniqueness requirement (`iss` + `tenant` + `sub`) to disambiguate subjects across tenants.

- **Multi-tenant OPs using tenant-specific issuer identifiers**: Multi-tenant OPs using tenant-specific issuer identifiers SHOULD omit the `tenant` claim since the issuer identifier itself identifies the tenant. If the `tenant` claim is included, the value MUST be `personal` or `organization`.

  - Each tenant issuer identifier MUST be a valid URL per [OpenID Connect Core 1.0] Section 2.
  - The combination of `iss` and `sub` MUST be unique per tenant.
  - If the OP uses `pairwise` subject identifiers, the `sub` value MUST differ across `client_id` values within each tenant. The combination of `iss` + `client_id` + `sub` MUST be unique across all tenants.
  - If the OP uses `public` subject identifiers, the `sub` value MUST be the same across all RPs/clients within each tenant. The `sub` value MAY be the same across tenants, but the combination of `iss` + `sub` MUST be unique across all tenants.

- **Discovery**: If an OP publishes support for the `tenant` claim in the `claims_supported` metadata parameter (see [OpenID Connect Discovery 1.0]), then RPs SHOULD assume that the issuer is a multi-tenant OP using a single issuer identifier and SHOULD expect the `tenant` claim to be present in ID Tokens. The `tenant` claim value MUST be one of the allowed values for the corresponding OP model as specified in the table below.

The following table summarizes the `tenant` claim rules by OP model:

| OP Model | Allowed Values |
|----------|----------------|
| Single-tenant | `personal` or `organization` |
| Multi-tenant (single issuer) | `personal` or unique tenant identifier |
| Multi-tenant (tenant-specific issuers) | `personal` or `organization` |

## aud_sub

The `aud_sub` claim is an opaque JSON string that represents the identifier the RP has for the account. This claim is OPTIONAL. How the OP acquires the `aud_sub` and how the OP account and RP account linking is established is out of scope of this specification.

The `aud_sub` value MUST be unique within the context of the `client_id`.

When the `aud_tenant` claim is present, the `aud_sub` claim represents the account identifier within the context of that specific RP tenant. See Section "aud_tenant" for uniqueness requirements.

## aud_tenant

The `aud_tenant` claim is a JSON string that represents an RP tenant identifier. This claim is OPTIONAL and is only included when the RP is multi-tenant and the OP knows the RP tenant identifier (see [Appendix A](#enterprise-tenancy-models) for how the RP communicates its tenant identifier to the OP).

When the RP provides the `client_tenant` authentication request parameter, the `aud_tenant` claim value MUST be the same value that the RP provided in that parameter. When the OP determines the RP tenant identifier through other means (e.g., `domain_hint`, `login_hint`, default tenant selection, or end-user selection), the `aud_tenant` claim value MUST be a valid RP tenant identifier for the client. The value is opaque to the OP (the OP does not need to understand its semantic meaning). The value MUST be a stable identifier that is unique within the context of the `client_id` used in the authentication request, ensuring that when multiple RP tenants share the same `client_id`, each tenant can be uniquely identified.

When `aud_tenant` is present, the `aud_sub` claim represents the identifier the RP has for the account within the context of that specific RP tenant. The combination of `aud` + `aud_tenant` and `aud_sub` MUST be unique within the RP.

# Authentication Request Parameters

An Authentication request is defined in Section 3.1.2.1 of [OpenID Connect Core 1.0].

Following are OPTIONAL parameters that may be included in an Authentication Request:

## domain_hint

The `domain_hint` parameter provides a hint for the OP to determine which OP tenant to present to the user to authenticate to. This parameter is typically a domain name or email domain (e.g., `example.com`) that helps the OP identify the appropriate tenant. The `domain_hint` parameter is a user experience hint and is not guaranteed to uniquely identify a tenant.

## tenant

The `tenant` parameter is the explicit OP tenant identifier value that corresponds to the `tenant` claim the RP would like included in the ID Token. This parameter takes precedence over `domain_hint` when both are present. 

The `tenant` parameter value MUST be one of the allowed values for the OP model as specified in the table in [Section "tenant"](#tenant):

- The value `personal` to indicate the RP would like the user to use a personal account (valid for all OP models)
- The value `organization` to indicate the RP would like the user to use an organizational account (valid for single-tenant OPs and multi-tenant OPs using tenant-specific issuers only)
- A stable, opaque OP tenant identifier (valid for multi-tenant OPs using a single issuer only)

If the `tenant` parameter value does not match any OP tenant, the OP SHOULD return an `invalid_request` error or proceed with the authentication using the OP's default tenant selection logic. The specific behavior is implementation-dependent.

## client_tenant

The `client_tenant` parameter is an OPTIONAL parameter that the RP includes to communicate its RP tenant identifier to the OP. This parameter is used when the RP is multi-tenant and uses a shared `client_id` across multiple RP tenants (see [Appendix A](#enterprise-tenancy-models) for details on multi-tenant RP models).

The client MAY register allowed tenants using the `tenants` client registration parameter. When the `client_tenant` authentication request parameter is provided, the OP SHOULD validate that the `client_tenant` value corresponds to a valid RP tenant identifier that was registered for this client.

The `client_tenant` parameter value MUST be a stable identifier that is unique within the context of the `client_id` used in the authentication request, ensuring that when multiple RP tenants share the same `client_id`, each tenant can be uniquely identified. The value is opaque to the OP (the OP does not need to understand its semantic meaning) and MUST be echoed back in the `aud_tenant` claim.

The OP MUST treat the `redirect_uri` as opaque and MUST NOT attempt to identify an RP tenant from a specific URL endpoint or pattern.

When the RP uses only the `state` parameter or session context for tenant routing and does not provide a `client_tenant` parameter, the OP MUST omit the `aud_tenant` claim from the ID Token.

If the `client_tenant` parameter is provided but the OP cannot determine the corresponding RP tenant (e.g., the value doesn't match any registered tenant identifier for the `client_id`), the OP SHOULD return an `invalid_request` error with an appropriate error description.

If an RP is multi-tenant and uses a shared `client_id` but does not provide a `client_tenant` parameter, the OP MAY:
- Attempt to resolve the RP tenant identifier using other available information (e.g., `domain_hint`, `login_hint`)
- Select a default tenant for the client or fallback behavior (implementation-dependent)
- Prompt the end-user to select a valid tenant for the client
- Return an `invalid_request` error indicating that tenant identification is required

If the OP successfully determines the RP tenant identifier through any of these means, it SHOULD include it in the `aud_tenant` claim of the ID Token.

If the OP does not support RP tenant identification and receives a `client_tenant` parameter, the OP SHOULD ignore the parameter and MUST omit the `aud_tenant` claim from the ID Token.

# Client Registration Parameters

Client registration is defined in [OpenID Connect Dynamic Client Registration 1.0].

Following are OPTIONAL client registration parameters that may be included during client registration:

## tenants

The `tenants` parameter is a JSON array of strings that represents RP tenant identifiers. This parameter is OPTIONAL and MAY be included during client registration.

When the `client_tenant` authentication request parameter is provided, the OP MAY use the `tenants` client registration parameter to validate that the `client_tenant` value corresponds to a valid RP tenant identifier that was registered for this client. The OP can use this information to apply RP tenant-specific policies or to validate the authentication request.

If an RP registers the `tenants` client registration parameter, OPs SHOULD assume the RP is multi-tenant.

For example:

```json
{
  "client_id": "rp-shared-abcde",
  "redirect_uris": ["https://app.example.com/callback"],
  "tenants": ["acme-corp-tenant-id", "widgets-inc-tenant-id"]
}
```

# Login from a Third Party Parameters

Initiating a login from a third party and a login initiation endpoint are defined in Section 4 of [OpenID Connect Core 1.0].

Following are OPTIONAL parameters that may be included in request to the login initiation endpoint:

## client_id

The `client_id` value the RP should use when making the Authentication Request. This allows a multi-tenant application that hosts multiple tenants, each represented by a different `client_id`, to know which `client_id` to use.

## domain_hint

The `domain_hint` value to be included in the Authentication Request.

## tenant

The `tenant` value to be included in the Authentication Request.

## client_tenant

The `client_tenant` value to be included in the Authentication Request.

# Security Considerations

## OP Security Considerations

### Tenant Isolation

OPs MUST ensure strict isolation between tenants. An authenticated user from one OP tenant MUST NOT be able to obtain tokens containing a different tenant's identifier. The OP MUST validate that the `tenant` claim (see [Section "ID Token Claims"](#id-token-claims)) in issued ID Tokens accurately reflects the tenant context in which the user authenticated.

### Client Tenant Validation

When the OP receives a `client_tenant` authentication request parameter (see [Section "Authentication Request Parameters"](#authentication-request-parameters)), the OP SHOULD validate that the value corresponds to a registered RP tenant identifier for the given `client_id`. If the OP has registered the `tenants` client registration parameter (see [Section "Client Registration Parameters"](#client-registration-parameters)) for the client, the OP SHOULD reject requests where `client_tenant` is not in the registered list.

Failure to validate the `client_tenant` parameter could allow an attacker to request tokens for arbitrary RP tenants, potentially bypassing RP tenant-specific policies configured at the OP.

### Subject Identifier Collision

Multi-tenant OPs MUST ensure that subject identifiers are unambiguous across tenants to prevent account confusion where an RP incorrectly links accounts from different OP tenants.

For multi-tenant OPs using a single issuer (see [Appendix A](#enterprise-tenancy-models)), the OP MUST ensure that subject identifiers are unambiguous across tenants. If the same `sub` value could exist in multiple OP tenants, the OP MUST include the `tenant` claim (see [Section "ID Token Claims"](#id-token-claims)) in the ID Token to enable RPs to correctly identify the account. The combination of `iss` + `tenant` + `sub` (for public subject identifiers) or `iss` + `tenant` + `client_id` + `sub` (for pairwise subject identifiers) MUST be unique across all tenants (see [Appendix A](#enterprise-tenancy-models) for detailed requirements).

For multi-tenant OPs using tenant-specific issuer identifiers (see [Appendix A](#enterprise-tenancy-models)), the OP MUST ensure that the combination of `iss` + `sub` (for public subject identifiers) or `iss` + `client_id` + `sub` (for pairwise subject identifiers) is unique across all tenants. Since each tenant has a different issuer identifier, the OIDC Core requirement that `sub` is unique within `iss` already ensures tenant isolation. However, the OP MUST ensure uniqueness across all tenants, regardless of whether a client is shared across tenants or unique per tenant (see [Appendix A](#enterprise-tenancy-models) for detailed requirements).

### Token Injection Prevention

OPs SHOULD implement measures to prevent token injection attacks where an attacker attempts to replay tokens across tenant boundaries. This includes ensuring that tokens issued for one tenant context cannot be used to authenticate to a different tenant.

## RP Security Considerations

### Tenant Claim Validation

When an RP expects to receive the `tenant` claim (see [Section "ID Token Claims"](#id-token-claims)) (e.g., when authenticating to a multi-tenant OP using a single issuer, as described in [Appendix A](#enterprise-tenancy-models)), the RP MUST validate that the `tenant` claim is present in the ID Token. If the RP has prior knowledge of the expected tenant (e.g., from a previous authentication or configuration), the RP SHOULD validate that the received `tenant` claim matches the expected value.

Failure to validate the `tenant` claim could result in:
- Account confusion where users from different OP tenants are incorrectly linked
- Privilege escalation if tenant-specific access controls are bypassed

### aud_tenant Claim Validation

When an RP sends the `client_tenant` authentication request parameter (see [Section "Authentication Request Parameters"](#authentication-request-parameters)), the RP MUST validate that the returned `aud_tenant` claim (see [Section "ID Token Claims"](#id-token-claims)) matches the value sent in the request. If the `aud_tenant` claim is missing or contains a different value, the RP MUST reject the ID Token.

This validation prevents an attacker from obtaining a token intended for one RP tenant and using it to authenticate to a different RP tenant. See [Appendix A](#enterprise-tenancy-models) for details on how the `client_tenant` parameter relates to the `aud_tenant` claim.

### Account Identifier Uniqueness

RPs MUST use the complete set of identifying claims when linking accounts:
- For multi-tenant OPs using a single issuer (see [Appendix A](#enterprise-tenancy-models)): `iss` + `tenant` (see [Section "ID Token Claims"](#id-token-claims)) + `sub`
- For multi-tenant OPs using tenant-specific issuers (see [Appendix A](#enterprise-tenancy-models)): `iss` + `sub`
- For multi-tenant RPs with shared `client_id` (see [Appendix A](#enterprise-tenancy-models)): `aud` + `aud_tenant` (see [Section "ID Token Claims"](#id-token-claims)) + `aud_sub` (see [Section "ID Token Claims"](#id-token-claims)) (when present)

Using only a subset of these claims (e.g., only `sub`) could result in incorrectly linking accounts from different tenants.

### Cross-Tenant Request Forgery

Multi-tenant RPs MUST ensure that authentication responses are processed in the correct tenant context. When using the `state` parameter or session context for tenant routing, the RP MUST validate that the response is processed by the same tenant that initiated the request. Failure to do so could allow an attacker to initiate authentication in one RP tenant and have the response processed in a different RP tenant.

# Privacy Considerations

*To be completed.*

# IANA Considerations

*To be completed.*

# References

## Normative References

- **[RFC2119]** Bradner, S. "Key words for use in RFCs to Indicate Requirement Levels," *RFC 2119*, March 1997.
- **[OpenID Connect Core 1.0]** – "OpenID Connect Core 1.0 incorporating errata set 2," available at <https://openid.net/specs/openid-connect-core-1_0.html>.
- **[OpenID Connect Discovery 1.0]** – "OpenID Connect Discovery 1.0 incorporating errata set 2," available at <https://openid.net/specs/openid-connect-discovery-1_0.html>.
- **[OpenID Connect Dynamic Client Registration 1.0]** – "OpenID Connect Dynamic Client Registration 1.0 incorporating errata set 2," available at <https://openid.net/specs/openid-connect-registration-1_0.html>. 

## Informative References

- **IANA JSON Web Token Claims Registry**, available at <https://www.iana.org/assignments/jwt/jwt.xhtml>.
- **IANA OAuth Parameters**, available at <https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml#client-metadata>.

{backmatter}

# Enterprise Tenancy Models

This appendix is non-normative.

This appendix explains the relationships between issuer, client, and tenant for an OpenID Provider (OP) and Relying Party (RP). Understanding these models is helpful for correctly implementing the claims and parameters defined in this specification.

The following diagram illustrates the relationship between OP tenants, RP tenants, and accounts:

```
┌─────────────────────────────────────────────────────────────┐
│                  OpenID Provider (OP)                       │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ OP Tenant A  │  │ OP Tenant B  │  │ OP Tenant C  │       │
│  │              │  │              │  │              │       │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │       │
│  │ │ Account 1│ │  │ │ Account 1│ │  │ │ Account 1│ │       │
│  │ │ Account 2│ │  │ │ Account 2│ │  │ │ Account 2│ │       │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                             │
│  Identified by: `iss` + `tenant` (single issuer model)      │
│  or by: `iss` alone (tenant-specific issuer model)          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Authentication
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Relying Party (RP)                         │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │ RP Tenant X  │  │ RP Tenant Y  │                         │
│  │              │  │              │                         │
│  │ ┌──────────┐ │  │ ┌──────────┐ │                         │
│  │ │ Account 1│ │  │ │ Account 1│ │                         │
│  │ │ Account 2│ │  │ │ Account 2│ │                         │
│  │ └──────────┘ │  │ └──────────┘ │                         │
│  └──────────────┘  └──────────────┘                         │
│                                                             │
│  Identified by: `aud` (unique client per tenant)            │
│  or by: `aud` + `aud_tenant` (shared client model)          │
└─────────────────────────────────────────────────────────────┘
```

## OP Tenancy

An OP can have a single-tenant issuer or a multi-tenant issuer:

- **Single-tenant OP**: The OP has a single tenant. All accounts are associated with this single tenant.

  - **Issuer Configuration**: The issuer identifier (`iss`) uniquely identifies the OP. The OP has a single OP metadata endpoint and signing keys.

  - **Subject Identifier Uniqueness**:
    - If the OP uses `pairwise` subject identifiers, the `sub` value for the same user will differ across different `client_id` values.
    - If the OP uses `public` subject identifiers, the `sub` value will be the same across all RPs/clients.

  For example:

  ```json
  {
    "iss": "https://idp.example.com",
    "sub": "user123"
  }
  ```

- **Multi-tenant OP**: The OP has multiple tenants. Multi-tenant OPs may use a single issuer identifier for all tenants, or tenant-specific issuer identifiers:
  - **Single issuer for all tenants**: The OP uses one issuer identifier for all tenants, and the `tenant` claim (see [Section "ID Token Claims"](#id-token-claims)) distinguishes between tenants.

    - **Issuer Configuration**: All tenants share the same issuer identifier (`iss`), OP metadata endpoint, and signing keys.

    - **Subject Identifier Uniqueness**:
      - The combination of `iss` (issuer identifier), `tenant` (OP tenant identifier), and `sub` (subject identifier) MUST be unique across all tenants. This ensures that a subject identifier is unambiguous within the context of the OP, even when the same `sub` value might exist in different OP tenants.
      - If the OP uses `pairwise` subject identifiers, the `sub` value for the same user MUST differ across different `client_id` values, but the same user MAY have the same `sub` value for the same `client_id` regardless of which OP tenant they authenticate to.  The OP is not required to have unique `pairwise` subject identifiers for clients that are shared across tenants per [OpenID Connect Core 1.0] Section 8.1. The `tenant` claim SHOULD be included in the uniqueness requirement (`iss` + `tenant` + `sub`) to disambiguate subjects across tenants.
      - If the OP uses `public` subject identifiers, the `sub` value MUST be the same across all RPs/clients and all OP tenants. The `tenant` claim MUST be included in the uniqueness requirement (`iss` + `tenant` + `sub`) to disambiguate subjects across tenants.

    For example:

    Acme Corporation OP Tenant
    ```json
    {
      "iss": "https://idp.example.com",
      "tenant": "acme-corp",
      "sub": "user123"
    }
    ```

    Widgets Inc. OP Tenant
    ```json
    {
      "iss": "https://idp.example.com",
      "tenant": "widgets-inc",
      "sub": "user456"
    }
    ```

  - **Tenant-specific issuer identifiers**: The OP uses different issuer identifiers per tenant.

    - **Issuer Configuration**: Each tenant has its own issuer identifier (`iss`), OP metadata endpoint, and signing keys. Each issuer identifier MUST be a valid URL per [OpenID Connect Core 1.0] Section 2.

    - **Subject Identifier Uniqueness**:
      - The combination of `iss` (issuer identifier) and `sub` (subject identifier) MUST be unique. Since each issuer identifier identifies a specific tenant, the OIDC Core requirement that `sub` is unique within `iss` already ensures tenant isolation.
      - If the OP uses `pairwise` subject identifiers, the `sub` value for the same user MUST differ across different `client_id` values within each tenant. The combination of `iss` + `client_id` + `sub` MUST be unique across all tenants, regardless of whether a client is shared across tenants or unique per tenant, since each tenant has a different issuer identifier.
      - If the OP uses `public` subject identifiers, the `sub` value MUST be the same across all RPs/clients within each tenant. The `sub` value MAY be the same across tenants (a global `sub`), but the combination of `iss` + `sub` MUST be unique across all tenants since each tenant has a different issuer identifier.

    For example:

    Acme Corporation OP Tenant
    ```json
    {
      "iss": "https://acme-corp.idp.example.com",
      "sub": "user123"
    }
    ```

    Widgets Inc. OP Tenant
    ```json
    {
      "iss": "https://widgets-inc.idp.example.com",
      "sub": "user456"
    }
    ```

The following table summarizes OP tenancy models:

| Model | Issuer Configuration | Uniqueness Requirement | Tenant Identification |
|-------|---------------------|------------------------|---------------------|
| Single-tenant OP | Single `iss`, single metadata endpoint, single signing keys | `public`: `sub` unique within `iss`<br/>`pairwise`: `iss` + `client_id` + `sub` unique | Not applicable |
| Multi-tenant OP (single issuer) | Single `iss` shared across tenants, single metadata endpoint, single signing keys | `public`: `iss` + `tenant` + `sub` unique<br/>`pairwise`: `iss` + `tenant` + `client_id` + `sub` unique | `tenant` claim in ID Token (see [Section "ID Token Claims"](#id-token-claims)) |
| Multi-tenant OP (tenant-specific issuers) | Each tenant has own `iss`, metadata endpoint, and signing keys | `public`: `iss` + `sub` unique (per tenant)<br/>`pairwise`: `iss` + `client_id` + `sub` unique (per tenant) | `iss` value identifies tenant |

- **Discovery**: If an OP publishes support for the `tenant` claim in the `claims_supported` metadata parameter (see [OpenID Connect Discovery 1.0]), then RPs SHOULD assume that the issuer is a multi-tenant OP using a single issuer identifier and SHOULD expect the `tenant` claim to be present in ID Tokens. The `tenant` claim value MUST be one of the allowed values for the corresponding OP model as specified in the table in [Section "tenant"](#tenant).

## OP Tenant Communication

When the OP uses tenant-specific issuer identifiers, the RP authenticates to the appropriate issuer endpoint (e.g., `https://acme-corp.idp.example.com`), and the tenant is identified by the issuer identifier itself. In that model, OP tenant communication is not required.

The following applies only to multi-tenant OPs that use a single issuer for all tenants. For such OPs, the RP MAY specify which OP tenant it wants the user to authenticate to using one of the following mechanisms:

- **`tenant` parameter**: The RP includes the `tenant` parameter in the authentication request with the OP tenant identifier value (e.g., `tenant=acme-corp`). When the OP receives this parameter, it SHOULD include the `tenant` claim in the ID Token with the same value. This is RECOMMENDED for RPs that know which `tenant` to make an authentication request to. See [Section "Authentication Request Parameters"](#authentication-request-parameters) for details.

- **`domain_hint` parameter**: The RP includes the `domain_hint` parameter with a domain name or email domain (e.g., `example.com`) that helps the OP identify the appropriate tenant. This is a user experience hint and is not guaranteed to uniquely identify a tenant. When both `tenant` and `domain_hint` are present, the `tenant` parameter takes precedence. If the OP cannot uniquely identify the tenant from `domain_hint` alone, the OP's tenant selection behavior is implementation-dependent. See [Section "Authentication Request Parameters"](#authentication-request-parameters) for details.

When the OP tenant is not specified by the RP (neither `tenant` nor `domain_hint` is provided, or `domain_hint` does not uniquely identify a tenant), the OP MAY:
- Provide a selector to allow the end-user to pick the tenant during authentication
- Default to a specific tenant for the `client_id` and/or `login_hint`
- Reject the request with an `invalid_request` error

The following diagram illustrates OP tenant communication flow:

```
┌─────────────────────┐                    ┌─────────────────────┐
│         RP          │                    │         OP          │
│                     │                    │                     │
│ 1. RP determines    │                    │                     │
│    desired OP       │                    │                     │
│    tenant           │                    │                     │
│    (from user       │                    │                     │
│    input, config,   │                    │                     │
│    etc.)            │                    │                     │
│                     │                    │                     │
│ 2. Authentication   │                    │                     │
│    Request          │                    │                     │
│    ├─ tenant=acme-  │                    │                     │
│    │  corp          │                    │                     │
│    │  (explicit)    │                    │                     │
│    └─ OR            │                    │                     │
│       domain_hint=  │                    │                     │
│       acme.com      │                    │                     │
│       (hint)        │                    │                     │
│         │───────────────────────────────>│                     │
│         │                                │                     │
│         │                                │ 3. OP resolves      │
│         │                                │    tenant context   │
│         │                                │                     │
│         │                                │ 4. User auth        │
│         │                                │                     │
│         │ 5. ID Token                    │                     │
│         │    └─ tenant: "acme-corp"      │                     │
│         │<───────────────────────────────│                     │
│         │                                │                     │
│ 6. RP validates     │                    │                     │
│    tenant claim     │                    │                     │
│    matches expected │                    │                     │
│    tenant           │                    │                     │
└─────────────────────┘                    └─────────────────────┘
```

## RP Tenancy

An RP can be single-tenant or multi-tenant:

- **Single-tenant RP**: The RP has a single tenant. All accounts are associated with this single tenant.

  - **Registration**: The RP registers a single `client_id` with the OP issuer.

  - **Account Identifier Uniqueness**: Account identifiers (such as `aud_sub` if present) MUST be unique within the context of that `client_id`.

  For example:
  ```json
  {
    "iss": "https://idp.example.com",
    "sub": "user123",
    "aud": "rp-single-tenant-xyz",
    "aud_sub": "rp-account-123"
  }
  ```

- **Multi-tenant RP**: The RP has multiple tenants. Each tenant represents a distinct organizational or administrative boundary within the RP. Accounts are specific to the RP tenant. When an RP is multi-tenant, it needs to structure its client registration with the OP so that the OP can identify which RP tenant is making an authentication request. Multi-tenant RPs can use one of the following approaches:
  - **Unique Client per Tenant**: Each RP tenant has its own unique `client_id` registered with the OP issuer.
    - **Registration**: Each RP tenant registers its own unique `client_id` with the OP issuer.
    - **Account Identifier Uniqueness**: Account identifiers (such as `aud_sub` if present) MUST be unique within the context of that `client_id`.

    For example:
    - RP tenant "Acme Corp" uses `client_id`: `rp-acme-corp-12345`
      ```json
      {
        "iss": "https://idp.example.com",
        "sub": "user123",
        "aud": "rp-acme-corp-12345",
        "aud_sub": "acme-account-456"
      }
      ```
    - RP tenant "Widgets Inc" uses `client_id`: `rp-widgets-inc-67890`
      ```json
      {
        "iss": "https://idp.example.com",
        "sub": "user123",
        "aud": "rp-widgets-inc-67890",
        "aud_sub": "widgets-account-789"
      }
      ```

  - **Shared Client for all Tenants**: Multiple RP tenants share a single `client_id` registered with the OP.
    - **Registration**: All RP tenants share a single `client_id` registered with the OP. The RP MAY register the `tenants` client registration parameter (see [Section "Client Registration Parameters"](#client-registration-parameters)) as a JSON array of strings containing the RP tenant identifiers.
    - **Account Identifier Uniqueness**: When both `aud_tenant` and `aud_sub` are present, their combination MUST be unique for a given `aud` (client identifier) within the RP. This ensures that account identifiers are unambiguous within the context of the RP, even when the same `aud_sub` value might exist in different RP tenants.

    For example:
    - All RP tenants share `client_id`: `rp-shared-abcde`
    - RP tenant "Acme Corp" is identified by the `aud_tenant` claim in the ID Token:
      ```json
      {
        "iss": "https://idp.example.com",
        "sub": "user123",
        "aud": "rp-shared-abcde",
        "aud_tenant": "acme-corp-tenant-id"
      }
      ```
    - RP tenant "Widgets Inc" is identified by the `aud_tenant` claim in the ID Token:

      ```json
      {
        "iss": "https://idp.example.com",
        "sub": "user456",
        "aud": "rp-shared-abcde",
        "aud_tenant": "widgets-inc-tenant-id"
      }
      ```

The following table summarizes RP tenancy models:

| Model | Registration | Account Identifier Uniqueness | Tenant Identification |
|-------|--------------|------------------------------|----------------------|
| Single-tenant RP | Single `client_id` registered with OP issuer | `aud_sub` unique within `client_id` | Not applicable |
| Multi-tenant RP (unique client per tenant) | Each tenant has own `client_id` registered with OP issuer | `aud_sub` unique within `client_id` | `aud` identifies tenant |
| Multi-tenant RP (shared client) | Single `client_id` shared across tenants, `tenants` parameter MAY be registered | `aud_tenant` + `aud_sub` unique within `aud` | `aud` + `aud_tenant` claim in ID Token (see [Section "ID Token Claims"](#id-token-claims)) |

- **Discovery**: If an RP supports multiple tenants and registers the `tenants` client registration parameter for the client, then OPs SHOULD assume the RP is multi-tenant.

## RP Tenant Communication

When an RP is multi-tenant and uses a shared `client_id`, the RP MAY communicate its tenant identifier to the OP, but is not required to do so. If the OP knows the RP tenant identifier, it SHOULD include it in the `aud_tenant` claim of the ID Token (see [Section "ID Token Claims"](#id-token-claims)).

The RP can communicate its tenant identifier using one of the following mechanisms:

- **`client_tenant` authentication request parameter** (RECOMMENDED): The RP includes the `client_tenant` parameter in the authentication request with its tenant identifier value. This is explicit and unambiguous, allowing the OP to include the `aud_tenant` claim in the ID Token and apply RP tenant-specific policies (e.g., access control, consent requirements, authentication methods). When present, the OP MUST echo this value back in the `aud_tenant` claim. See [Section "Authentication Request Parameters"](#authentication-request-parameters) for details.

- **`state` parameter or session context**: RPs may include tenant identification information in the opaque `state` parameter of the OpenID Connect Authentication Request, or maintain tenant context via cookies or other session mechanisms. When the RP uses only this mechanism, the OP does not have access to the tenant identifier and MUST omit the `aud_tenant` claim from the ID Token. The OP cannot apply RP tenant-specific policies, and the RP MUST use implementation-specific mechanisms (such as parsing the `state` parameter or session context) to determine the tenant for routing the authentication response. This pattern is commonly used in practice.

- **`redirect_uri`**: RPs may register a `redirect_uri` per tenant and include the specific tenant redirect_uri in the OpenID Connect Authentication Request. The OP MUST treat the `redirect_uri` as opaque and MUST NOT attempt to identify a tenant from a specific URL endpoint or pattern. This mechanism only enables RP-side tenant routing; the OP cannot apply RP tenant-specific policies using this approach.

If the RP does not provide a `client_tenant` parameter and the OP cannot determine the RP tenant identifier from other mechanisms (such as `state` or `redirect_uri`), the OP MAY attempt to resolve the RP tenant using other available information (e.g., `domain_hint`, `login_hint`) or MAY select a default tenant for the client, or MAY prompt the end-user to select a valid tenant for the client. If the OP successfully determines the RP tenant identifier through any of these means, it SHOULD include it in the `aud_tenant` claim of the ID Token.

The following diagram illustrates RP tenant communication flow:

```
┌─────────────────────┐                    ┌─────────────────────┐
│         RP          │                    │         OP          │
│                     │                    │                     │
│ 1. RP identifies    │                    │                     │
│    its tenant       │                    │                     │
│    context          │                    │                     │
│    (e.g., from URL, │                    │                     │
│    session, config) │                    │                     │
│                     │                    │                     │
│ 2. Authentication   │                    │                     │
│    Request          │                    │                     │
│    └─ client_tenant=│                    │                     │
│       acme-corp-    │                    │                     │
│       tenant-id     │                    │                     │
│         │───────────────────────────────>│                     │
│         │                                │                     │
│         │                                │ 3. OP validates     │
│         │                                │    client_tenant    │
│         │                                │    (if tenants      │
│         │                                │    registered)      │
│         │                                │                     │
│         │                                │ 4. User auth        │
│         │                                │                     │
│         │ 5. ID Token                    │                     │
│         │    └─ aud_tenant:              │                     │
│         │        "acme-corp-tenant-id"   │                     │
│         │<───────────────────────────────│                     │
│         │                                │                     │
│ 6. RP validates     │                    │                     │
│    aud_tenant claim │                    │                     │
│    matches          │                    │                     │
│    client_tenant    │                    │                     │
│    sent and routes  │                    │                     │
│    to correct       │                    │                     │
│    tenant           │                    │                     │
└─────────────────────┘                    └─────────────────────┘
```

# Acknowledgements

*To be updated.*

# Notices

Copyright (c) 2025 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer,
implementer, or other interested party a non-exclusive, royalty free,
worldwide copyright license to reproduce, prepare derivative works from,
distribute, perform and display, this Implementers Draft, Final
Specification, or Final Specification Incorporating Errata Corrections
solely for the purposes of (i) developing specifications,
and (ii) implementing Implementers Drafts, Final Specifications,
and Final Specification Incorporating Errata Corrections based
on such documents, provided that attribution be made to the OIDF as the
source of the material, but that such attribution does not indicate an
endorsement by the OIDF.

The technology described in this specification was made available
from contributions from various sources, including members of the OpenID
Foundation and others. Although the OpenID Foundation has taken steps to
help ensure that the technology is available for distribution, it takes
no position regarding the validity or scope of any intellectual property
or other rights that might be claimed to pertain to the implementation
or use of the technology described in this specification or the extent
to which any license under such rights might or might not be available;
neither does it represent that it has made any independent effort to
identify any such rights. The OpenID Foundation and the contributors to
this specification make no (and hereby expressly disclaim any)
warranties (express, implied, or otherwise), including implied
warranties of merchantability, non-infringement, fitness for a
particular purpose, or title, related to this specification, and the
entire risk as to implementing this specification is assumed by the
implementer. The OpenID Intellectual Property Rights policy
(found at openid.net) requires
contributors to offer a patent promise not to assert certain patent
claims against other contributors and against implementers.
OpenID invites any interested party to bring to its attention any
copyrights, patents, patent applications, or other proprietary rights
that may cover technology that may be required to practice this
specification.

# Document History

   [[ To be removed from the final specification ]]

   -00

   initial draft

   -01

   * added `aud_sub` claim

   -02

   * added `aud_tenant` claim
   * added `client_tenant` authentication request parameter
   * added `tenants` client registration parameter
   * added `client_tenant` to Login from a Third Party parameters
   * added Tenancy Models appendix to describe OP and RP tenancy models and relationships
   * added Security Considerations