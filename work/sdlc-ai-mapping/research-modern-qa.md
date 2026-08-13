# Modern QA / Testing / Validation Practice — Research Notes

**Date:** 2026-08-12
**Purpose:** Evidence base for placing quality activities on an SDLC map with an AI overlay.
**Method:** Claims traced to primary sources (original authors, standards bodies, first-party engineering blogs) where reachable; anything not verified at a primary source is marked **secondary** or **unverified**.

**TL;DR:** Modern product-engineering QA is a hybrid: quality work pushed *earlier* than coding (shift-left: reviews, static analysis, TDD/BDD, CI gates, tests derived from requirements) *and* pushed *past* release (shift-right: feature flags, canaries, chaos engineering, observability/SLOs, A/B experiments) — with the dedicated QA department largely dissolved into "developers own quality, QA specialists coach and build infrastructure" at Google, Microsoft, Atlassian, and Spotify. Deriving test plans from requirements before implementation is a well-established practice (ATDD/BDD/Specification by Example, and mandated in ISTQB/ISO terms as test design against a "test basis" with traceability), though the formal-standards version of it (ISO 29119) is contested by the context-driven testing school. Verification ("built the product right") and validation ("built the right product") remain formally distinct in IEEE/ISO/FDA usage, and validation has visibly migrated into production (beta programs, experiments, telemetry). AI is entering QA fastest at the unit-test-generation and fuzzing layers (real, measured deployments at Meta and Google), while "autonomous test agents" and "self-healing tests" remain mostly vendor-claimed; DORA's 2024–2025 research warns AI amplifies existing delivery strengths *and* dysfunctions rather than fixing quality fundamentals.

---

## 1. Hybrid shift-left + shift-right is the modern norm — CONFIRMED

**Shift-left** was coined by Larry Smith in *Dr. Dobb's Journal*, September 2001 ("Shift-Left Testing", [full text mirror](https://jacobfilipp.com/DrDobbs/articles/DDJ/2001/0109/0109e/0109e.htm), [ACM record](https://dl.acm.org/doi/10.5555/500399.500404)). Smith's original meaning: integrate QA and development so that test cases are developed earlier, testing starts earlier, and testing is automated as much as possible — "bugs are cheap when caught young." The term has since broadened to cover any quality activity moved earlier in the lifecycle: requirements review, static analysis/linting, TDD, security scanning ("shift-left security"), and CI quality gates.

**Shift-right** has no single canonical coiner (the term appears to have emerged from the DevOps vendor/platform ecosystem — **secondary** on origin), but its authoritative practitioner definition is well documented. Microsoft's official DevOps guidance, ["Shift right to test in production"](https://learn.microsoft.com/en-us/devops/deliver/shift-right-test-production), defines it as testing in production-like and production environments via ring-based/progressive deployment, [feature flags](https://learn.microsoft.com/en-us/devops/operate/progressive-experimentation-feature-flags), canary releases, and fault injection. The intellectual case for the right side comes from:

