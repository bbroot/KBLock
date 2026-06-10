// Update-lab Ed25519 dev key: generates (or reuses) a base64 seed file and
// prints the matching `SUPublicEDKey`-style base64 public key on stdout.
//
//   swift keygen.swift <seed-file>
//
// CryptoKit keeps the throwaway dev key in a plain file under build/ instead
// of the login keychain (Sparkle's `generate_keys` always goes through the
// keychain). The seed format is compatible with `sign_update --ed-key-file -`.
import CryptoKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: keygen.swift <seed-file>\n".utf8))
    exit(2)
}
let path = CommandLine.arguments[1]

let key: Curve25519.Signing.PrivateKey
if let existing = try? String(contentsOfFile: path, encoding: .utf8),
   let raw = Data(base64Encoded: existing.trimmingCharacters(in: .whitespacesAndNewlines)),
   let parsed = try? Curve25519.Signing.PrivateKey(rawRepresentation: raw) {
    key = parsed
} else {
    key = Curve25519.Signing.PrivateKey()
    try key.rawRepresentation.base64EncodedString()
        .write(toFile: path, atomically: true, encoding: .utf8)
}
print(key.publicKey.rawRepresentation.base64EncodedString())
