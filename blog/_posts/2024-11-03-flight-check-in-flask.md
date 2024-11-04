---
layout: post
title: Conversion of PHP Flight Check-in app to Python/Flask
sitemap: false
hide_last_modified: true
---

About 4 years ago, I wrote an app in PHP that could automatically check you in to your Southwest Airlines flight. It ran really well for about a year, maybe a little more, until Southwest figured out that I, or someone, was using their public API to check myself and friends in to our flights automatically. I've written a lengthy README over in the [original repo](https://github.com/jdstone/flight-check-in) (this is before I had my blog here) that explains thoroughly how the application works and all the nitty gritty details of it.

# Reasoning behind re-writing in Python

I wanted to learn Python, the motivation being primarily for my job, DevOps, but it turned into much more! I converted this PHP app to Python using Flask as the web framework. The application is exactly the same as my PHP application, it's just written in Python. I found that I enjoy working with Python (and Flask) and look forward to more projects in the near future.

# Test Suite

As I mentioned previously, Southwest got all the wiser and put an end to my flight auto check-in's and I needed a way to check my PHP code, and confirm it still works, because it was a mess of code and comments. So, I wrote an API that would mimic Southwest Airlines' API (also written in PHP) -- I call this my Flight Check-in Test Suite.

This too, I also re-wrote in Python using Flask. This test suite gives the ability to anyone to see that my check-in app actually works as it was originally written.

# Conclusion

I had so much fun with this, I just kept trying to find things to improve in the application even though it could never actually be used. But I've got a list of skills to improve upon and new skills to acquire, that I have to shelve any further (worthless) improvements to this application. :smile:

# Links

* Automatic Flight Check-in (PHP): [https://github.com/jdstone/flight-check-in](https://github.com/jdstone/flight-check-in)
* Automatic Flight Check-in (Python/Flask): [https://github.com/jdstone/flight-check-in-flask](https://github.com/jdstone/flight-check-in-flask)
* Test Suite: [https://github.com/jdstone/flight-check-in-test-suite](https://github.com/jdstone/flight-check-in-test-suite)
