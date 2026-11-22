# What makes a good app — research checklist

Owner 2026-11-22: "I like white papers… what makes a good app". Each rule below comes from a published source and
says how it applies to RecipeFinder. Use it with `docs/PRODUCT.md` → Principles; check every new or changed screen
against it (reviewers and the challenger cite the rule number).

## Speed
1. **Instant means ≤100 ms; flow breaks past 1 s; attention is gone by 10 s.** Taps answer within 100 ms (highlight,
   haptic, placeholder) even when the work takes longer; anything over 1 s shows progress. — Miller 1968, *Response
   time in man-computer conversational transactions*; Nielsen 1993, *Response Times: The 3 Important Limits*.
2. **Fast systems get used more.** Keep screens under ~400 ms to useful content (Today, Discover, recipe open); guard
   them with `PerformanceBudgetTests`. — Doherty & Thadani 1982, *The Economic Value of Rapid Response Time* (IBM).

## Motion
3. **Animate to explain a change, never to decorate.** Motion shows where something came from or went. — Chang &
   Ungar 1993, *Animation: From Cartoons to the User Interface*; Heer & Robertson 2007, *Animated Transitions in
   Statistical Data Graphics*.
4. **Match duration to distance.** Small controls ~150–250 ms; full-screen moves ~350–500 ms; no bounce on
   full-screen moves (critically damped springs). Every gesture-driven motion is interruptible. Reduce Motion =
   cross-fades only. — Material Design motion (duration & easing); Apple HIG *Motion*; WWDC 2018 *Designing Fluid
   Interfaces*.

## Choice and decisions
5. **Fewer options, more decisions.** Show one clear pick plus an easy "another", not a wall of choices, wherever the
   job is deciding (Today, Plan deck). Endless browsing belongs only where browsing *is* the job (Discover). —
   Iyengar & Lepper 2000, *When Choice Is Demotivating*.
6. **More choices take longer to pick from; small targets far away take longer to hit.** Primary actions big and near
   the thumb; menus short. — Hick 1952 / Hyman 1953 (Hick–Hyman law); Fitts 1954 (Fitts's law).

## Habits, honestly
7. **Behaviour = motivation × ability × prompt.** Make the next cook easier (ability) before adding nudges (prompts);
   a prompt arrives when the person can act (e.g. Sunday plan nudge, not 3 am). — Fogg 2009, *A Behavior Model for
   Persuasive Design*.
8. **Calm by default.** Inform at the edge of attention; notifications are rare, useful and easy to switch off; no
   guilt streak loss. Rewards follow meals cooked, not time scrolled. — Weiser & Brown 1995, *Designing Calm
   Technology*.

## Quality
9. **Basics first, then delight.** Must-haves (import works, nothing lost, fast) only stop complaints; delight
   (pictures, Made-it moment, swipe deck) wins love — but never ship delight on broken basics. — Kano et al. 1984,
   *Attractive Quality and Must-Be Quality*.
10. **Nielsen's heuristics on every screen:** visible status; real-world words; undo and exits; consistency; prevent
    errors; recognition over recall; shortcuts for experts; minimal design; plain-language errors with a fix; help
    in context. — Nielsen 1994, *10 Usability Heuristics for User Interface Design*.

## Measuring (without tracking anyone)
11. **HEART:** Happiness, Engagement, Adoption, Retention, Task success — each roadmap item names one signal and how
    we'd notice it (on-device numbers, App Store analytics, tester feedback). — Rodden, Hutchinson & Fu 2010,
    *Measuring the User Experience on a Large Scale* (Google).

## Further reading
Norman, *The Design of Everyday Things*; Krug, *Don't Make Me Think*; Wathan & Schoger, *Refactoring UI*; Eyal,
*Hooked* (read critically — use rule 8 as the ethical limit); Apple Human Interface Guidelines.
