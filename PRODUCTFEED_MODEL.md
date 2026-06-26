# PRODUCTFEED_MODEL — `productfeed_en_v3.json`

Format description of the PF Concept product data feed downloaded from
`https://www.pfconcept.com/portal/datafeed/productfeed_en_v3.json`.

This is the master product catalogue: every model, its sellable items (variants),
and their commercial / logistical / decoration / media metadata. The filename
encodes `en` = language (English) and `v3` = feed schema version. It pairs with the
print feed (`printdata_*`) via `modelCode` / `itemCode`.

> **Size**: ~189 MB, **pretty-printed** (indented) JSON. Unlike the print feed it is
> not minified, but it is far larger — prefer streaming / chunked parsing.

## 1. Top-level shape

```
pfcProductfeed
└─ productfeed
   ├─ creationDateTime        feed generation timestamp (UTC, e.g. 2026-06-24T13:34:02.940284Z)
   ├─ language                e.g. "EN"
   ├─ department              e.g. "CNL1"
   ├─ version                 e.g. "v3"
   └─ models[]                array, one element per product model
      └─ model                object (NOT an array)
         ├─ modelCode
         ├─ description
         ├─ extDesc
         ├─ keywords
         ├─ productComments
         ├─ attributes.attribute[]      product-level attribute list
         ├─ supplierAddress
         └─ items[]                     array, one element per variant
            └─ item                     object
               ├─ itemCode
               ├─ … (measurements, decorationSettings, colors, imageData, …)
               └─ isDiscontinued
```

Note the recurring **single-key wrapper** pattern: each element of `models[]` is an
object `{ "model": { … } }`, and each element of `items[]` is `{ "item": { … } }`.
There are no `numberOf…` count fields (unlike the print feed).

## 2. Envelope fields (`productfeed`)

| Field | Type | Notes |
|-------|------|-------|
| `creationDateTime` | string | ISO-8601 with `Z` (UTC), microsecond precision, e.g. `2026-06-24T13:34:02.940284Z`. |
| `language` | string | Content language, e.g. `EN`. |
| `department` | string | Source department/segment code, e.g. `CNL1`. |
| `version` | string | Feed schema version, e.g. `v3`. |
| `models` | array | One wrapper object per model. |

## 3. Model (`models[].model`)

| Field | Type | Notes |
|-------|------|-------|
| `modelCode` | string | Product/model identifier (e.g. `100137`). Joins to the print feed `modelCode`. |
| `description` | string | Short product name. |
| `extDesc` | string | Long marketing description. |
| `keywords` | string | Comma-separated search keywords. |
| `productComments` | string \| null | Often `null`. |
| `attributes` | object | `{ "attribute": [ … ] }` — see below. |
| `supplierAddress` | string | Comma-joined supplier/importer address block. |
| `items` | array | One wrapper object per variant. |

### `attributes.attribute[]`

| Field | Type | Notes |
|-------|------|-------|
| `productAttributeCode` | string | Attribute key, prefixed `pa_` (e.g. `pa_bsciFactory`, `pa_oekoStandard`, `pa_certifications_environmental`, `pa_certifications_social`, `pa_affordableprice`, `pa_mainLabelType`, `pa_numberOfSheets`). |
| `attributeSetting` | string \| null | Value: `Yes`/`No`, free text (e.g. `OEKO-TEX®`, `BSCI`), or `null`. |

## 4. Item (`items[].item`)

Top-level item fields (all values are strings unless noted):

| Field | Type | Notes |
|-------|------|-------|
| `itemCode` | string | 8-char variant/article code (e.g. `10013700`). Joins to print feed `itemCode`. |
| `size`, `sizeGrid`, `sizeRange` | string | Apparel sizing; often empty. |
| `gender` | string \| null | Often `null`. |
| `measurements` | object | See below. |
| `qtyPerCarton` | string | Numeric as string. |
| `decorationSettings` | object | See below. |
| `grossWeightKg`, `nettWeightKg` | string | Decimal uses **comma** separator (e.g. `8,55`). |
| `exportLcm`, `exportWcm`, `exportHcm` | string | Export carton dimensions (cm). |
| `countryOfOrigin` | string | e.g. `PRC`. |
| `hsCode` | string | Customs HS code (zero-padded). |
| `brand` | string | e.g. `Unbranded`. |
| `categoryData` | object | `groupCode`, `groupDesc`, `catCode`, `catDesc`. |
| `colors` | object | `{ "color": [ … ] }` — see below. |
| `penInkColor` | string | Often empty. |
| `material` | string | Free-text material description. |
| `simpleMaterial` | array[string] \| null | e.g. `["Fleece"]`, or `null`. |
| `battery` | object | See below. |
| `eanCode` | string | EAN barcode; **may contain trailing spaces** — trim before use. |
| `launchDate` | string | Format `MM-DD-YYYY` (e.g. `06-29-2012`). |
| `imageData` | object | Fixed set of image slots — see below. |
| `videoUrl1`, `videoUrl2` | string | Often empty. |
| `markSegment` | string | e.g. `Bullet`. |
| `addOn` | string | Often empty. |
| `catalogues` | object | `{ "catalog": { type, year, page } }`. |
| `themes` | object | `{ "theme": [ … ] }` — array of single-element arrays (see below). |
| `relatedItems` | object | `{ "related": ["112959", …] }` — array of related model/item codes. |
| `greenPoints` | object | `greenPointsTotal`, `co2footprint` (comma decimal). |
| `isDiscontinued` | string | `"true"` / `"false"` (string, not boolean). |

