# SAP ABAP Custom ALV — Open Sales Orders Report

> **Capstone Project** | Sanskrita Baishya | Roll No: 2305807 | Batch: SAP ABAP
> Specialization: SAP ABAP Development

---

## Problem Statement

Zenith Retail Pvt. Ltd. is a mid-sized retail company operating across 12 states in India, processing hundreds of sales orders daily through SAP. The sales operations team had no single, consolidated view of open (undelivered or partially delivered) orders across customers. Existing standard transactions such as **VA05** and **VL10A** required manual data compilation across multiple screens, consuming 2–3 hours of effort daily.

The absence of a unified report led to delayed order fulfillment, missed delivery commitments, and no visibility into which orders were at risk. This project develops a **Custom ALV (ABAP List Viewer) Report** that retrieves open order data from `VBAK`, `VBAP`, `KNA1`, and `VBUP`, applies business-driven color-coded order health indicators, and presents the output in an interactive ALV Grid with subtotals and export capabilities.

---

## Solution & Features

### Selection Screen

| Parameter | Description |
|---|---|
| `SO_ERDAT` | Order creation date range (Obligatory) |
| `SO_KUNNR` | Customer number range |
| `SO_AUART` | Sales order document type |
| `P_LFSTA` | Delivery status filter (default: A = Not yet delivered) |

### Data Retrieval

Optimized `SELECT ... INNER JOIN` across four SAP standard database tables:

- **VBAK** — Sales Order Header (order number, date, type, currency)
- **VBAP** — Sales Order Item (material, quantity, net value)
- **KNA1** — Customer Master (customer name, city)
- **VBUP** — Sales Order Item Status (delivery status per line item)

Only orders with delivery status **not equal to 'C'** (Completed) are fetched, ensuring the report shows only actionable open orders.

### Color-Coded Order Health

| Color | Condition | ALV Key |
|---|---|---|
| 🔴 Red | Order age exceeds 30 days — immediate action required | `C610` |
| 🟡 Yellow | Order age between 15 and 30 days — approaching risk | `C510` |
| 🟢 Green | Order age under 15 days — within fulfillment window | `C310` |

Order age is calculated at runtime using `SY-DATUM - ERDAT`, providing live visibility into order health every time the report is executed.

### ALV Grid Capabilities

- Dynamic field catalog built via `REUSE_ALV_FIELDCATALOG_MERGE`
- Subtotals and grand totals on **Net Value** (`NETWR`) and **Quantity** (`KWMENG`)
- Zebra-striping and auto-fit column widths for readability
- Row-level color coding linked via `info_fname` layout parameter
- Saveable layout variants per user (`i_save = 'A'`)
- Direct export to **Excel (.xlsx)** and **PDF** via standard ALV toolbar

---

## Tech Stack

| Component | Details |
|---|---|
| SAP Platform | SAP ECC 6.0 / S/4HANA 2021 |
| Language | ABAP Release 7.50+ |
| Development Transaction | SE38 — ABAP Workbench Editor |
| UI Technology | ALV Grid — `CL_GUI_ALV_GRID` |
| Container | `CL_GUI_CUSTOM_CONTAINER` |
| Function Modules | `REUSE_ALV_FIELDCATALOG_MERGE` |
| Database Tables | VBAK, VBAP, KNA1, VBUP |
| Transport Package | ZREPORTS |
| Testing | SE38 → F8 Execute, ABAP Debugger (F12) |

---

## Repository Structure

```
SAP-ABAP-ALV-Project/
├── ZZENITH_OPEN_ORDERS_ALV.abap     ← Full ABAP source code
├── [YourName]_ALV_Report.pdf        ← Full project report (upload separately)
├── Screenshots/                     ← SAP GUI screenshots (upload separately)
│   ├── Fig1_SE38_Editor.png
│   ├── Fig2_Selection_Screen.png
│   ├── Fig3_ALV_Grid_Output.png
│   ├── Fig4_Color_Coding.png
│   ├── Fig5_Subtotals.png
│   └── Fig6_Export_to_Excel.png
└── README.md
```

---

## Step-by-Step Development

The program is structured across 7 clearly separated steps:

1. **SE38 Setup** — Create executable program `ZZENITH_OPEN_ORDERS_ALV` in package `ZREPORTS`
2. **Global Declarations** — Type structure `ty_orders`, internal tables, ALV object references
3. **Selection Screen** — User-facing parameter block with obligatory date range and delivery status filter
4. **Data Fetch** — Optimized `SELECT INNER JOIN` across VBAK, VBAP, KNA1, and VBUP; excludes fully delivered orders
5. **Color Coding** — `LOOP` assigns row color key based on `SY-DATUM - ERDAT` (order age in days)
6. **Field Catalog** — `REUSE_ALV_FIELDCATALOG_MERGE` with manual customization of column headers, subtotals, and hidden fields
7. **ALV Display** — Layout configured with zebra, auto-width, and color field; grid displayed via `CL_GUI_ALV_GRID->SET_TABLE_FOR_FIRST_DISPLAY`

---

## Unique Highlights

- **Four-Table JOIN** — Includes `VBUP` for delivery status filtering at the database level, reducing data volume before processing
- **Live Order Health** — Color logic uses `SY-DATUM` at runtime, so every execution reflects today's actual order age
- **City-Level Visibility** — Customer city (`ORT01`) is included from `KNA1`, enabling regional fulfillment analysis
- **Declarative Subtotals** — `DO_SUM` flags in the field catalog handle aggregation without manual `COMPUTE SUM`
- **Modular Design** — Color coding, field catalog, and ALV display are logically separated for easy maintenance

---

## Future Improvements

- **CDS View Migration** — Replace SELECT logic with ABAP CDS Views for S/4HANA Clean Core compliance
- **Fiori Analytical List Page** — Expose as OData service and build a browser-accessible Fiori ALP for mobile use
- **Automated Overdue Alerts** — Schedule as a background job (SM36) to email the overdue order list to the sales head daily
- **Configurable Age Thresholds** — Store red/yellow/green day thresholds in a custom Z-table so admins can adjust without code changes
- **Drill-Down to VA03** — Add double-click handler to navigate directly to the Sales Order display transaction from any grid row

---

## Screenshots

> *Upload your SAP GUI screenshots to the `Screenshots/` folder.*

| Fig. | Description |
|---|---|
| Fig. 1 | SE38 Editor — program source loaded, syntax check passed (green bar) |
| Fig. 2 | Selection Screen — date range, customer, order type, status filter |
| Fig. 3 | ALV Grid Output — all columns, zebra-striping, auto-fit widths |
| Fig. 4 | Color Coding — red/yellow/green rows by order age |
| Fig. 5 | Subtotals — Net Value and Quantity aggregated per customer group |
| Fig. 6 | Export to Excel — Local File export dialog generating .xlsx |

---

*Submitted as part of the SAP ABAP Capstone Project — April 2026*
