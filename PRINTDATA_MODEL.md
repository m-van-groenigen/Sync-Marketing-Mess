# PRINTDATA_MODEL — `printdata_cse1_fi_v3.json`

Format description of the PF Concept print data feed downloaded from
`https://www.pfconcept.com/portal/datafeed/printdata_cse1_fi_v3.json`.

The feed maps **products** to the **print images** and **SVG print templates** that
are available for decorating them. The filename encodes the variant: `cse1` =
catalogue/segment, `fi` = language (Finnish), `v3` = feed schema version.

## 1. Top-level shape

A single JSON object, emitted as one line (minified). Hierarchy:

```
PFCPrintFeed
└─ printfeed[]                  (array, 1 element in this feed)
   ├─ creationDateTime          feed generation timestamp
   ├─ language                  e.g. "FI"
   ├─ department                e.g. "CNL2"
   ├─ version                   e.g. "v3"
   └─ models[]                  (array, 1 element)
      ├─ numberOfModels         declared model count (matches model.length)
      └─ model[]                one entry per product model
         ├─ modelCode
         ├─ description
         └─ items[]             (array, 1 element)
            ├─ numberOfItems    declared item count (matches item.length)
            └─ item[]           one entry per sellable variant (e.g. colour)
               ├─ itemCode
               └─ printfeedrefs[]   (array, 1 element)
                  ├─ count          declared ref count (matches printfeedref.length)
                  └─ printfeedref[] one entry per available print image
                     ├─ ref
                     ├─ imagePrintLine
                     └─ svgFile
```

Note the recurring **wrapper-with-count** pattern: `models`, `items`, and
`printfeedrefs` are each single-element arrays whose one object carries a
`numberOf…`/`count` field plus the real payload array. In this feed those counts
always equal the actual array lengths.

## 2. Field reference

### `printfeed[]` (feed envelope)

| Field | Type | Notes |
|-------|------|-------|
| `creationDateTime` | string | ISO-8601 local time, e.g. `2026-06-25T05:29:49.006`. No timezone offset. |
| `language` | string | UI/content language, e.g. `FI`. |
| `department` | string | Source department/segment code, e.g. `CNL2`. |
| `version` | string | Feed schema version, e.g. `v3`. |
| `models` | array[1] | Wrapper around the model list. |

### `models[0]`

| Field | Type | Notes |
|-------|------|-------|
| `numberOfModels` | int | Declared model count (1725 in this feed; equals `model.length`). |
| `model` | array | One object per product model. |

### `model[]`

| Field | Type | Notes |
|-------|------|-------|
| `modelCode` | string | Product/model identifier. 5–6 digits (e.g. `100137`, `2PA068`). Not strictly numeric. |
| `description` | string | Human-readable name in the feed language. Always present. |
| `items` | array[1] | Wrapper around the variant list. |

### `items[0]`

| Field | Type | Notes |
|-------|------|-------|
| `numberOfItems` | int | Declared variant count (equals `item.length`). |
| `item` | array | One object per sellable variant. |

### `item[]`

| Field | Type | Notes |
|-------|------|-------|
| `itemCode` | string | Variant/article code, always 8 chars. Usually `modelCode` + 2-digit suffix (e.g. `10013700`), but some models list cross-referenced articles whose code does **not** start with `modelCode`. |
| `printfeedrefs` | array[1] | Wrapper around the print-reference list. |

### `printfeedrefs[0]`

| Field | Type | Notes |
|-------|------|-------|
| `count` | int | Declared print-reference count (equals `printfeedref.length`). May be `0`. |
| `printfeedref` | array | One object per available print image. A few items have an empty array (no prints). |

### `printfeedref[]`

| Field | Type | Notes |
|-------|------|-------|
| `ref` | int | Sequential reference index for the print line. Range `1`–`8505` in this feed. **Not** a globally unique image key — values repeat across items (often as an overlapping running counter between neighbouring items). |
| `imagePrintLine` | string | Print image filename (`.jpg`). May be an empty string when no preview exists. |
| `svgFile` | string | Relative path to the SVG print template, normally `<modelCode>/svg/<imagePrintLine-basename>.svg`. May be an empty string. |

## 3. Filename conventions

### `imagePrintLine`

Always a `.jpg` filename built from underscore-separated segments:

```
<itemCode>_<method>_<a>_<b>[_<locale>].jpg
        e.g.  10013700_2_1226_74.jpg
              21000100_3_5178_441_uk.jpg
```

| Segment | Meaning (observed) |
|---------|--------------------|
| `itemCode` | The 8-char variant code. |
| `method` | Numeric print-method/view code. Observed values: 1–49 (not contiguous). |
| `a`, `b` | Two numeric segments, likely print-position/area dimensions or area IDs. |
| `locale` | Optional trailing locale suffix (e.g. `uk`) on a minority of files. |

Most filenames have 4 segments; some have a 5th locale segment. When
`imagePrintLine` is empty the file simply has no preview image.

### `svgFile`

Relative path, forward-slash separated (JSON-escaped as `\/` in the raw feed):

```
<modelCode>/svg/<imagePrintLine-without-extension>.svg
        e.g.  100137/svg/10013700_2_1226_74.svg
```

The path prefix is normally the model's `modelCode`; for a small number of refs
`svgFile` is empty.

## 4. Cardinality / integrity (this feed snapshot)

| Metric | Value |
|--------|-------|
| `printfeed` entries | 1 |
| `numberOfModels` / actual models | 1725 / 1725 |
| Total items (variants) | 6106 |
| Total print refs | 24411 |
| `ref` value range | 1–8505 (8505 distinct) |
| Count-field mismatches (`numberOfItems`, `count`) | 0 |
| Models with empty `description` | 0 |
| Items with 0 print refs | 5 |
| Empty `imagePrintLine` values | 165 |
| Empty `svgFile` values | present (small minority) |
| Items whose `itemCode` ≠ `modelCode` prefix | 103 |
| Image extensions used | `.jpg` only |

## 5. Consumer notes / gotchas

- **Single-element wrappers**: always read `models[0]`, `items[0]`,
  `printfeedrefs[0]` — don't assume more than one wrapper element, but do iterate
  the inner `model` / `item` / `printfeedref` arrays.
- **Trust the arrays, not just the counts**: the `numberOf…`/`count` fields match
  array lengths here, but defensive consumers should iterate the arrays directly.
- **Empty strings are valid**: `imagePrintLine` and `svgFile` can be `""`; handle
  missing previews/templates gracefully. Some items have zero `printfeedref`s.
- **`ref` is not a primary key**: do not use `ref` as a stable image identifier;
  use `imagePrintLine` (or the SVG path) for identity.
- **`itemCode` may not start with `modelCode`**: a model can reference related
  articles, so don't assume the prefix relationship when joining.
- **Escaping**: paths are JSON-escaped (`\/`); decode before use.
- **Timestamp has no timezone**: `creationDateTime` is local server time without
  an offset.
