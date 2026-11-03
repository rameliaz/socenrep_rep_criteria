# build_criteria.R
#
# Generates the data-driven parts of the rubric website from the newest
# rubric workbook in source/ (rubric_draft_DD.MM.YYYY.xlsx, newest by the
# date in the file name) and the corpus list source/10_final_set.xlsx (a copy
# of litsearch/output/search_output/10_final_set.xlsx). Runs automatically as
# Quarto's pre-render step, so `quarto render` in this folder is all that is
# needed after a new dated workbook is put in source/.
#
# source/ is not in git. Without it (e.g. in a fresh clone) the script keeps
# the generated files already in the repo, so the site still renders.
#
# Writes (all overwritten on every run, do not hand-edit):
#   criteria/tier-<n>/*.qmd   one page per criterion
#   _generated/*.md|dot       partials included by the hand-written pages
#   _variables.yml            workbook name, date and counts for {{< var >}}
#
# Hand-written pages (index.qmd, graph.qmd, sources.qmd, about.qmd) are
# never touched, so their text can be edited freely.

# `quarto preview` re-renders single pages as they are opened and would run this
# script each time. Only full renders (or running it directly) rebuild.
if (nzchar(Sys.getenv("QUARTO_PROJECT_DIR")) && Sys.getenv("QUARTO_PROJECT_RENDER_ALL") != "1") quit(save = "no")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
  library(readxl)
  library(glue)
})

here::i_am("build_criteria.R")

# ---- Inputs ----------------------------------------------------------------

workbooks <- tibble(path = list.files(here::here("source"), "^rubric_draft_\\d{2}\\.\\d{2}\\.\\d{4}\\.xlsx$",
                                      full.names = TRUE)) |>
  mutate(date = as.Date(str_extract(basename(path), "\\d{2}\\.\\d{2}\\.\\d{4}"), "%d.%m.%Y")) |>
  arrange(desc(date))
corpus_path <- here::here("source", "10_final_set.xlsx")
if (!nrow(workbooks) || !file.exists(corpus_path)) {
  if (!file.exists(here::here("_variables.yml"))) stop("source/ needs rubric_draft_DD.MM.YYYY.xlsx and 10_final_set.xlsx")
  message("No workbook or corpus file in source/: keeping the existing generated pages")
  quit(save = "no")
}
wb <- workbooks$path[1]
message("Building from ", basename(wb))

rubric   <- read_excel(wb, sheet = "Rubric draft") |> mutate(row = row_number() + 1L)
evidence <- read_excel(wb, sheet = "Text evidence")
addinfo  <- read_excel(wb, sheet = "Addinfo", col_names = c("key", "value"))
corpus   <- read_excel(corpus_path, sheet = "Literature") |> rename(paper_id = `No.`)

# Badge awarded per tier, shown with the tier name throughout the site
medal  <- c(`1` = "Bronze", `2` = "Silver", `3` = "Gold")
rubric <- mutate(rubric, tier_label = as.character(glue("Tier {tier} · {tier_name} - {medal[as.character(tier)]}")))

# The workbook has pct_injunctive and pct_tacit but not pct_descriptive. Recount the
# framing from the Text evidence sheet as rubric_tiers.R does (one row per source x
# criterion, duplicates merged) and warn if the recount no longer matches the workbook.
if (!"pct_descriptive" %in% names(rubric)) {
  duplicate_sources <- c(`138` = 98)  # = DUPLICATE_SOURCES in litsearch/codes/rubric_tiers.R
  pct <- function(x, value) round(100 * mean(x == value, na.rm = TRUE), 1)
  framing <- evidence |>
    mutate(source_id = coalesce(unname(duplicate_sources[as.character(paper_id)]), paper_id)) |>
    arrange(paper_id != source_id) |>
    distinct(source_id, criterion, .keep_all = TRUE) |>
    summarise(n = n(), inj = pct(`normative framing`, "injunctive"),
              pct_descriptive = pct(`normative framing`, "descriptive"),
              tac = pct(`normative framing`, "tacit"), .by = criterion)
  rubric <- left_join(rubric, framing, by = "criterion")
  off <- filter(rubric, n != sources | inj != pct_injunctive | tac != pct_tacit)$criterion
  if (length(off)) warning("Descriptive share may be inconsistent; recount differs from the workbook for: ", toString(off))
  rubric <- select(rubric, -c(n, inj, tac))
}