- **Testing in production as deliberate practice:** Charity Majors (Honeycomb co-founder), ["I test in prod"](https://increment.com/testing/i-test-in-production/) (Increment, 2019): every deploy *is* a test in production whether acknowledged or not; the mature move is to invest in tooling (observability, progressive delivery, instrumentation) to do it safely rather than pretend pre-production testing catches everything.
- **Chaos engineering:** the Netflix-originated discipline is defined at [principlesofchaos.org](https://principlesofchaos.org) — "the discipline of experimenting on a system in order to build confidence in the system's capability to withstand turbulent conditions in production."
- **Observability/SLOs:** Google's SRE book chapter on [Service Level Objectives](https://sre.google/sre-book/service-level-objectives/) formalizes error budgets — a production-side, quantitative quality contract that replaces "zero defects" with "acceptable unreliability spent deliberately."

The hybrid framing — validation at every stage, left and right, as "continuous testing" — is explicit in the Microsoft guidance above, and DORA's [Test Automation capability](https://dora.dev/capabilities/test-automation/) research ties continuous, developer-maintained automated testing to software delivery performance.

**So what for our SDLC map:** quality is not a phase; the map needs quality activities attached to *every* SDLC stage, and it needs a production/operate stage with first-class quality activities (canary, flags, chaos, SLO monitoring, experimentation) — not just "maintenance." The left/right vocabulary is safe to use; attribute shift-left to Smith 2001 and define shift-right operationally per Microsoft/Majors.

---

## 2. Test plans derived from requirements/PRDs before implementation — CONFIRMED as established practice, with a contested formal wing

"Write the tests (or at least the test plan/acceptance criteria) from the requirements before implementing" has at least four established lineages:

- **BDD:** Dan North's original article ["Introducing BDD"](https://dannorth.net/introducing-bdd/) (first published in *Better Software*, March 2006) reframes TDD as behaviour specification: acceptance criteria written as executable "Given/When/Then" scenarios *from the requirements*, before code. North explicitly connects this to acceptance-test-driven planning — a story's behaviour is defined by its acceptance criteria up front.
- **Specification by Example:** Gojko Adzic's book ([official page](https://gojko.net/books/specification-by-example/), Manning 2011) documents, from ~50 case studies, the practice of deriving executable specifications from collaboratively refined examples during requirements work ("living documentation"). This is the direct ancestor of "the PRD's examples become the test suite."
- **Agile Testing Quadrants:** Brian Marick's original 2003 "agile testing directions" series on his blog ([Exploration Through Example, Aug 2003](http://www.exampler.com/old-blog/2003/08/22/)) introduced the business-facing vs technology-facing × support-the-team vs critique-the-product matrix. Lisa Crispin and Janet Gregory popularized it as the Agile Testing Quadrants in *Agile Testing* (2009; [book site](https://agiletester.ca) — **secondary** for the book's content, the quadrant attribution to Marick is confirmed at his blog). Q2 ("business-facing, supporting the team") is exactly the derive-tests-from-requirements-before/while-building activity.
- **Standards:** ISTQB's Foundation syllabus ([istqb.org](https://www.istqb.org/)) makes test analysis/design activities that work from a "test basis" (requirements, user stories, PRDs) and maintain **traceability between test basis and test cases** core certified vocabulary (**secondary** — syllabus PDF not fetched this session, but this is stable, widely documented ISTQB content). [ISO/IEC/IEEE 29119-1:2022](https://www.iso.org/standard/81291.html) likewise frames test plans/strategies derived from requirements under risk-based testing.

**The complication — ISO 29119 is contested.** The context-driven testing community (James Bach, Michael Bolton, the International Society for Software Testing) ran the 2014 ["Stop 29119" petition](https://www.ipetitions.com/petition/stop29119) arguing the standard lacks practitioner consensus and over-weights documentation and up-front plans; Michael Bolton's [FAQ on the controversy](https://developsense.com/blog/2014/09/frequently-asked-questions-about-the-29119-controversy) is the best primary statement of the objection. So "test plan from the PRD" is mainstream, but *how formal* that plan should be is genuinely disputed: the agile lineages above want executable examples and conversations, not documents; the standard wants documented plans; context-driven testers want neither imposed universally.

**So what for our SDLC map:** placing "generate test plan / acceptance criteria from PRD" at the requirements stage is defensible and well-precedented — but the map should distinguish *acceptance criteria & executable examples* (agile-native, collaborative) from *formal documented test plans* (regulated/contract contexts), because the field treats these differently. An AI overlay that drafts Given/When/Then scenarios from a PRD sits squarely on the ATDD/BDD/SbE lineage.

---

## 3. Developers own quality; dedicated QA re-scoped to enablement — CONFIRMED, with nuance ("re-scoped" more than "disappeared")

- **Google:** the Google Testing Blog's *How Google Tests Software* series (2011) states the position directly — ["Quality is not equal to test... quality is a development issue, not a testing issue"; SWEs "own quality for everything they touch"](https://testing.googleblog.com/2011/02/how-google-tests-software-part-two.html). The specialist roles that remain are engineering roles: Software Engineer in Test (later **SETI** — Software Engineer, Tools & Infrastructure) building test infrastructure, and [Test Engineers](https://testing.googleblog.com/2013/01/test-engineers-google.html) doing user-focused risk analysis. In 2016 Google renamed the whole organization from "QA" framing to ["Engineering Productivity"](https://testing.googleblog.com/2016/03/from-qa-to-engineering-productivity.html) — the clearest first-party statement that the dedicated-QA function became an enablement/infrastructure function.
- **Microsoft:** retired the dedicated SDET role around mid-2014 in the shift to "combined engineering" (unified engineer role owning feature + tests), driven by the move to cloud cadence. Best available account is Gergely Orosz's researched write-up ["How Microsoft does QA"](https://blog.pragmaticengineer.com/how-microsoft-does-qa/) (**secondary** — Microsoft published no single first-party announcement of the SDET retirement; corroborated by many ex-Microsoft primary testimonies).
- **Atlassian:** first-party ["Introducing Atlassian QA"](https://www.atlassian.com/blog/inside-atlassian/introducing-atlassian-qa) describes their **"Quality Assistance"** model: developers test their own features to production standard; QA engineers coach, train, and build capability rather than execute test passes ([skills follow-up](https://www.atlassian.com/blog/software-teams/6-essential-skills-quality-assistance-engineer)).
- **Spotify:** first-party ["Testing of Microservices"](https://engineering.atspotify.com/2018/01/testing-of-microservices) (2018) shows developer-owned testing strategy and also contributes the **testing honeycomb** (integration-heavy shape for microservices) to the shapes debate.
- **DORA/Accelerate:** the research program behind *Accelerate* (Forsgren, Humble, Kim, 2018) finds that continuous testing — with **developers primarily creating and maintaining acceptance tests**, tests run throughout delivery, fast feedback — predicts software delivery performance ([DORA Test Automation capability](https://dora.dev/capabilities/test-automation/)). This is the strongest quantitative evidence that developer-owned automated quality correlates with performance outcomes.
- **martinfowler.com canon:** Martin Fowler's ["Eradicating Non-Determinism in Tests"](https://martinfowler.com/articles/nonDeterminism.html) (2011) treats flaky-test management as an engineering discipline; Ham Vocke's ["The Practical Test Pyramid"](https://martinfowler.com/articles/practical-test-pyramid.html) (2018) is the standard developer-owned test-portfolio reference.
- **The shapes disagreement (present it, don't flatten):** the classic **test pyramid** (many unit, fewer integration, few E2E — Fowler/Vocke, above) vs Kent C. Dodds's **testing trophy** (most value in integration tests; ["The Testing Trophy and Testing Classifications"](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications), ["Write tests. Not too many. Mostly integration."](https://kentcdodds.com/blog/write-tests)) vs Spotify's **honeycomb** (above). Fowler's own adjudication, ["On the Diverse And Fantastical Shapes of Testing"](https://martinfowler.com/articles/2021-test-shapes.html) (2021), argues the shapes disagree less than they appear to: the real variable is what "unit"/"integration" mean in context, and the load-bearing property is a fast, reliable, mostly-automated suite.
- **Nuance:** the honest reading is *re-scoped, not extinct*. Google kept TEs/SETIs; Atlassian kept QA engineers (as coaches); regulated industries and games/hardware still run dedicated test organizations; and the context-driven school (Bach/Bolton, see §2) argues skilled exploratory testing is a distinct craft that developer-ownership models under-serve — a live disagreement, not a settled fact.

**So what for our SDLC map:** don't draw a "QA phase" owned by a QA team. Draw quality activities owned by the feature team at every stage, plus a cross-cutting "quality enablement" function (test infrastructure, coaching, risk analysis) — that's where the modern dedicated-QA headcount actually sits, and it's also the natural anchor point for AI test tooling (AI as the new SETI-style infrastructure).

---

## 4. Verification vs validation — distinction confirmed and stable in standards; validation has moved into production in practice

- **IEEE:** [IEEE 1012 (System, Software, and Hardware Verification and Validation; current edition 2024)](https://ieeexplore.ieee.org/document/11134780) is the governing V&V standard: **verification** checks that the products of a development activity conform to that activity's requirements (built *right*); **validation** checks the product satisfies its intended use and user needs (built the *right thing*).
- **Vocabulary:** [ISO/IEC/IEEE 24765 (Systems and software engineering — Vocabulary)](https://www.iso.org/obp/ui/#iso:std:iso-iec-ieee:24765:en) carries the same paired definitions as the cross-standard reference.
- **Safety-critical:** the FDA's guidance ["General Principles of Software Validation"](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-principles-software-validation) (2002; still the canonical framing for medical-device software) defines validation as "confirmation by examination and provision of objective evidence that software specifications conform to user needs and intended uses" — i.e., validation is explicitly about *user needs*, with documented evidence and a risk-based approach.
- The "building the product right vs building the right product" slogan is conventionally attributed to Barry Boehm (early 1980s) — **secondary** (widely attributed; original passage not fetched).
- **Where validation lands in modern practice:** the pre-production forms are UAT and beta/early-access programs; the shift-right practices in §1 are validation instruments too — A/B experiments and progressive rollouts validate that the built thing actually serves users, with production telemetry as the evidence stream (Microsoft's [progressive experimentation guidance](https://learn.microsoft.com/en-us/devops/operate/progressive-experimentation-feature-flags) frames flags/canaries exactly as hypothesis-testing on real users). In other words: verification stayed left (CI, reviews, automated tests against specs); a large share of validation moved right, into production.

**So what for our SDLC map:** keep V&V as two distinct swim-lanes or tags. Verification activities cluster at design→build→CI stages; validation activities appear twice — pre-release (UAT/beta) *and* post-release (experiments, telemetry, SLO review). An AI overlay must respect the distinction: generating tests from a spec is verification support; LLM-as-judge over user-facing behaviour or telemetry analysis is validation support.

---

## 5. Where AI is entering QA (2024–2026) — real at the test-generation and fuzzing layers; agentic/self-healing claims still mostly vendor-grade

Ranked by evidence quality:

- **LLM unit-test generation, industrially deployed (HIGH evidence):** Meta's TestGen-LLM — ["Automated Unit Test Improvement using Large Language Models at Meta"](https://arxiv.org/abs/2402.09171) (FSE 2024 industry track) — uses "Assured LLM-based Software Engineering": every generated test must pass filters (builds, passes repeatedly, measurably increases coverage) before a human sees it. Measured results: 75% of generated cases built, 57% passed reliably, 25% increased coverage; 73% of recommendations accepted by Meta engineers. The design lesson generalizes: LLM output gated by objective verification beats raw generation.
- **AI-boosted fuzzing (HIGH evidence):** Google's OSS-Fuzz has used LLMs to write fuzz targets since 2023 (["AI-Powered Fuzzing: Breaking the Bug Hunting Barrier"](https://security.googleblog.com/2023/08/ai-powered-fuzzing-breaking-bug-hunting.html), Google security blog — URL from memory, findings corroborated by [secondary coverage](https://thehackernews.com/2024/11/googles-ai-powered-oss-fuzz-tool-finds.html)): ~30% coverage gains across 300+ C/C++ projects and, by late 2024, 26 new real vulnerabilities including a 20-year-old OpenSSL flaw (CVE-2024-9143). This is property-based/fuzz testing genuinely advanced by AI, in production, with CVEs to show.
- **Test generation from requirements/PRDs (MEDIUM, rapidly moving):** the ATDD/BDD lineage (§2) gives AI a natural slot — draft Given/When/Then scenarios and test plans from a PRD. As of 2024–2026 this is offered by most AI coding assistants and QA vendors, but there is no peer-reviewed deployment study on requirements→test-plan generation comparable to TestGen-LLM — treat effectiveness claims as **unverified**; the *practice pattern* it automates is solidly established.
- **LLM-as-judge for validation (MEDIUM, research-grounded but known-flawed):** the technique is anchored by ["Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena"](https://arxiv.org/abs/2306.05685) (Zheng et al., NeurIPS 2023), which both validated GPT-4-as-judge (~80%+ agreement with humans) and catalogued its biases (position, verbosity, self-enhancement). In QA practice it appears as automated evaluation of AI-product outputs and NL acceptance checking — usable, but it is a *validation heuristic with documented failure modes*, not a verification oracle.
- **Self-healing tests (LOW/vendor-claimed):** auto-repairing UI locators when the DOM changes — open-source [Healenium](https://healenium.io) plus commercial offerings (mabl, testRigor, Applitools). No independent deployment studies located; treat quantitative vendor claims as **unverified/hype-adjacent**. The underlying idea (reduce brittle-selector maintenance) is plausible and narrow.
- **Autonomous test agents (LOW, frontier):** agents that explore an app and design their own tests. Active research and vendor demos in 2025–2026, no Meta/Google-grade published deployment evidence found — **hype-leaning; watch, don't rely**.
- **The system-level caution (HIGH evidence):** DORA's [2024 report](https://dora.dev/research/2024/dora-report/) found a 25% increase in AI adoption associated with an estimated **1.5% decrease in delivery throughput and 7.2% decrease in delivery stability** — attributed to larger batch sizes and weakened fundamentals; the [2025 report (State of AI-assisted Software Development)](https://dora.dev/dora-report-2025/) (90% of ~5,000 respondents using AI) concludes AI acts as an **amplifier** of existing organizational strengths and dysfunctions. For QA specifically: AI accelerates code production, which *raises* the value of strong automated quality gates rather than substituting for them.

**So what for our SDLC map:** the AI overlay should be strongest where verification is mechanically checkable (unit-test generation, fuzzing, CI triage) and clearly labeled as assistive/heuristic where it touches validation (LLM-as-judge, requirement-to-scenario drafting needing human review). Add the DORA caveat to the map's narrative: AI increases change volume, so the quality lanes get *more* load-bearing under AI, not less.

---

## Open questions / disagreements in the field

1. **Formal test documentation vs context-driven testing** (ISO 29119 vs Stop-29119): unresolved; choose per regulatory context, not by picking a winner.
2. **Test shapes** (pyramid vs trophy vs honeycomb): partially reconciled by Fowler 2021 as a definitional dispute, but teams still fight about E2E investment levels.
3. **Is dedicated QA disappearing or re-scoping?** Big-tech evidence says re-scoping into enablement/infrastructure roles; the context-driven school argues exploratory-testing skill is being lost; regulated domains never dissolved QA. Both trends are real in different segments.
4. **Where did the shift-right term come from?** No authoritative coiner found; only operational definitions (Microsoft, Dynatrace, vendors). Origin remains **unverified**.
5. **Does AI test generation improve *quality outcomes* (escaped defects), not just coverage?** TestGen-LLM measured coverage and acceptance, not defect escape rates; no strong published evidence yet.
6. **LLM-as-judge reliability for acceptance/validation decisions** — known biases (MT-Bench) vs growing production use; calibration and human-override design are open practice questions.

---

## Sources

**Shift-left / shift-right**
- Larry Smith, "Shift-Left Testing", Dr. Dobb's Journal, Sept 2001 — [mirror](https://jacobfilipp.com/DrDobbs/articles/DDJ/2001/0109/0109e/0109e.htm), [ACM](https://dl.acm.org/doi/10.5555/500399.500404)
- Microsoft Learn, [Shift right to test in production](https://learn.microsoft.com/en-us/devops/deliver/shift-right-test-production); [Progressive experimentation with feature flags](https://learn.microsoft.com/en-us/devops/operate/progressive-experimentation-feature-flags)
- Charity Majors, [I test in prod](https://increment.com/testing/i-test-in-production/) (Increment)
- [Principles of Chaos Engineering](https://principlesofchaos.org)
- Google SRE Book, [Service Level Objectives](https://sre.google/sre-book/service-level-objectives/)

**Requirements-to-tests lineages & standards**
- Dan North, [Introducing BDD](https://dannorth.net/introducing-bdd/)
- Gojko Adzic, [Specification by Example](https://gojko.net/books/specification-by-example/)
- Brian Marick, [Agile testing directions (Exploration Through Example, 2003)](http://www.exampler.com/old-blog/2003/08/22/)
- Crispin & Gregory, [Agile Testing book site](https://agiletester.ca)
- [ISTQB](https://www.istqb.org/) (CTFL syllabus — test basis, traceability)
- [ISO/IEC/IEEE 29119-1:2022](https://www.iso.org/standard/81291.html); [Stop 29119 petition](https://www.ipetitions.com/petition/stop29119); Michael Bolton, [29119 controversy FAQ](https://developsense.com/blog/2014/09/frequently-asked-questions-about-the-29119-controversy)

**Developer-owned quality**
- Google Testing Blog: [How Google Tests Software, Part Two](https://testing.googleblog.com/2011/02/how-google-tests-software-part-two.html); [Test Engineers @ Google](https://testing.googleblog.com/2013/01/test-engineers-google.html); [From QA to Engineering Productivity](https://testing.googleblog.com/2016/03/from-qa-to-engineering-productivity.html)
- Gergely Orosz, [How Microsoft does QA](https://blog.pragmaticengineer.com/how-microsoft-does-qa/) (secondary)
- Atlassian, [Introducing Atlassian QA](https://www.atlassian.com/blog/inside-atlassian/introducing-atlassian-qa); [Quality assistance skills](https://www.atlassian.com/blog/software-teams/6-essential-skills-quality-assistance-engineer)
- Spotify Engineering, [Testing of Microservices](https://engineering.atspotify.com/2018/01/testing-of-microservices)
- DORA, [Test Automation capability](https://dora.dev/capabilities/test-automation/)
- martinfowler.com: [Eradicating Non-Determinism in Tests](https://martinfowler.com/articles/nonDeterminism.html); [The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) (Ham Vocke); [On the Diverse And Fantastical Shapes of Testing](https://martinfowler.com/articles/2021-test-shapes.html)
- Kent C. Dodds: [The Testing Trophy and Testing Classifications](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications); [Write tests. Not too many. Mostly integration.](https://kentcdodds.com/blog/write-tests)

**Verification & validation**
- [IEEE 1012-2024](https://ieeexplore.ieee.org/document/11134780); [ISO/IEC/IEEE 24765 vocabulary](https://www.iso.org/obp/ui/#iso:std:iso-iec-ieee:24765:en)
- FDA, [General Principles of Software Validation](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-principles-software-validation)

**AI in QA**
- Alshahwan et al., [Automated Unit Test Improvement using LLMs at Meta (TestGen-LLM)](https://arxiv.org/abs/2402.09171)
- Google Security Blog, [AI-Powered Fuzzing](https://security.googleblog.com/2023/08/ai-powered-fuzzing-breaking-bug-hunting.html) (URL from memory) + [secondary coverage of the 26-vulnerability result](https://thehackernews.com/2024/11/googles-ai-powered-oss-fuzz-tool-finds.html)
- Zheng et al., [Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena](https://arxiv.org/abs/2306.05685)
- DORA, [2024 Accelerate State of DevOps Report](https://dora.dev/research/2024/dora-report/); [2025 State of AI-assisted Software Development](https://dora.dev/dora-report-2025/)
- [Healenium](https://healenium.io) (self-healing tests, open source; vendor-grade evidence)
