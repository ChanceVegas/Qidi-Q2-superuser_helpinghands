There are **multiple** install scripts, ensure you run the right one
To use the install script, ssh into your printer using `ssh mks@<printer.ip.address>` and enter `makerbase` as the password

This install will install Bunny Box, Helixscreen, and install my custom config changes for a better experience.
Pros and Cons: [Bunny Box](https://github.com/Wazzup77/Bunny-Box) adds improved box functionality, specifically things like faster loading times and improved multicolor.
  [Helixscreen](https://github.com/prestonbrown/helixscreen) makes using the box with Bunny Box installed possible. It has low resource use and is very configurable.
```
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/BB%20%26%20HS.sh | sh
```

This install is for non-box users who wish to retain the stock screen
These changes make the `print_start` macro faster, lowers the bed almost all of the way down during print_end, and adds the `screws_tilt` macro for easy bed leveling setup.
```
curl -sSL https://raw.githubusercontent.com/Camden-Winder/Qidi-Q2-superuser/refs/heads/main/Install%20Script/No%20Box%20-%20No%20HS.sh | sh
```
