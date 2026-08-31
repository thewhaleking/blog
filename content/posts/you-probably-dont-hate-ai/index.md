---
title: "You (Probably) Don't Hate AI"
date: 2026-08-31T14:20:11+02:00
authors: ["thewhaleking"]
tags: ["ai", "llm", "opinion"]
summary: "Evaluating your opinions on AI-produced code."
cover:
  image: "cover.png"
  alt: "AI slop"
  relative: true
draft: false
---

You've been programming since high school. You've honed your craft over many years. You survived the leetcode interview era. 
You maintain a few open-source projects, which has just gotten a PR opened from a community member. You open it, the description
is extensive, there's half a dozen new unit tests for the feature. The issue's been correctly linked. You test the feature. It doesn't
work, and now the right-aligned fonts are broken. "AI Slop…", you say as your cursor hovers over the Request Changes button,
"…I hate AI slop" before clicking "Close Pull Request". You pull up 𝕏 to see Linus Torvalds is embracing LLMs, you scroll down
and Dario is terrified that Claude 5.1-Morrowind has started a zombie apocalypse in simulation.

### What exactly is "AI slop"?

We've all seen it, and we all hate it, but defining it is like defining pornography, according to the Supreme Court: 
you know it when you see it. Surely Linus Torvalds is not putting out AI slop, but yet he's using AI to generate code. 
What's the difference between his code, and the PR you've just closed? Is it the model being used; is the Fiery Finn simply
better at English? The main difference is likely more so in the prompter than anything.


### Enshittification

You're probably familiar with the term "enshittification". It's been popular for well over a decade, long before the "rise of AI"
in the programming field. You're also likely familiar with the concept, having seen firsthand the degradation of software
in the last 10-15 years: Windows still takes forever to load, apps that show your flight tickets are half a gigabyte, your password
manager is spinning displaying "Updating" for a year and a half. 

Despite wonderful, modern IDEs; infinite resources for documentation; and the ability to `pip install` just about anything, 
software has been getting worse for a long time. It's because the wrong pilot is behind the controls, it's someone who
views programming as a means to collect a higher salary. They don't enjoy programming, at least not enough to learn enough
about it to make good software. We've applied the term "software engineer" broadly to every job that involves invoking a 
compiler, to the point where our peers in traditional engineering disciplines use the term pejoratively. Software engineering 
exists, definitely, but how much "coding" is truly software engineering?

Face it: the only people who care about and/or respect your craft are your peers. Your customers don't (directly) care,
your wife smiles and nods as you explain the new item you've just completed (she's a pharmacist who prefers to never touch
a computer in her life), your VP just wants to know when the new feature is coming out (bonus time is soon!), your
company's accountants see it the same as any other labor expense: can it be replaced with something cheaper?

### AI is simply a tool

You've likely seen the comparison of the "anti-AI" crowd to Luddites, 19th-century English textile artisans who protested
the Industrial Revolution.  Maybe it is the equivalent of the Industrial Revolution, but I think it's more akin to power tools.
Just as you've seen some absolute garbage made with power tools, you've certainly also seen some fine craftmanship using 
those same tools. The tool doesn't produce the craft — the craftsman does. 

Claude doesn't know what you consider important unless you tell it. It considers industry best practices, codebase patterns
and antipatterns, etc.; but there are always considerations specific to your implementation it cannot know unless you specifically
describe them. One of the most important aspects of software engineering is being able to precisely describe what you actually
want — a subject with which project managers have usually struggled.

AI-assisted programming has been incredible for me, personally; and the field of programming, generally. I do foresee the
elimination of a lot of jobs that we've filled over the years with people who see programming as just a money-making job,
and not something they are passionate about. I do not, however, foresee the elimination of programmers as a career. 

### In Conclusion

You probably don't hate AI. You hate the junk that's associated with it, but then again you probably hate that same junk
when it's independent of AI. I'm not going to go into the "AI uses all the water" or "AI makes electricity more expensive 
for poor people" debates, as these subjects have been fact-checked and debunked dozens of times by people far more
qualified to comment on the matter than myself.
