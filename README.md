# Sync-Marketing-Mess

Scripts to download and process the PF Concept marketing data feeds (product +
print data) and extract image filename lists from them.

## Data feeds

Two JSON feeds are downloaded from `https://www.pfconcept.com/portal/datafeed/`:

| Feed | File | Approx size | Format docs |
|------|------|-------------|-------------|
| Print data | `printdata_cse1_fi_v3.json` | ~9 MB (minified) | [PRINTDATA_MODEL.md](PRINTDATA_MODEL.md) |
| Product catalogue | `productfeed_en_v3.json` | ~189 MB (pretty-printed) | [PRODUCTFEED_MODEL.md](PRODUCTFEED_MODEL.md) |

> The `.json` feeds and their `.bak` backups are **git-ignored** — regenerate them
> with the download scripts.

## Scripts

Every script has a Windows (PowerShell, `.ps1`) and a Linux/macOS (Bash, `.sh`)
version. The Bash versions are tested on CentOS Stream 9 (GNU grep/sed/coreutils).

### Download the feeds

Downloads both feeds, validates each as JSON, and keeps the previous copy as
`<file>.bak`. A temp file is used so a failed download never corrupts the existing
data; one feed failing does not stop the others.

```bash
# Windows
./download_json_files.ps1
# Linux / macOS
./download_json_files.sh
```

Override the URL list with `-Urls` (PowerShell) or positional arguments (Bash).

### Extract print image filenames

Extracts every `.jpg` from the `imagePrintLine` fields in the print feed →
`imagePrintLines.txt` (unique, sorted, one per line).

```bash
# Windows
./extract-imageprintlines.ps1
# Linux / macOS
./extract-imageprintlines.sh
```

### Extract product image filenames

Extracts every filename from the `imageData` slots in the product feed →
`imageData_filenames.txt` (unique, sorted, one per line).

```bash
# Windows
./extract-imagedata.ps1
# Linux / macOS
./extract-imagedata.sh
```

All extract scripts **stream** their input (no full-file load into memory) and
accept optional input/output path arguments.

## Typical workflow

```bash
./download_json_files.sh        # fetch both feeds
./extract-imageprintlines.sh    # -> imagePrintLines.txt
./extract-imagedata.sh          # -> imageData_filenames.txt
```

On Linux, make the scripts executable first:

```bash
chmod +x *.sh
```

## Repository contents

| File | Purpose |
|------|---------|
| `download_json_files.ps1` / `.sh` | Download both data feeds |
| `extract-imageprintlines.ps1` / `.sh` | Print-feed `imagePrintLine` image list |
| `extract-imagedata.ps1` / `.sh` | Product-feed `imageData` image list |
| `PRINTDATA_MODEL.md` | Print feed format reference |
| `PRODUCTFEED_MODEL.md` | Product feed format reference |
| `imagePrintLines.txt` | Generated print image list |
| `imageData_filenames.txt` | Generated product image list |
