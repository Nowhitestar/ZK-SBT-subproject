pragma circom 2.0.0;

include "circuits/lib/credentialMultiQuerySig.circom";

component main{public [challenge,
                        userID,
                        userState,
                        issuerID,
                        issuerClaimNonRevState,
                        claimSchema,
                        slotIndex,
                        operator,
                        value,
                        timestamp]} = CredentialMultiQuerySig(32, 32, 64, 2);