# Cell comments on the anchor columns hold the source IDs behind each anchor.
# openpyxl stores comments under xl/comments/, which neither tidyxl (segfaults
# on these workbooks) nor openxlsx2 reads, so the comments part linked from the
# "Rubric draft" sheet is parsed directly.
anchor_cols <- c("criterion_met", "criterion_partially_met", "criterion_not_met")
sheet_rels <- xml2::read_xml(unz(wb, glue("xl/worksheets/_rels/sheet{match('Rubric draft', excel_sheets(wb))}.xml.rels")))
comments_part <- xml2::xml_find_first(sheet_rels, "//d1:Relationship[contains(@Type, '/comments')]") |>
  xml2::xml_attr("Target") |> xml2::url_absolute("/xl/worksheets/") |> str_remove("^/")
comment_nodes <- if (is.na(comments_part)) list() else
  xml2::xml_find_all(xml2::read_xml(unz(wb, comments_part)), "//d1:comment")
comments <- tibble(ref = xml2::xml_attr(comment_nodes, "ref"), comment = xml2::xml_text(comment_nodes)) |>
  transmute(row = as.integer(str_extract(ref, "\\d+")),
            anchor = names(rubric)[match(str_extract(ref, "^[A-Z]+"), LETTERS)], comment) |>
  filter(anchor %in% anchor_cols)

# ---- Helpers ---------------------------------------------------------------

slug <- function(x) str_replace_all(str_to_lower(x), "[^a-z0-9]+", "-") |> str_remove_all("^-|-$")
sentence <- function(x) str_replace(x, "^.", str_to_upper)
path_of <- setNames(glue("criteria/tier-{rubric$tier}/{slug(rubric$criterion)}"), rubric$criterion)

# Escape pandoc-markdown syntax in spreadsheet text, keep line breaks as paragraphs
md <- function(x) {
  x |>
    str_replace_all("\r\n?", "\n") |>
    str_replace_all("([\\\\`*_\\[\\]<>$#|~^@])", "\\\\\\1") |>
    str_replace_all("(?m)^(\\s*)([-+])(\\s)", "\\1\\\\\\2\\3") |>
    str_replace_all("(?m)^(\\s*)(\\d+)([.)])(\\s)", "\\1\\2\\\\\\3\\4") |>
    str_trim() |>
    str_replace_all("\\s*\n\\s*", "\n\n")
}
md_inline <- function(x) str_replace_all(md(x), "\n\n", " ")

# Link source IDs (#42) in already-escaped text to the sources page
titles <- setNames(str_replace_all(corpus$Title, '"', "'"), corpus$paper_id)
link_ids <- function(x, root) {
  str_replace_all(x, "\\\\#(\\d+)", function(m) {
    id <- str_remove(m, "\\\\#")
    glue('[#{id}]({root}sources.qmd#p{id} "{titles[id]}")')
  })
}

# root = relative path from the calling page to the site root
crit_link <- function(label, root, text = label) glue("[{text}]({root}{path_of[label]}.qmd)")
na_dash <- function(x) if_else(is.na(x), "—", as.character(x))
n_word <- function(n, word) paste(n, if_else(n == 1, word, paste0(word, "s")))

# Write only when the content changed: `quarto preview` watches these files, so
# rewriting identical files would trigger an endless pre-render/re-render loop
write_if_changed <- function(text, path) {
  lines <- strsplit(paste(text, collapse = "\n"), "\n", fixed = TRUE)[[1]]
  if (!file.exists(path) || !identical(readLines(path, encoding = "UTF-8", warn = FALSE), lines)) {
    writeLines(lines, path)
  }
}

# ---- Prerequisite edges ----------------------------------------------------

edges <- rubric |>
  select(to = criterion, core = core_prerequisites, recommended = recommended_prerequisites) |>
  pivot_longer(c(core, recommended), names_to = "prereq_status", values_to = "list") |>
  filter(!is.na(list)) |>
  separate_longer_delim(list, "; ") |>
  extract(list, c("from", "n"), "^(.*) \\((\\d+)\\)$", convert = TRUE)

