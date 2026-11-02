# SocEnRep Reproducibility Rubric

Quarto website for browsing the rubric criteria. All criterion content comes from
two files in `source/`:

- the newest `rubric_draft_DD.MM.YYYY.xlsx` (newest by the date in the file name)
- `10_final_set.xlsx`, a copy of `litsearch/output/search_output/10_final_set.xlsx`,
  for the source list

## What is automatically generated, what is hand-written

| File | Edit? |
|---|---|
| `index.qmd`, `graph.qmd`, `sources.qmd`, `about.qmd`, `pipeline.qmd` | Yes: text of each page |
| `_quarto.yml`, `theme.scss` | Yes: navigation, sidebar, theme, colors |
| `criteria/tier-*/*.qmd` | No: one page per criterion, regenerated on every render |
| `_generated/*`, `_variables.yml` | No: tables, graphs and counts, regenerated on every render |
| `docs/` | No: the rendered site |

Cell comments on the **met**/**partially met**/**not met** columns appear under each anchor, and `#ID`s in them link to the source list. The core-reason badge on each criterion
page (**endorsement**/**structural**) opens the two rules from the workbook's `Addinfo`
sheet when clicked.

## Comments

Hypothesis annotations are switched on (`comments: hypothesis` in `_quarto.yml`).
