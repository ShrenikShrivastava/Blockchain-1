# Blockchain-1
### Access-Control Design & Layered Permissions

The `CertifyMe` contract implements a distinct separation of privileges to maintain a tamper-proof registry. The access control is divided into three clear layers: the Owner (administrator), Authorized Issuers (operators), and the Public (verifiers).

The **Owner** is established during contract deployment and holds the exclusive right to add or remove addresses from the `authorizedIssuers` mapping. By restricting administrative actions via the `onlyOwner` modifier, the contract prevents unauthorized entities from manipulating the issuer whitelist.

**Authorized Issuers** are granted the ability to mint new certificates via the `onlyIssuer` modifier. This delegation allows multiple club leaders to operate concurrently without sharing a single admin wallet. Crucially, if an issuer acts maliciously and is removed by the Owner, their address is mapped to `false`. This immediately strips their ability to issue new certificates or revoke past ones, directly satisfying the requirement for strict, real-time permission layering.

**Owner Self-Removal Edge Case:** If the Owner intentionally or accidentally removes their own address from the `authorizedIssuers` mapping, they will immediately lose the ability to issue certificates. However, because the overarching `owner` state variable remains unchanged, they retain administrative rights and can simply call `addIssuer` to reinstate their issuance privileges. This provides a safe, documented fallback while maintaining strict logical boundaries between the "admin" role and the "operator" role.

### Additive Revocation and the Audit Trail

A core tenet of blockchain technology is transparency; therefore, the contract enforces a strict rule against silent data loss. When a certificate is revoked, the contract does not use the `delete` keyword to erase the struct data from the blockchain. Instead, it employs an additive state change.

The `Certificate` struct contains three specific fields to handle this workflow: an `isRevoked` boolean, a `revocationReason` string, and a `revokedBy` address. When a revocation is triggered, the `isRevoked` flag is toggled to true, and the rationale is permanently recorded alongside the revoker's address.

This design choice ensures that all historical data remains fully queryable and auditable. If an issuer goes rogue and wrongfully revokes a student's credential, the public audit trail clearly shows exactly who executed the revocation and what justification they provided. While the `isValidCertificate` view function correctly returns `false` for these revoked entries, anyone querying the student's full history will see the complete, undeleted record, ensuring absolute accountability.
