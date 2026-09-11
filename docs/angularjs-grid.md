# AngularJS and PowerSchool grid conventions

Reference review completed September 10, 2026. This document records the
implementation baseline; no dashboard page or data endpoint exists yet.

## Runtime and structure

Target **AngularJS 1.4.7**, as required for this project. Load the PowerSchool
runtime through RequireJS rather than shipping Angular or a separate grid library.
Avoid Angular APIs introduced after 1.4.7, including `.component()`.

Use the modular structure demonstrated in the AngularJS training presentation
and the PowerSchool General AngularJS Setup example:

```text
web_root/
  admin/enrollment_express_form_explorer/
    home.html
  scripts/components/enrollment_express_form_explorer/
    index.js
    module.js
    controllers/
      index.js
      explorer.js
    services/
      index.js
      form_inventory.js
    views/
```

The module depends on `powerSchoolModule`. Its entry point loads
`components/shared/index`, the module, and the controller and service indexes.
Use explicit array dependency injection and `controllerAs` with a `vm` object.
The page's `data-module-name` must exactly match the registered Angular module
name; it is not the JavaScript variable holding the module.

Use `data-require-path`, `data-module-name`, and the documented local bootstrap
pattern. Do not add a second manual bootstrap over the same page. Prefer
`data-ng-*` attributes, matching the presentation. Pass required PSHTML context
through page attributes and normalize its types at the service boundary.
Component views cannot contain PSHTML; keep server substitutions in the admin
page or an appropriate server endpoint.

Use native admin headers, navigation, footer, common scripts, and screen/print
styles. Match native tables, feedback messages, and controls. Any project CSS
must be scoped and distributed with this project; do not depend on district CSS.

## Native grid contract

The widget enhances a normal HTML table. Each grid needs a stable, unique ID.

| Binding or attribute | Intended use |
| --- | --- |
| `data-pss-grid-widget` | Attach the native grid to a wrapper around `table.grid`. |
| `data-data="vm.items"` | Supply the complete loaded dataset for a client-side grid. |
| `data-filtered-data="vm.visibleItems"` | Receive rows to render; repeat table rows over this output. |
| `data-client-side-pagination="true"` | Enable local pagination after loading the complete dataset. |
| `data-filtertap-data-sorted="vm.matchingItems"` | Receive all filtered and sorted rows before client-side pagination. |
| `data-pss-sort-fields="position\|number"` | Declare a numeric sort/filter field; normalize input numbers first. |
| `data-primary-sort="ascending"` | Set initial ordering on the appropriate header. |
| `data-pss-filter-field` | Add a filter independent of visible columns. |
| `data-filter-info` | Supply label-to-value maps for selection filters. |
| `data-persist-rows-per-page="true"` | Preserve page-size preference using the grid's stable ID. |

With client-side pagination, `visibleItems` contains only the current page.
Use the full matching dataset for an eventual "Export filtered results" action
and filtered totals. Verify the full-list binding against supported installations
before relying on it; these details were confirmed in the reviewed installed
directive, not every PowerSchool release.

Keep native basic and advanced filters available. Use typed fields for numbers,
dates, and selection values. `multiselect-dropdown` is a useful candidate for
long option lists such as schools or forms. Build option maps before mounting
the grid, as demonstrated by the Staff Changes grids. Matching field definitions
must use consistent types and selection maps across filters and headers.

Do not assume a scalar multiselect filter can interpret a form's aggregated list
of school restrictions. Define and verify that data shape before offering a
school-availability filter. A configured school rule and effective availability
are different facts.

Multi-field sort declarations can provide stable secondary ordering. They do
not establish nested question order that the underlying SQL has not resolved.
Keep displayed headers and cells aligned when columns are shown or hidden.

The example page documents `no-filters`, `simple-only`, and `advanced-only`
filter constraints, plus default filters and negative comparators. Use these
only for a specific requirement; Form Explorer needs both text search and
structured filtering.

`haltFunction` is a navigation/refresh gate, not a loading indicator. The reviewed
directive stops when the callback returns **true**, which conflicts with wording
in the example description. No halt callback is needed for the initial read-only
inventory. Confirm runtime behavior before adopting this optional hook.

## Data access and user states

Keep loading and normalization in a service. Use Angular `$http` promises and
`$q.all` when independent requests must finish together. Propagate request
failures and end loading in a completion handler. `ng-cloak` prevents an initial
template flash; it does not represent completion of asynchronous data loading.

Provide distinct loading, failed-request, empty-inventory, and no-filter-matches
states. Preserve identifiers separately from labels. Render question text and
stored expressions as text; do not compile metadata as Angular or insert it as
trusted HTML.

The final endpoint choice remains open. The MBA reference demonstrates schema
query services, while existing projects also use relative JSON endpoints. First
validate the inventory SQL in SQL Studio, then adapt it to a read-only endpoint
with appropriate administrator permissions. A client-side school filter is not
an authorization boundary. Never infer completeness from a truncated response;
verify any endpoint's paging contract before using client-side pagination.

Avoid copying teaching-example errors: mismatched module names, resolving the
wrong deferred promise, or closing a loading indicator before the request ends.

## Proposed dashboard organization

- Forms view: browse form definitions, publication state, configured school
  rules, and condition evidence, retaining forms that have no elements.
- Questions view: search question text across forms and filter metadata with
  the native grid. Keep layout/hidden elements identifiable rather than counting
  every element as a visible question.
- Detail view: show the owning form, mapped fields, choices, stored placement,
  direct controller links, and raw restrictions with their validation status.

Use labels such as "Configured school rules" and "Display condition" until
effective availability is established. Do not label unknown restrictions as
"All schools" or "Always visible." See [SQL validation](validation.md) for the
remaining questions about inherited conditions, nested order, and composite
elements.

## Sources and precedents

The following paths are relative to an authenticated PowerSchool server, not
files distributed by this repository:

| Source | Review scope |
| --- | --- |
| `/admin/ui_examples/angularGridWidget.html` | Mode descriptions and examples for basic grids, client pagination, default sorting, filters, multiselect dropdowns, external fields, negative comparators, and navigation gates. |
| `/admin/ui_examples/gridwidgetexamples/` | Example-file paths identified from the grid examples page. |
| `/admin/ui_examples/angularjs/generalangularsetup.html` | RequireJS loading, module organization, controllers, services, and views. |
| `/scripts/components/widgets/directives/gridWidget.js` | Installed directive source inspected through Custom Page Management; binding, filtering, sorting, pagination, and halt behavior. |
| `/admin/mbaCustomizationReference/jsjq.html` | AngularJS section: initialization, directives, services, HTTP, schema queries, and parallel requests. |
| PACA2023 - Part 3 - Angular JS | User's presentation: slides 7, 16-22, 37, 42-61, 68-74, 85-93, and 100-101 inform runtime, organization, data loading, and grid conventions. |

Local precedents reviewed include the Enrollment Express Modules enrollment
dashboard, Staff Changes grid views and service organization, Student Checkers'
sacrament checker, and Health Log's log-list grid. The closest visual and
structural precedents are the enrollment dashboard's `vm` controller and the
Staff Changes typed filters and school-map initialization. Reuse their patterns
without district-specific rules, identifiers, or unrelated dependencies.

Vendor source and private research remain outside tracked files. Live reference
review establishes the intended integration approach; it does not validate the
future plugin's data access or installed behavior.
