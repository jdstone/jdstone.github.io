#!/usr/bin/env bash
#
# After making theme changes to build locally, this script rewrites _config.yml so it will properly build on GitHub.

cat _config.yml | sed 's/theme: jekyll-theme-hydejack/#theme: jekyll-theme-hydejack/' | sed 's/#remote_theme: hydecorp\/hydejack@v9/remote_theme: hydecorp\/hydejack@v9/' > _config.yml.tmp

mv _config.yml.tmp _config.yml
