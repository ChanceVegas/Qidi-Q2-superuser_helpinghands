# Installing Spoolman

Spoolman tracks filament usage, spool weights, and inventory. It installs just like the rest of the Companion stack — another clean Docker container.

---

## Setup steps

1. **Open the `companion` directory** on your printer or server.
2. **Create a new folder** named `Spoolman`.
3. **Inside that folder**, create a file named `docker-compose.yml`.
4. **Paste the following configuration** and adjust paths only if needed:

```yaml
services:
  spoolman:
    image: ghcr.io/donkie/spoolman:latest # Also available at dockerhub: donkieyo/spoolman:latest
    restart: unless-stopped
    volumes:
      # Local data directory → container data directory
      - type: bind
        source: ./data
        target: /home/app/.local/share/spoolman # Do NOT modify this line
    ports:
      # Host port 7912 → container port 8000
      - "7912:8000"
    environment:
      - TZ=Europe/Stockholm # Optional, defaults to UTC
```

5. **Start the container**  
   ```bash
   sudo docker compose up -d
   ```

6. **Open Spoolman in your browser**  
   When the container starts, Docker prints the local URL for the web interface.  
   **Bookmark it immediately** — you’ll use it often.

---

## Optional

- View the project repo:  
  [Spoolman GitHub](https://github.com/Donkie/Spoolman)

- Change the port if 7912 is already in use:  
  Update `"7912:8000"` to any other host port, e.g. `"9000:8000"`.

- Move the data directory:  
  Replace `source: ./data` with an absolute path if you want centralized storage.

---

## Notes

- Spoolman integrates cleanly with Klipper and Moonraker.  
- Once running, you can add spools, track usage, and sync with other tools.

---
