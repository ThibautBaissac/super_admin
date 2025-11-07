# CSS Build System

SuperAdmin uses precompiled Tailwind CSS to provide a plug-and-play experience without requiring users to configure Tailwind in their host applications.

## How it Works

### Architecture

1. **Source File**: `app/assets/stylesheets/super_admin/tailwind.source.css`
   - Contains Tailwind directives (`@tailwind base`, `@tailwind components`, `@tailwind utilities`)
   - Can include custom CSS if needed

2. **Configuration**: `tailwind.config.js`
   - Scans only SuperAdmin's files (views, components, helpers)
   - Generates CSS with only the classes actually used by SuperAdmin

3. **Compiled File**: `app/assets/stylesheets/super_admin/tailwind.css`
   - Precompiled, minified Tailwind CSS (~21KB)
   - Committed to the repository
   - Served as a regular Rails asset

4. **Layout Integration**: `app/views/layouts/super_admin.html.erb`
   - Loads the precompiled CSS via `stylesheet_link_tag`
   - No CDN required, no configuration required from users

### Benefits

✅ **Zero Configuration**: Users don't need to configure Tailwind in their app
✅ **No Conflicts**: SuperAdmin's CSS is self-contained and doesn't interfere with host app Tailwind
✅ **Better Performance**: No CDN requests, smaller file size (only used classes)
✅ **Offline Ready**: Works without internet connection
✅ **Production Ready**: CSS is already minified and optimized

## Rebuilding CSS

### When to Rebuild

You need to rebuild the CSS when:
- Adding new Tailwind classes to SuperAdmin views
- Modifying SuperAdmin components or helpers
- Updating to a new Tailwind version
- Adding custom CSS to the source file

### Prerequisites

```bash
# Make sure you have dependencies installed
bundle install
```

This installs `tailwindcss-rails` which includes the Tailwind CSS standalone binary.

### Build Script

```bash
# From the gem root directory
bin/build-css
```

The script will:
1. Locate the Tailwind CSS binary from the `tailwindcss-ruby` gem
2. Compile `tailwind.source.css` using the `tailwind.config.js` configuration
3. Generate minified CSS at `app/assets/stylesheets/super_admin/tailwind.css`
4. Show the final file size

### Manual Build

If you prefer to run the command manually:

```bash
# Find the tailwindcss-ruby gem path
TAILWINDCSS_PATH=$(bundle show tailwindcss-ruby)

# Run the compiler
$TAILWINDCSS_PATH/exe/tailwindcss \
  -i ./app/assets/stylesheets/super_admin/tailwind.source.css \
  -o ./app/assets/stylesheets/super_admin/tailwind.css \
  --minify
```

## Development

### Watching for Changes

During active development, you can use watch mode:

```bash
# Find the tailwindcss-ruby gem path
TAILWINDCSS_PATH=$(bundle show tailwindcss-ruby)

# Watch for changes
$TAILWINDCSS_PATH/exe/tailwindcss \
  -i ./app/assets/stylesheets/super_admin/tailwind.source.css \
  -o ./app/assets/stylesheets/super_admin/tailwind.css \
  --watch
```

This will automatically rebuild the CSS whenever you change SuperAdmin's view files.

### Adding Custom CSS

You can add custom CSS to `tailwind.source.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom SuperAdmin styles */
.super-admin-custom-class {
  /* Your custom styles here */
}
```

Then rebuild with `bin/build-css`.

## Troubleshooting

### "tailwindcss-rails gem not found"

Run `bundle install` to install the development dependencies.

### "Tailwind CSS binary not found"

The `tailwindcss-rails` gem installs `tailwindcss-ruby` as a dependency. Make sure both are installed:

```bash
bundle install
bundle show tailwindcss-ruby
```

### CSS classes not appearing

1. Make sure you've run `bin/build-css` after adding new classes
2. Check that your new classes are in files scanned by `tailwind.config.js`
3. Verify the compiled CSS file exists: `app/assets/stylesheets/super_admin/tailwind.css`
4. Restart the Rails server after rebuilding CSS

### File size too large

The CSS should be around 20-30KB when minified. If it's much larger:

1. Check if you've accidentally added all of Tailwind's classes
2. Verify your `tailwind.config.js` is only scanning SuperAdmin files
3. Make sure `--minify` flag is used during build

## CI/CD Integration

The precompiled CSS is committed to the repository, so users get it automatically when installing the gem. However, if you want to verify the CSS is up-to-date in CI:

```yaml
# .github/workflows/ci.yml
- name: Check CSS is up to date
  run: |
    bin/build-css
    git diff --exit-code app/assets/stylesheets/super_admin/tailwind.css
```

This will fail if the CSS needs to be rebuilt.

## For Gem Users

**You don't need to do anything!** The CSS is precompiled and included in the gem. It will work out of the box with zero configuration.

If you want to customize SuperAdmin's appearance:
1. Override specific views in your app
2. Add your own CSS that targets SuperAdmin elements
3. Use SuperAdmin's configuration options for colors/themes (if available)

Do **not** modify the gem's CSS files directly, as they will be overwritten on gem updates.