unknown <- setdiff(edges$from, rubric$criterion)
if (length(unknown)) stop("Prerequisites that are not rubric criteria: ", toString(unknown))

# ---- Criterion pages -------------------------------------------------------

walk(c(unique(dirname(path_of)), "_generated"), \(d) dir.create(here::here(d), recursive = TRUE, showWarnings = FALSE))

anchor_box   <- c(criterion_met = "tip", criterion_partially_met = "warning", criterion_not_met = "important")
anchor_title <- c(criterion_met = "Met", criterion_partially_met = "Partially met", criterion_not_met = "Not met")

# Popover on the core-reason badge: both rules from the Addinfo explanation of
# core_reason, with the criterion's own rule in bold
reason_rules <- addinfo$value[addinfo$key %in% "core_reason"] |>
  str_extract_all("\\b(endorsement|structural): [^.]+\\.") |> unlist()
if (!length(reason_rules)) warning("Addinfo 'core_reason' no longer defines endorsement/structural; popovers show only the link")
reason_popover <- function(reason) {
  rules <- if_else(str_starts(reason_rules, reason), paste0("<b>", reason_rules, "</b>"), reason_rules)
  paste0(paste0("<p>", rules, "</p>", collapse = ""), "<a href='../../about.html#definitions-from-the-workbook'>All column definitions</a>")
}

prereq_lines <- function(df, label_col, empty) {
  if (!nrow(df)) return(empty)
  paste(glue("- {crit_link(df[[label_col]], '../../', sentence(df[[label_col]]))} ({n_word(df$n, 'source')})"),
        collapse = "\n")
}

# Hand-written notes: _notes/<page name>.md goes at the top of that criterion's page
site_note <- function(criterion) {
  f <- here::here("_notes", paste0(slug(criterion), ".md"))
  if (file.exists(f)) c(readLines(f, encoding = "UTF-8", warn = FALSE), "") else character()
}

render_criterion <- function(r) {
  com <- filter(comments, row == r$row)
  # Anchors that share one comment get a single "Based on" line below them
  shared <- nrow(com) == 3 && n_distinct(com$comment) == 1
  note <- function(text) glue("[{link_ids(md(text), '../../')}]{{.source-note}}")

  anchors <- map_chr(anchor_cols, function(a) {
    own <- com$comment[com$anchor == a]
    glue("::: {{.callout-{anchor_box[[a]]} appearance=\"simple\" title=\"{anchor_title[[a]]}\"}}\n",
         "{md(r[[a]])}",
         "{if (length(own) && !shared) paste0('\n\n', note(own)) else ''}\n:::")
  })

  prereq_core <- edges |> filter(to == r$criterion, prereq_status == "core") |> arrange(desc(n))
  prereq_rec  <- edges |> filter(to == r$criterion, prereq_status == "recommended") |> arrange(desc(n))
  needed_by   <- edges |> filter(from == r$criterion) |> arrange(desc(n))

  ev <- evidence |>
    filter(criterion == r$criterion) |>
    arrange(paper_id) |>
    mutate(item = glue(
      "**[#{paper_id}](../../sources.qmd#p{paper_id})** {md(paper_title)} · *{`normative framing`}*\n\n",
      "> {str_replace_all(md(`text evidence`), '\n\n', '\n>\n> ')}",
      "{if_else(is.na(notes), '', paste0('\n\n*Note:* ', md(notes)))}"
    ))

  # Quarto shows the subtitle (badges) and description (definition) under the title
  reason_badge <- if (is.na(r$core_reason)) "" else glue(
    ' [{r$core_reason}]{{.badge .reason tabindex="0" role="button" data-bs-toggle="popover" ',
    'data-bs-trigger="focus" data-bs-placement="bottom" data-bs-html="true" data-bs-title="Why is this criterion core?" ',
    'data-bs-content="{reason_popover(r$core_reason)}"}}')
  badges <- glue("[{r$tier_label}]{{.badge .tier-{r$tier}}} [{r$status}]{{.badge .status-{r$status}}}{reason_badge}")
  front <- list(title = sentence(r$criterion), subtitle = as.character(badges),
                description = r$definition, order = r$row)

  page <- c(
    "---", str_trim(yaml::as.yaml(front)), "---", "",
    glue("<!-- Generated by build_criteria.R from {basename(wb)}. Do not edit. -->"), "",
    site_note(r$criterion),
    "## Rating", "",
    anchors, "",
    if (shared) c(note(com$comment[1]), "") else "",
    glue("::: {{.callout-note appearance=\"simple\" title=\"Not applicable\"}}\n",
         "{if (is.na(r$not_applicable)) '—' else md(r$not_applicable)}\n:::"), "",
    "## Prerequisites", "",
    glue("Check order: **{na_dash(r$check_order)}**",
         if (is.na(r$check_order)) " (no prerequisite links coded)" else ""), "",
    ":::: {.columns}", "::: {.column width=\"50%\"}",
    "**Builds on**", "",
    prereq_lines(prereq_core, "from", "*No core prerequisites.*"), "",
    if (nrow(prereq_rec)) c("*Recommended:*", "", prereq_lines(prereq_rec, "from", ""), "") else "",
    ":::", "::: {.column width=\"50%\"}",
    "**Prerequisite for**", "",
    prereq_lines(needed_by, "to", "*No criterion builds on this one.*"),
    ":::", "::::", "",
    paste0("## In the corpus [[]{.bi .bi-info-circle}](../../about.qmd#evidence-on-each-criterion-page ",
           "\"What these numbers mean\"){.heading-info aria-label=\"What these numbers mean\"}"), "",
    "| Sources | Injunctive | Descriptive | Tacit | Automatable | Manual check | Automation unclear | LLM sources |",
    "|--:|--:|--:|--:|--:|--:|--:|--:|",
    glue("| {r$sources} | {r$pct_injunctive}% | {r$pct_descriptive}% | {r$pct_tacit}% | {r$pct_automatable_yes}% | ",
         "{r$pct_automatable_no}% | {r$pct_automatable_unclear}% | {r$llm_sources} |"), "",
    glue("## Text evidence ({n_word(nrow(ev), 'quote')})"), "",
    "::: {.callout-note collapse=\"true\" appearance=\"minimal\" title=\"Show quotes\"}",
    paste(ev$item, collapse = "\n\n---\n\n"),
    ":::"
  )
  write_if_changed(page, here::here(paste0(path_of[[r$criterion]], ".qmd")))
}

