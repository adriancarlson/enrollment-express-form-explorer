# SQL validation and open questions

## Completed checks

The initial SQL files were checked on September 10, 2026:

- All 10 statements parsed using SQLGlot's Oracle dialect and were SELECT
  statements.
- An independent extraction of column definitions from Data Dictionary 26.4.0.0
  matched all 330 checked physical-column references.
- Query 01 subsequently ran in one district's PowerSchool SQL Studio environment.
  Its results support using the enrollment checkbox as that installation's
  initial scope filter, including pre-registration forms that carry the flag.

These checks do not establish cross-version compatibility, successful execution
of queries 02 through 04, or accurate interpretation of all visibility rules.
District-specific outputs are intentionally kept outside this repository.

## Questions to resolve with live configuration

| Area | Required verification |
| --- | --- |
| Enrollment scope | Confirm the enrollment flag captures intended forms, including pre-registration, older forms, and unpublished definitions. |
| School availability | Resolve school-sharing values, special/default values, the relevant school population, and the role of `use_by_school_sharing`. Do not treat the owning school or a sharing-row count as effective availability. |
| Form conditions | Establish how field conditions combine, including grouping and AND/OR behavior. A zero count for one sharing type does not prove a form is unconditional. |
| Question workflows | Verify controller links, trigger encodings, multi-value matching, hidden/defaulted controllers, and whether current field values or in-progress answers control display. |
| Inherited conditions | Trace form, container, collection, and controller-chain restrictions. The draft exposes direct links rather than evaluating every ancestor. |
| Question order | Verify container identifiers, multi-column order, nested placement, duplicate positions, and elements with multiple placements. Numeric stored position is not sufficient to establish every visual sequence. |
| Composite elements | Compare contact, race, event, payment, collection, and document elements with their rendered subquestions. Some built-in questions are not standalone element rows. |
| Permissions and publication | Check role permissions, publication windows, single-student settings, and custom CSS in the relevant user context. |
| Export fidelity | Confirm SQL Studio preserves CLOB summaries. Use the individual sharing and detail statements when aggregated output is clipped. |
| Calculated fields | Form metadata identifies a dependency on a field; the logic calculating that field may live elsewhere and requires separate investigation. |

## Suggested live validation

1. Compare query 01 with the intended enrollment form list.
2. Run query 02 and reconcile its rows against query 01's element counts,
   allowing one retained row for each empty form.
3. Compare an ordinary form, a school-restricted form, a form restricted by
   student values, and a form with conditional questions against Form Builder
   and the relevant parent-facing context.
4. Inspect individual sharing records with query 03 and composite configuration
   using the applicable statement from query 04.
5. Record verified behavior separately from assumptions before implementing
   dashboard labels such as "all schools" or "always visible."

## Dictionary reference map

The source dictionary is not distributed with this project.

| Pages | Configuration |
| --- | --- |
| 40-43 | Form definitions, ownership, sharing flags, publication, and enrollment checkbox. |
| 45-46 | Answer choices, values, and stored order. |
| 49-52 | Pre-registration school preferences and collection placement. |
| 53-56 | Form elements, layout, permissions, mapped fields, and workflow. |
| 71 | School, student, and admin-role sharing records. |
| 72 | SIS document subquestions; no documented position column. |
| 28-29, 109-111 | Contact settings and configurable contact fields. |
