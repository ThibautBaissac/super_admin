# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SuperAdmin is a mountable Rails engine that provides a full-featured administration interface for Rails 8 applications. It's inspired by Administrate and ActiveAdmin, offering a modern approach with Turbo, Stimulus, and Tailwind CSS.

## Development Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake spec
# Or simply:
rake

# Run linting
rubocop

# Test in dummy app (Rails test mode)
cd test/dummy
rails server
```

## Key Architecture Patterns

### Dashboard-Based Resource Discovery

SuperAdmin uses an explicit dashboard pattern rather than auto-discovery. Only models with a corresponding dashboard class in `app/dashboards/super_admin/` appear in the admin interface.

- **DashboardRegistry** (app/services/super_admin/dashboard_registry.rb): Singleton that discovers and caches dashboard classes by scanning `app/dashboards/**/*_dashboard.rb`
- **BaseDashboard** (app/dashboards/super_admin/base_dashboard.rb): DSL for defining which attributes appear in collection/show/form views
- Dashboard classes define `collection_attributes`, `show_attributes`, and `form_attributes`

### Dynamic Resource Controller

**ResourcesController** (app/controllers/super_admin/resources_controller.rb) handles CRUD for all resources dynamically:

- Uses `params[:resource]` to determine which model to operate on
- **Resources::Context** wraps model discovery and dashboard resolution
- **Resources::PermittedAttributes** builds strong parameters dynamically based on model reflection
- All CUD operations trigger audit logging via **Auditing** service

### Query Object Pattern

Search, filter, and sort logic is delegated to query objects in `app/services/super_admin/queries/`:

- **ResourceScopeQuery**: Orchestrates search + filter + sort
- **SearchQuery**: Full-text search across text/string columns and associations
- **FilterQuery**: Applies filters from UI
- **SortQuery**: Handles sorting with association joins

These are coordinated by **ResourceQuery** service and **Resources::CollectionPresenter**.

### Form Field System

**FormBuilder** (app/services/super_admin/form_builder.rb) generates form inputs by introspecting ActiveRecord columns and associations. It delegates to field objects in `app/services/super_admin/form_fields/`:

- **Factory** detects field type from column/association metadata
- Field classes (AssociationField, EnumField, NestedField, etc.) render appropriate inputs
- Supports nested attributes up to configurable depth (default: 2 levels)

### Authorization & Authentication

**Authorization** (app/services/super_admin/authorization.rb) uses an adapter pattern:

- Auto-detects Pundit, CanCanCan, or falls back to proc/default
- Adapters in `app/services/super_admin/authorization_adapters/`
- Configuration in `config/initializers/super_admin.rb`:
  - `authorize_with`: proc/method for authorization
  - `authenticate_with`: proc/method for authentication
  - `current_user_method`: method name to fetch current user (default: `:current_user`)

### Background CSV Exports

- **CsvExportCreator** queues export jobs via Solid Queue
- **GenerateSuperAdminCsvExportJob** streams CSV to Active Storage
- Exports tracked in `SuperAdmin::CsvExport` model with token-based access

### Audit Logging

- **Auditing** service (app/services/super_admin/auditing.rb) records all create/update/destroy actions
- **AuditLog** model stores user, resource, action, changes, and context
- Automatically triggered from ResourcesController for all operations

## Generator Usage

```bash
# Install SuperAdmin (creates initializer + migrations)
rails generate super_admin:install

# Generate dashboards
rails generate super_admin:dashboard          # All models
rails generate super_admin:dashboard User     # Specific model
```

**InstallGenerator** (lib/generators/super_admin/install_generator.rb):
- Copies initializer template
- Runs `rake super_admin:install:migrations`

**DashboardGenerator** (lib/generators/super_admin/dashboard_generator.rb):
- Uses **DashboardCreator** (lib/super_admin/dashboard_creator.rb) to introspect models and generate dashboard files
- Creates files in host app's `app/dashboards/super_admin/` directory

## Configuration

Main config file: `config/initializers/super_admin.rb`

Key options:
- `max_nested_depth`: Controls nested form depth (default: 2)
- `association_select_limit`: Max options in association dropdowns (default: 10)
- `enable_association_search`: Enable async search for associations (default: true)
- `parent_controller`: Base controller to inherit from (default: `"::ApplicationController"`)
- `layout`: Layout template (default: `"super_admin"`)
- `default_locale`: I18n locale (default: `:fr`)

## Testing Strategy

- Uses Minitest with Rails integration
- Dummy app in `test/dummy/` for integration tests
- Generator tests in `test/lib/generators/`
- Test helper loads dummy app environment and migrations from both engine and dummy app

## JavaScript/Stimulus Architecture

SuperAdmin uses a **single-file bundled approach** for all JavaScript to avoid module resolution issues with Rails engines.

### Structure

```
app/javascript/
└── super_admin/
    └── application.js    # All-in-one file with 3 Stimulus controllers
```

### Bundled Stimulus Controllers

All controllers are defined inline in `app/javascript/super_admin/application.js`:

1. **AssociationSelectController**: Enhances association select dropdowns with async search for large datasets
   - Detects when total count exceeds displayed options
   - Creates search interface dynamically
   - Fetches results from `/super_admin/associations/search` endpoint
   - Used in forms for belongs_to/has_many associations

2. **BulkSelectionController**: Manages checkbox selection for bulk actions
   - Tracks selected items count
   - Handles "select all" toggle with indeterminate state
   - Updates counter display in real-time
   - Used in resource index views

3. **NestedFormController**: Handles dynamic nested attribute fields
   - Adds/removes nested record fields using templates
   - Manages `_destroy` flags for soft deletion
   - Uses `__NEW_RECORD__` placeholder replaced with timestamp
   - Respects `max_nested_depth` configuration

### Auto-Registration

Controllers are **automatically registered** when SuperAdmin pages are loaded:
- `app/javascript/super_admin/application.js` detects the host app's Stimulus instance (`window.Stimulus`)
- Auto-registers all three controllers with the `super-admin--` prefix
- No imports, no module resolution, no manual setup required

Views use `data-controller="super-admin--controller-name"` attribute.

### Importmap Integration

Minimal configuration for maximum compatibility:

```ruby
# config/importmap.rb
pin "super_admin/application"
```

- Engine initializer adds JavaScript paths to host app's asset pipeline (lib/super_admin/engine.rb:5-8)
- SuperAdmin layout explicitly imports `super_admin/application` module (app/views/layouts/super_admin.html.erb:111)
- Single file = no module resolution issues with engines

**No host app configuration required - everything is automatic!**

## Important Conventions

1. **Namespacing**: All engine code is under `SuperAdmin` module with isolated namespace
2. **Route helpers**: Custom RouteHelper module injected into ActionView, ActionController, and ViewComponent via engine initializer
3. **Resource params**: Dynamic resource name in URL (`:resource`) determines which model to manage
4. **Dashboard discovery**: Only models with dashboards in `app/dashboards/super_admin/` are accessible
5. **Audit exclusion**: AuditLog model explicitly excluded from auditing to prevent recursion
6. **Stimulus naming**: All Stimulus controllers use `super-admin--` prefix to avoid conflicts with host app controllers
