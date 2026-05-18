# Filament Configurations

**What this does**  
This file explains how to reorder filament entries so you can add vendors and move the filaments you use most to the top of the printer menu.

**Quick video walkthrough**  
[Short demo video](https://www.youtube.com/watch?v=MS9I-vYy4Fs)

---

## How it works
Each filament entry uses a `filax` index (for example `fila1`, `fila2`, etc.). The printer displays filaments in ascending index order, so changing the index reorders the list.

---

## Step‑by‑step: Reorder filaments
1. **Copy** all filament entries into a text editor. (Any plain text editor works.)
2. **Create** a new file and paste only the filaments you want to keep or reorder.
3. **Renumber** the `filax` index so the filament you want first is `fila1`, the next is `fila2`, and so on.
   - **Example**: If ABS is currently `fila5` and you want it first, change `fila5` → `fila1`.
4. **Save** the new config and upload it to your printer following your usual process.

---

## Example

```text
; original
filax=5 ; ABS

; changed to be first
filax=1 ; ABS
```

For a full example config, see my repository: [filament config file](https://github.com/Camden-Winder/Qidi-Q2-superuser/blob/main/Configurations/filament%20configs.txt)

---

## Troubleshooting
- **Duplicates**: Make sure no two filaments share the same `filax` number.
- **Gaps**: Gaps (e.g., `fila1` then `fila3`) usually work but renumbering consecutively keeps things predictable.
- **Backup**: Always keep a copy of the original config before editing.

---

## Thanks
Thanks to **jarvis5178** for finding this and posting it in the Qidi Discord.

---
