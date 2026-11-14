# Local Vault

An offline terminal utility for encrypting individual files on macOS and Linux. It requires Node.js 22 or newer on your PATH and uses only built-in modules. Keep `vault.sh` and `vault.mjs` together.

```sh
./vault.sh
# Also works with bash vault.sh or zsh vault.sh.
```

1. On first run, choose a password of at least 14 characters or enter five words of your choice separated by spaces. Record your credential and enter it again to finish setup. Word order and capitalization matter. Subsequent runs ask for the same credential.
2. At `VAULT>`, drag one file from your file manager into the terminal and press Enter. You can also paste its path or use **B** to browse and select a file. For direct import, run `./vault.sh -- "/path/to/file"`.
3. To retrieve a file, press **C** and select it by name. The vault restores it to its original path and opens it in the system's default app. If the original directory is unavailable, the path is occupied, or the encrypted file predates path storage, the vault saves it to your Desktop. If the Desktop filename is already taken, the vault creates a new folder there. Toggle auto-open under **O**. On Linux, checkout uses the desktop location reported by `xdg-user-dir` when available, and auto-open uses `xdg-open`.

The working directory is the starting point for Browse. The project directory is always the location of the vault. Vault imports store files under `.vault/files/` with opaque `.lvlt` names. Checkout leaves the encrypted copy in the vault. When finished with the plaintext checkout, remove it yourself or import it again to save a new encrypted copy. Close other apps that are editing a file before importing it.

## Files and recovery

Import streams the source bytes into an encrypted file. It reads the encrypted copy back, authenticates it, compares the decrypted bytes by SHA-256, and syncs the encrypted file and directory before unlinking the source path. It accepts regular files with one filesystem link, up to 64 GiB minus 32 bytes. It preserves file contents and the filename. Permissions, timestamps, extended attributes, and macOS resource forks are outside the format.

Unlinking removes the source path. Copies may remain in SSD blocks, filesystem snapshots, backups, editor autosaves, or other storage. Files created by checkout are plaintext. An abrupt system stop during checkout can leave a private `.vault-checkout-*` staging directory at the destination.

Keep private backups of `.vault/identity.json` and `.vault/files/` and record the credential separately. Recovery requires all three. To restore, put the original identity and encrypted files back in those locations on either supported platform. The vault directories need mode `700` and the identity file needs mode `600`, owned by your user. The clock at restore time has no effect on the key.

## Reset after forgetting your credential

At the startup menu, choose **R**, or run `./vault.sh --reset`. Type `RESET` to confirm. This erases the encrypted files, vault settings, decryption identity, and any older checkouts still inside the vault. Setup then creates a new identity. The new identity cannot decrypt any files encrypted by the old vault. Plaintext previously checked out elsewhere and external backups are outside the reset.

Open one vault session at a time. If the program was forcibly killed and still reports a lock, make sure every vault session is closed before running `rmdir .vault-session` from the project directory. The next launch finishes any reset that was interrupted after confirmation.

## Encryption

1. scrypt derives a 256-bit value from the credential and a fresh 256-bit setup salt using a 128 MiB work factor.
2. HKDF-SHA-256 mixes it with a fresh 256-bit local secret and includes the setup date and local time to the second and a random 11-digit number as context. The local secret is part of `identity.json`. Reusing a password across independently initialized vaults yields independent keys with negligible collision probability.
3. A fresh 256-bit salt per file drives another HKDF expansion into distinct keys for its original path and contents. AES-256-GCM encrypts and authenticates both. Each encryption uses a fresh nonce.

The setup salt, timestamp, and number do not add password entropy. If someone obtains the identity and files, they can attempt offline password guesses. Guessing resistance depends on the credential and the attacker's resources. Knowing the credential and possessing the original identity is sufficient to unlock the vault.

Cryptographic primitives are provided by [Node.js Crypto](https://nodejs.org/api/crypto.html).
