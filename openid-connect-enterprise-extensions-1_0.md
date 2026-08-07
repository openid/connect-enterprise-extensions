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

Enterprise deployments are often multi-tenant on both sides of the protocol: an OP may serve many organizations, and an RP may be a SaaS application serving many customer organizations. OpenID Connect Core names the OP with `iss`, the Account at the OP with `sub`, and the RP with `aud`. The extensions in this specification name what is left: the OP Tenant with the `tenant` claim, the RP Tenant with the `aud_tenant` claim, and the Account at the RP with the `aud_sub` claim. [Appendix A](#enterprise-tenancy-models) describes the tenancy models these extensions serve, and is non-normative.

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

- **Tenant**: A logically isolated entity that represents a distinct organizational or administrative boundary. A Tenant may contain Accounts managed by individuals, or may contain Accounts managed by an organization.

- **OP Tenant**: A Tenant within an OP. An OP may have a single Tenant, or multiple Tenants.

- **RP Tenant**: A Tenant within an RP. An RP may have a single Tenant, or multiple Tenants.

# ID Token Claims

An ID Token is defined in Section 2 of [OpenID Connect Core 1.0](#OpenID Connect Core 1.0). 

Following are OPTIONAL claims that may be included in an ID Token:

## session_expiry

The `session_expiry` claim is a JSON integer that represents the Unix timestamp (seconds since epoch) indicating when a session created from the ID Token MUST expire. 

## tenant

The `tenant` claim is a JSON string that identifies the OP Tenant the user authenticated to. The value MUST be `personal`, `organization`, or a tenant identifier that is stable, unique within the issuer, and opaque to the RP. The `personal` value is reserved for when Accounts are managed by individuals. The `organization` value is reserved for Accounts managed by an organization.

An OP that uses a distinct issuer identifier per OP Tenant SHOULD omit the `tenant` claim, as `iss` identifies the OP Tenant. If the claim is included, the value MUST be `personal` or `organization`.

An OP that uses a single issuer identifier for multiple OP Tenants SHOULD include the `tenant` claim. The value MUST be `personal` or a tenant identifier.

| OP | `tenant` claim | Value |
|----|----------------|-------|
| Single Tenant | MAY be included | `personal` or `organization` |
| Multiple Tenants, one issuer identifier | SHOULD be included | `personal` or a tenant identifier |
| Multiple Tenants, issuer identifier per Tenant | SHOULD be omitted | `personal` or `organization` |

The `tenant` claim carries Tenant context; it does not participate in subject identifier uniqueness. Per Section 2 of [OpenID Connect Core 1.0](#OpenID Connect Core 1.0), the `sub` value MUST be unique within the issuer, which includes being unique across all OP Tenants sharing that issuer identifier.

An OP that includes the `tenant` claim SHOULD list `tenant` in the `claims_supported` metadata parameter defined in [OpenID Connect Discovery 1.0](#OpenID Connect Discovery 1.0).

## aud_sub

The `aud_sub` claim is an opaque JSON string that represents the identifier the RP has for the Account. How the OP acquires the `aud_sub`, and how the OP Account and RP Account are linked, is out of scope of this specification.

The `aud_sub` value MUST be unique within the `aud`, which includes being unique across all RP Tenants sharing that `client_id`.

## aud_tenant

The `aud_tenant` claim is a JSON string that identifies the RP Tenant the authentication was for. The value MUST be stable and unique within the `aud`, and is opaque to the OP.

If the RP provided the `client_tenant` authentication request parameter, the OP MUST set `aud_tenant` to that value. If the OP determines the RP Tenant by other means, such as `domain_hint`, `login_hint`, a default for the client, or user selection, the OP SHOULD include the `aud_tenant` claim. If the OP does not know the RP Tenant, the OP MUST omit the `aud_tenant` claim.

The `aud_tenant` and `aud_sub` claims are independent; either, both, or neither may be present.

# Authentication Request Parameters

An Authentication Request is defined in Section 3.1.2.1 of [OpenID Connect Core 1.0](#OpenID Connect Core 1.0).

Following are OPTIONAL parameters that may be included in an Authentication Request:

## domain_hint

The `domain_hint` parameter provides a hint for the OP to determine which OP Tenant to present to the user to authenticate to, typically a domain name such as `example.com`. The parameter is a hint and is not guaranteed to identify a single OP Tenant.

## tenant

The `tenant` identifier per the `tenant` claim for the OP Tenant that the RP would like the user to be authenticated to. Passing a `tenant` value of `personal` indicates the RP would like the user to use an Account managed by the user. Passing a `tenant` value of `organization` indicates the RP would like the user to use an Account managed by an organization.

If both the `tenant` and `domain_hint` parameters are present, the `tenant` parameter takes precedence.

If the `tenant` value does not match an OP Tenant, the OP SHOULD return an `invalid_request` error.

## client_tenant

The `client_tenant` identifier per the `aud_tenant` claim for the RP Tenant that the Authentication Request is for. This parameter is used by an RP that shares a `client_id` across multiple RP Tenants.

An OP that supports the `client_tenant` parameter MUST return the value in the `aud_tenant` claim. An OP that does not support the `client_tenant` parameter MUST ignore it and MUST omit the `aud_tenant` claim.

If the client registered the `tenants` client registration parameter and the `client_tenant` value is not one of the registered values, the OP SHOULD return an `invalid_request` error.

The OP MUST treat the `redirect_uri` as opaque and MUST NOT determine an RP Tenant from it.

# Client Registration Parameters

Client registration is defined in [OpenID Connect Dynamic Client Registration 1.0](#OpenID Connect Dynamic Client Registration 1.0).

Following are OPTIONAL parameters that may be included in client registration:

## tenants

The `tenants` parameter is a JSON array of strings containing the RP Tenant identifiers the client may provide in the `client_tenant` authentication request parameter. Registering the `tenants` parameter indicates the RP is multi-tenant and shares the `client_id` across its Tenants.

An OP MAY use the registered values to validate the `client_tenant` parameter and to apply RP Tenant specific policy.

# Login from a Third Party Parameters

Initiating a login from a third party and a login initiation endpoint are defined in Section 4 of [OpenID Connect Core 1.0](#OpenID Connect Core 1.0). 

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

## OP Considerations

### Tenant Isolation

The `tenant` claim MUST reflect the OP Tenant the user authenticated to. A user who authenticated to one OP Tenant MUST NOT be able to obtain an ID Token carrying a different OP Tenant's identifier.

### Subject Identifier Collision

An RP identifies an Account by `iss` and `sub`. An OP serving multiple OP Tenants from a single issuer identifier MUST NOT issue the same `sub` value to different users in different OP Tenants. Doing so would cause an RP to link two users as one. The `tenant` claim does not relax this requirement.

### Client Tenant Validation

The `client_tenant` parameter is supplied by the RP in the Authentication Request. An OP that applies RP Tenant specific policy SHOULD validate the value against the client's registered `tenants`. Without validation, a request can name any RP Tenant and receive that Tenant's policy.

## RP Considerations

### Tenant Claim Validation

An RP that expects the `tenant` claim MUST verify it is present, and, when the RP knows which OP Tenant it expects, that the value matches. An RP that does not validate the claim may link Accounts from different OP Tenants, or apply Tenant specific access control for the wrong Tenant.

### aud_tenant Claim Validation

An RP that provided the `client_tenant` parameter MUST reject the ID Token if the `aud_tenant` claim is absent or has a different value. Without this check, a token obtained for one RP Tenant can be presented to another.

### Account Linking

An RP MUST link Accounts using the full identifier: `iss` and `sub` for the OP Account, and `aud` and `aud_sub` for the RP Account. Linking on `sub` alone will merge users from different OPs or different OP Tenants.

### Cross-Tenant Response Handling

A multi-tenant RP that routes responses using the `state` parameter, a cookie, or session context MUST verify that the Authentication Response is processed in the same RP Tenant context that made the request.

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

An enterprise single sign-on names six things: the OP, the Account at the OP, the OP Tenant, the RP, the Account at the RP, and the RP Tenant. OpenID Connect Core names the first, second, and fourth with `iss`, `sub`, and `aud`. This specification names the rest.

```
 OP                                RP
 iss: https://idp.example.com      aud: rp-shared-abcde

 ┌─────────────┬─────────────┐     ┌─────────────┬─────────────┐
 │ OP Tenant   │ OP Tenant   │     │ RP Tenant   │ RP Tenant   │
 │ acme-corp   │ widgets-inc │     │ acme        │ widgets     │
 │             │             │     │             │             │
 │ sub:user123 │ sub:user456 │     │ aud_sub:a-1 │ aud_sub:w-1 │
 │ sub:user124 │ sub:user457 │     │ aud_sub:a-2 │ aud_sub:w-2 │
 └─────────────┴─────────────┘     └─────────────┴─────────────┘

 the tenant claim names            the aud_tenant claim names
 which column                      which column
```

## An OP with many Tenants

An OP that serves many organizations has made one architectural choice before any RP arrives: whether each Tenant gets its own issuer identifier, or whether all Tenants share one.

**An issuer identifier per Tenant.** Each OP Tenant has its own issuer identifier, metadata document, and signing keys. Nothing further is needed, because `iss` names the Tenant.

```json
{ "iss": "https://acme-corp.idp.example.com", "sub": "user123" }
{ "iss": "https://widgets-inc.idp.example.com", "sub": "user456" }
```

The cost is borne by the RP: every Tenant is a separate OP to discover, configure, and trust.

**One issuer identifier for all Tenants.** All OP Tenants share one issuer identifier, one metadata document, and one set of signing keys. An RP configures the OP once and serves every Tenant. Since `iss` no longer names the Tenant, the OP names it in the `tenant` claim.

```json
{ "iss": "https://idp.example.com",
  "tenant": "acme-corp",   "sub": "user123" }

{ "iss": "https://idp.example.com",
  "tenant": "widgets-inc", "sub": "user456" }
```

In both models `sub` is unique within `iss`, as OpenID Connect Core requires. Two users in two Tenants of the same issuer never share a `sub`. The `tenant` claim answers "which Tenant is this user in", not "which user is this".

| OP | Issuer | OP Tenant identified by |
|----|--------|-------------------------|
| Single Tenant | One issuer identifier | not applicable |
| Multiple Tenants, one issuer identifier | One issuer identifier, metadata document, and set of signing keys for all Tenants | `tenant` claim |
| Multiple Tenants, issuer identifier per Tenant | An issuer identifier, metadata document, and set of signing keys per Tenant | `iss` |

## Choosing the OP Tenant

When one issuer identifier serves many OP Tenants, the RP has three ways to reach the Tenant it wants:

- **`tenant`**, when the RP knows the identifier. This is explicit, and takes precedence over anything else in the request.
- **`domain_hint`**, when the RP only knows the user's domain. The OP resolves it, and may not resolve it to exactly one Tenant.
- **neither**, leaving it to the OP. The OP can present a Tenant selector to the user, default to a Tenant for the `client_id` or the `login_hint`, or reject the request.

However the Tenant was reached, the ID Token carries the `tenant` claim, and the RP checks it against what it asked for.

## An RP with many Tenants

The RP side mirrors the OP side. A SaaS application serving many customer organizations either registers a `client_id` per customer, or registers once and shares it.

**A `client_id` per Tenant.** `aud` names the RP Tenant, the way a per-Tenant issuer identifier names an OP Tenant.

```json
{ "iss": "https://idp.example.com", "sub": "user123",
  "aud": "rp-acme-corp-12345" }

{ "iss": "https://idp.example.com", "sub": "user789",
  "aud": "rp-widgets-inc-67890" }
```

This is what RPs do today when nothing else is available. It does not scale: every new customer is a new client registration, with its own credentials and lifecycle, for what is one application.

**One `client_id` for all Tenants.** The RP registers once, so `aud` is the same for every Tenant. The RP names the Tenant with the `client_tenant` request parameter, and the OP returns it in the `aud_tenant` claim.

```json
{ "iss": "https://idp.example.com", "sub": "user123",
  "aud": "rp-shared-abcde", "aud_tenant": "acme" }

{ "iss": "https://idp.example.com", "sub": "user789",
  "aud": "rp-shared-abcde", "aud_tenant": "widgets" }
```

The RP can register the Tenant identifiers it will use, so the OP can validate them and attach policy to them:

```json
{
  "client_id": "rp-shared-abcde",
  "redirect_uris": ["https://app.example.com/callback"],
  "tenants": ["acme", "widgets"]
}
```

| RP | Registration | RP Tenant identified by |
|----|--------------|-------------------------|
| Single Tenant | One `client_id` | not applicable |
| Multiple Tenants, `client_id` per Tenant | A `client_id` per Tenant | `aud` |
| Multiple Tenants, one `client_id` | One `client_id`, optionally with registered `tenants` | `aud_tenant` claim |

## Telling the OP which RP Tenant

An RP that shares a `client_id` keeps track of its own Tenant across the authentication in one of three ways. Only the first is visible to the OP.

- **`client_tenant`.** The OP sees the RP Tenant, can apply policy for it such as access control, consent, or authentication method, and returns it in the `aud_tenant` claim.
- **`state` or session context.** Common in practice, and invisible to the OP. The RP routes its own response, the OP has nothing to apply policy to, and no `aud_tenant` claim is returned.
- **A `redirect_uri` per Tenant.** Also RP-side only. The OP treats the `redirect_uri` as opaque and does not parse a Tenant out of it. Deriving tenancy from a URL would make the redirection endpoint a protocol field, and would break the moment the RP changed its URL structure.

## Naming the Account at the RP

The `aud_sub` claim is the RP's own identifier for the user, placed in the ID Token by the OP. It lets the OP refer to the user in terms the RP already uses, without the RP having to resolve `sub` first.

An `aud_sub` value is unique within the `aud`, across all of the RP's Tenants and not just within one. `aud` and `aud_sub` are therefore always enough to name the Account. An RP whose per-Tenant identifiers collide across Tenants, a per-Tenant sequential integer for example, constructs an `aud_sub` that does not collide, and keeps the construction to itself.

The `aud_tenant` and `aud_sub` claims are independent. The OP includes each one it knows:

| | no `aud_sub` | `aud_sub` |
|---|---|---|
| **no `aud_tenant`** | the OP knows neither | the OP knows the Account at the RP |
| **`aud_tenant`** | the OP knows the RP Tenant | the OP knows both |

## The whole picture

```
   RP                                                       OP
   │                                                         │
   │  Authentication Request                                 │
   │    tenant=acme-corp        which OP Tenant              │
   │    client_tenant=acme      which RP Tenant              │
   │────────────────────────────────────────────────────────>│
   │                                                         │
   │                                      user authenticates │
   │                                                         │
   │  ID Token                                               │
   │    iss                     which OP                     │
   │    tenant=acme-corp        which OP Tenant              │
   │    sub                     which Account at the OP      │
   │    aud                     which RP                     │
   │    aud_tenant=acme         which RP Tenant              │
   │    aud_sub                 which Account at the RP      │
   │<────────────────────────────────────────────────────────│
   │                                                         │
   │  RP verifies tenant is the OP Tenant it asked for,      │
   │  and aud_tenant is the RP Tenant it asked for           │
   │                                                         │
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

   * clarified `tenant` claim rules by OP model
   * clarified that `sub` uniqueness within the issuer includes uniqueness across OP Tenants
   * clarified that `aud_sub` uniqueness within the `aud` includes uniqueness across RP Tenants
   * added `aud_tenant` claim
   * added `client_tenant` authentication request parameter
   * added `tenants` client registration parameter
   * added `client_tenant` to Login from a Third Party parameters
   * added Security Considerations
   * added Enterprise Tenancy Models appendix
