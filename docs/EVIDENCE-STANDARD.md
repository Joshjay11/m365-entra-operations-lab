# Evidence standard

The repository distinguishes four kinds of evidence.

## Production experience

Claims from prior employment describe real work but must not expose employer or customer data beyond information already approved for the resume or public profile.

## Lab execution

Commands, scripts, screenshots, and outputs produced in Jason's own Microsoft 365 or Entra lab are labeled as lab evidence. Lab execution proves that the workflow was performed in the stated environment. It does not prove production scale.

## Synthetic demonstration

Files labeled synthetic are invented examples used to show output shape, logic, or documentation without exposing tenant data. Synthetic output must never be described as a real assessment result.

## Design-only work

An unexecuted plan, script, or configuration is labeled design-only until it is run and validated. Design-only work may demonstrate reasoning, but not successful execution.

## Completion checklist

A project can be marked complete when all applicable checks pass:

- the scenario and purpose are clear
- required permissions are documented
- default behavior is read-only or safely staged
- tenant data is redacted or replaced with synthetic data
- scripts have been executed in the stated lab environment
- expected and actual results are compared
- limitations and failures are recorded
- cleanup and disconnect steps are documented
- the README contains enough information for a reviewer to understand the project in two minutes

