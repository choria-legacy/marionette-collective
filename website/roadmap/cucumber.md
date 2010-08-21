---
layout: mcollective
title: Cucumber Testing Suite
disqus: true
---

# {{page.title}}

|                    |         |
|--------------------|---------|
|Target release cycle|**1.0.x**|

## Overview

There isn't an automated testing suite today, we should work towards unit testing but to kick it off a cucumber based test suite for agents might be a good start for both internal project use and users.

You should be able to write scenarios that describe the behavior of a call to an agent, it should do the call over MC and evaluate the result.

Cucumber is a good choice for this as its BDD, we can provide some generic step definitions for users to use when writing their own agents.