> **No pricing.** This feed contains no price, currency, or cost fields.

### `measurements`

`weightGr`, `grammage`, `lengthCm`, `heightCm`, `widthCm`, `diameterCm`,
`circumferenceCm` (string \| null), `SizeCombined`, and the `giftbox*` equivalents
(`giftboxLengthCm`, `giftboxHeightCm`, `giftboxWidthCm`, `giftboxDiameterCm`,
`giftboxSizeCombined`). Empty strings are common.

### `decorationSettings`

| Sub-object | Fields |
|------------|--------|
| `decoDefault` | `method`, `leadTime`, `leadTimeMaxQty`, `impLocationDefault`, `impWidthDefaultMm`, `impHeightDefaultMm`, `impDiameterDefaultMm`, `maxColoursDefault`, `impSizeDefaultMm`, `imageImprintDefault` (a `.jpg`, matches print-feed `imagePrintLine`), `decorationMandatory`, `decoComments` (string \| null). |
| `packaging` | `decoPackagingIndiv`, `decoPackagingIndivType`, `decoPackaging`. |

### `colors.color[]`

Each color: `colorCode`, `colorDesc`, `baseColor`, `hexColor` (RGB hex, no `#`),
`pmsColorReference` (may be empty). Most items have 1 color; some have several.

### `battery`

`batteryIncluded`, `batteryNr`, `batteryWeight`, and `batterySizes` — an array of
**two** fixed slots, each `{ "types": { "seq": "1|2" }, "batterySize": "", "batteryType": "" }`.
Usually empty for non-electronic products.

### `imageData`

Fixed set of optional image-filename slots (empty string when absent):
`imageMain`, `imageLogoY1`, `imageLogoY2`, `imageLogoY3`, `imagePackage`,
`imageFront`, `imageBack`, `imageExtra1`–`3`, `imageDetail1`–`3`, `imageGroup`,
`imageMood1`–`3`, `imageModel`.

### `themes.theme`

An array of single-element arrays of theme tags, e.g.
`[ ["Sale"], ["3d_logo_tool"], ["Summer-holiday"] ]`. Flatten one level to get the
tag list.

## 5. Cardinality / integrity (this feed snapshot)

| Metric | Value |
|--------|-------|
| `productfeed` envelope | 1 |
| Models (`modelCode`) | 2078 |
| Items (`itemCode`) | 18818 |
| `model` wrappers that are arrays | 0 (always an object) |
| `items` arrays | 2078 (one per model) |
| Avg items per model | ~9 |
| Price / currency fields | none |
| Distinct JSON keys | 128 |
| `batterySizes` entries per item | 2 (fixed) |

> Field presence is high but not 100% uniform — a handful of items omit individual
> optional fields, so iterate defensively rather than assuming every key exists.

## 6. Consumer notes / gotchas

- **Stream it.** At ~189 MB, avoid loading the whole document; parse via a streaming
  reader (e.g. `System.Text.Json.Utf8JsonReader`) or chunked scanning.
- **Single-key wrappers.** Unwrap `models[].model` and `items[].item`; `model` is an
  object, `items` is an array with one `{ "item": … }` per variant.
- **Everything is a string.** Numbers, booleans, weights, quantities and dates are
  all JSON strings. `isDiscontinued` is `"true"`/`"false"` text.
- **Decimal comma.** Numeric decimals use `,` (e.g. `8,55`, `4,9804765326912`).
- **Date format.** `launchDate` is `MM-DD-YYYY`; `creationDateTime` is ISO-8601 UTC.
- **Trim strings.** `eanCode` (and some others) may carry trailing spaces.
- **Nulls vs empty strings.** Both occur (`productComments`, `gender`,
  `circumferenceCm`, `simpleMaterial`, `decoComments`, `attributeSetting` can be
  `null`; many other fields are `""`). Handle both.
- **Nested-array quirks.** `themes.theme` is an array of single-element arrays;
  `relatedItems.related` and `simpleMaterial` are flat string arrays.
- **Cross-feed join.** `modelCode` / `itemCode` link to the print feed; an item's
  `decoDefault.imageImprintDefault` corresponds to a print-feed `imagePrintLine`.
- **No price data.** Pricing must come from another source.
