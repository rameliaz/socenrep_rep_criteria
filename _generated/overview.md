## Tier 1 · Available - Bronze

::: {.criteria-table}
| Criterion | Status | Sources | Check order | Definition |
|:------|:---|--:|--:|:-------------|
| [Documentation](criteria/tier-1/documentation.qmd) | [core]{.badge .status-core} | 83 | 0 | The replication package explains its own contents: a README lists every file, describes the data and states how to run the code to reproduce the results, and a codebook or data dictionary defines each variable with its values and labels. A third party should be able to understand and use the data without contacting the authors. |
| [Data provenance](criteria/tier-1/data-provenance.qmd) | [core]{.badge .status-core} | 48 | 0 | The origin of every dataset used in the analysis is recorded: a citation of the source with its version or vintage, how and when the data were obtained (e.g. the query or API used), and, for data that cannot be shared, how and under what conditions others can obtain the same data. Where possible, identifiers or checksums let a user confirm they hold identical data. |
| [License](criteria/tier-1/license.qmd) | [core]{.badge .status-core} | 30 | 0 | Every part of the package, code and data alike, carries an explicit license or terms of use, so others know whether and how they may use, modify and redistribute it. The authors have the right to share what they deposit. |
| [Code deposit](criteria/tier-1/code-deposit.qmd) | [core]{.badge .status-core} | 103 | 1 | All code needed to go from the data to every reported result, including data cleaning and preparation as well as the analysis, is publicly available with the paper in human-readable form, preferably in a trusted repository with a persistent identifier. |
| [Data deposit](criteria/tier-1/data-deposit.qmd) | [core]{.badge .status-core} | 94 | 1 | The data needed to reproduce the reported results are publicly available with the paper, preferably in a trusted repository with a persistent identifier. This can be the raw data, the analysis data, or both; with analysis data only, results can be reproduced from the analysis data but not from the raw data. |
| [Artifacts longevity/sustainability](criteria/tier-1/artifacts-longevity-sustainability.qmd) | [recommended]{.badge .status-recommended} | 9 | — | The package is meant to stay usable after publication: the authors commit to preserving data and code for a stated period and keep them runnable as software and dependencies change, for example by maintaining the code or rebuilding the environment. |
:::

## Tier 2 · Executable - Silver

::: {.criteria-table}
| Criterion | Status | Sources | Check order | Definition |
|:------|:---|--:|--:|:-------------|
| [Dependency resolution](criteria/tier-2/dependency-resolution.qmd) | [core]{.badge .status-core} | 59 | 2 | Every add-on package or library the code needs is declared with its exact version, ideally in a machine-readable file (e.g. renv.lock in R) or an installation script (e.g. a setup.do in Stata), so that a user can install them on a new machine and the code finds them. |
| [Path resolution](criteria/tier-2/path-resolution.qmd) | [core]{.badge .status-core} | 30 | 2 | The code finds its input and output files on any machine without edits: paths are relative to the package's root folder, there are no hard-coded absolute paths or machine-specific working directories, and files sit in the folders the code expects. |
| [Coding error handling](criteria/tier-2/coding-error-handling.qmd) | [core]{.badge .status-core} | 28 | 2 | The code runs to completion without execution errors (bugs). The criterion also covers how errors found during a check are handled: they are recorded, the reproducer makes only minor and unambiguous fixes within a stated limit, each fix is documented, and anything larger goes back to the authors. |
| [Computing environment](criteria/tier-2/computing-environment.qmd) | [core]{.badge .status-core} | 69 | 3 | The system the code was run on is documented: operating system, version of the statistical software or programming language, and, where relevant, hardware and expected runtime. Ideally the environment is captured so it can be rebuilt (e.g. a container, virtual machine or cloud capsule) and the code runs the same way on another machine. |
| [Code runs without manual intervention](criteria/tier-2/code-runs-without-manual-intervention.qmd) | [recommended]{.badge .status-recommended} | 4 | 0 | The full analysis runs from a single entry point (e.g. a master script or Makefile) in the correct order and non-interactively, with no manual steps, GUI clicks or copying of results between scripts. |
| [Code annotation](criteria/tier-2/code-annotation.qmd) | [recommended]{.badge .status-recommended} | 6 | 2 | The code is commented and structured so that a reader can follow what each part does: script headers state purpose, inputs and outputs, and comments show which section produces which table or figure. |
| [Dynamic code inspection](criteria/tier-2/dynamic-code-inspection.qmd) | [recommended]{.badge .status-recommended} | 1 | 2 | A reproducer can explore how the code behaves by running it with small modifications, inspecting intermediate results, or applying code-analysis tools. |
| [Workflow/reproduction tree](criteria/tier-2/workflow-reproduction-tree.qmd) | [recommended]{.badge .status-recommended} | 1 | 2 | The package documents which code and data files produce each table and figure in the paper, for example as a diagram or table that traces every display item back to its scripts and inputs. |
| [Version control](criteria/tier-2/version-control.qmd) | [recommended]{.badge .status-recommended} | 12 | — | Code, and where feasible data, is kept under a version control system such as Git, so that its history is tracked and the exact version used for the paper can be identified (e.g. by a commit hash or tagged release). |
| [Commands logs traceability](criteria/tier-2/commands-logs-traceability.qmd) | [recommended]{.badge .status-recommended} | 1 | — | A log of the commands used to set up the environment and run the analysis is kept, so the setup can be recreated step by step. |
| [Test code coverage](criteria/tier-2/test-code-coverage.qmd) | [recommended]{.badge .status-recommended} | 1 | — | The code includes tests, and the share of the code they cover is checked and reported. |
:::

## Tier 3 · Reproducible - Gold

::: {.criteria-table}
| Criterion | Status | Sources | Check order | Definition |
|:------|:---|--:|--:|:-------------|
| [Codes consistent with claims](criteria/tier-3/codes-consistent-with-claims.qmd) | [core]{.badge .status-core} | 17 | 3 | The code does what the paper says it does: data preparation, samples, model specifications and estimators match the description in the paper, and results are computed by the code rather than copied in. This can be checked by reading the code against the paper, without running it (i.e., static code analysis). |
| [Numerical output match](criteria/tier-3/numerical-output-match.qmd) | [core]{.badge .status-core} | 49 | 4 | Re-running the code on the deposited data reproduces the numerical results reported in the paper and appendix: estimates, standard errors, test statistics, sample sizes and numbers in the text. Sources differ on the tolerance, from exact agreement to small stated deviations. |
| [Table and figure match](criteria/tier-3/table-and-figure-match.qmd) | [core]{.badge .status-core} | 24 | 5 | The code regenerates every table and figure in the paper and appendix, and the regenerated items match the published ones in structure and appearance; for figures, this means the levels, shapes and positions of curves and data points. |
| [Third-party certification](criteria/tier-3/third-party-certification.qmd) | [recommended]{.badge .status-recommended} | 1 | 1 | An independent party certifies that it reproduced the results, or specific tables and figures, from the package, for example in a signed letter or a certificate from a certification agency. This matters most only when the data cannot be shared and reproducers cannot access them. |
:::