rubric |> split(seq_len(nrow(rubric))) |> walk(\(r) render_criterion(as.list(r)))

# Remove pages of criteria that were renamed, dropped or moved to another tier
stale <- setdiff(list.files(here::here("criteria"), "\\.qmd$", recursive = TRUE),
                 str_remove(paste0(path_of, ".qmd"), "^criteria/"))
invisible(file.remove(here::here("criteria", stale)))

# ---- Prerequisite graph ----------------------------------------------------

# Bronze / Silver / Gold, as $tier-1..3 in theme.scss; borders are darker shades
tier_fill   <- c(`1` = "#cd7f32", `2` = "#c0c0c0", `3` = "#ffd700")
tier_border <- c(`1` = "#8c5523", `2` = "#7d7f83", `3` = "#b39500")
min_strong  <- 3L  # same threshold as the 'structural' core_reason rule

# Writes <name>.dot plus <name>_unlinked.md, which lists the criteria left out
# of the drawing because they have no link at this threshold
write_graph <- function(min_n, name) {
  e <- filter(edges, n >= min_n)
  linked <- rubric$criterion %in% c(e$from, e$to)
  unlinked <- rubric$criterion[!linked]
  write_if_changed(
    if (length(unlinked)) paste("Not linked at this threshold:",
                                paste(crit_link(unlinked, "", sentence(unlinked)), collapse = ", ")) else "",
    here::here("_generated", paste0(name, "_unlinked.md")))

  nodes <- rubric[linked, ] |>
    mutate(t = as.character(tier),
           tip = str_squish(str_replace_all(definition, '"', "'")),
           fill = if_else(status == "core", tier_fill[t], "white"),
           style = if_else(status == "core", "rounded,filled", "rounded,dashed"),
           line = glue('  "{criterion}" [label="{sentence(criterion)}", URL="{path_of[criterion]}.html", target="_top", ',
                       'tooltip="{tip}", fillcolor="{fill}", color="{tier_border[t]}", style="{style}", penwidth=1.5]'))
  # No tier boxes: they force long detours. Columns follow prerequisite depth, colors show the tier.
  edge_lines <- glue('  "{e$from}" -> "{e$to}" [penwidth={round(0.6 + sqrt(e$n) * 0.6, 2)}, label="{e$n}", ',
                     'style="{if_else(e$prereq_status == "core", "solid", "dashed")}"]')
  write_if_changed(c(
    "digraph prerequisites {",
    '  rankdir=LR; nodesep=0.25; ranksep=0.8; bgcolor="transparent";',
    '  node [shape=box, fontname="Helvetica", fontsize=13, margin="0.18,0.08"];',
    '  edge [color="#888888", fontname="Helvetica", fontsize=11, fontcolor="#555555", arrowsize=0.7];',
    nodes$line, edge_lines, "}"),
    here::here("_generated", paste0(name, ".dot")))
}

