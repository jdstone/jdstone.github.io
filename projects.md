---
# The name of the tag, used in a post's front matter (e.g. tags: [<slug>]).
slug: projects

# (Optional) You can disable grouping posts by date.
# no_groups: true

# Featured tags need to have either the `list` or `grid` layout (PRO only).
layout: page
title: Projects
description: >
  Contains various projects I've completed.
hide_description: true
---
For some of my projects, please see my [blog](/blog).

{% for projects in site.projects %}
  <h2>
    <a href="{{ projects.url }}">
      {{ projects.title }}
    </a>
  </h2>
  <p>{{ projects.description | markdownify }}</p>
{% endfor %}