write_graph(1, "graph_all")
write_graph(min_strong, "graph_strong")

# ---- Overview, sources, column guide ---------------------------------------

overview <- rubric |>
  group_split(tier) |>
  map_chr(function(t) {
    rows <- glue("| {crit_link(t$criterion, '', sentence(t$criterion))} | [{t$status}]{{.badge .status-{t$status}}} | ",
                 "{t$sources} | {na_dash(t$check_order)} | {md_inline(t$definition)} |")
    paste(c(glue("## {t$tier_label[1]}"), "", "::: {.criteria-table}",
            "| Criterion | Status | Sources | Check order | Definition |",
            "|:------|:---|--:|--:|:-------------|", rows, ":::", ""), collapse = "\n")
  })
write_if_changed(overview, here::here("_generated", "overview.md"))

cited_in <- evidence |>
  distinct(paper_id, criterion) |>
  left_join(select(rubric, criterion, row), by = "criterion") |>
  arrange(row) |>
  summarise(criteria = paste(crit_link(criterion, ""), collapse = ", "), .by = paper_id)

sources <- corpus |>
  left_join(cited_in, by = "paper_id") |>
  mutate(title = if_else(is.na(DOI), md_inline(Title), glue("[{md_inline(Title)}](https://doi.org/{DOI})")),
         line = glue("| []{{#p{paper_id}}}{paper_id} | {md_inline(Authors)} ({Year}). {title} | ",
                     "{replace_na(criteria, '—')} |"))
write_if_changed(c("| # | Paper | Text evidence for |", "|--:|:--------|:-----|", sources$line),
           here::here("_generated", "sources.md"))

# Addinfo: column table, N/A conditions, scope rule (blank rows separate the blocks)
about <- addinfo |>
  mutate(block = cumsum(is.na(key))) |>
  filter(!is.na(key)) |>
  group_split(block) |>
  map_chr(function(b) {
    if (nrow(b) == 1) return(glue("**{md(b$key)}.** {md_inline(b$value)}\n"))
    paste(c(glue("| {md(b$key[1])} | {md(b$value[1])} |"), "|:--|:-------|",
            glue("| {md(b$key[-1])} | {md_inline(b$value[-1])} |"), ""), collapse = "\n")
  })
write_if_changed(about, here::here("_generated", "addinfo.md"))

tiers <- summarise(rubric, tier_label = first(tier_label), n = n(), n_core = sum(status == "core"), .by = tier) |>
  arrange(tier)
write_if_changed(yaml::as.yaml(c(list(rubric_file = basename(wb), rubric_date = format(workbooks$date[1], "%d.%m.%Y"),
                                      n_criteria = nrow(rubric), n_core = sum(rubric$status == "core"),
                                      n_quotes = nrow(evidence), n_papers = nrow(corpus), n_edges = nrow(edges),
                                      n_strong = sum(edges$n >= min_strong), min_strong = min_strong),
                                 setNames(as.list(tiers$tier_label), paste0("tier_", tiers$tier)),
                                 setNames(as.list(tiers$n), paste0("n_tier_", tiers$tier)),
                                 setNames(as.list(tiers$n_core), paste0("n_core_tier_", tiers$tier)))),
                 here::here("_variables.yml"))

message(nrow(rubric), " criteria, ", nrow(edges), " prerequisite links, ", nrow(evidence), " quotes",
        if (length(stale)) paste0("; removed stale pages: ", toString(stale)) else "")
