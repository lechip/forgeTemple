# Coding standards

The `reviewer-code` agent reads this file and applies it to each diff. The `implementer` agent follows the "Tests" section.

This is a starter set for a TypeScript project. Edit it for your project. Keep each rule short and checkable. If a review finding repeats, add a rule here.

## TypeScript

- No `any`. Use `unknown` and narrow it. No `as` cast unless a comment says why it is safe.
- No `@ts-ignore`. No `@ts-expect-error` without a reason on the same line.
- Give exported functions explicit parameter and return types.
- Validate data that comes from outside (requests, files, environment, outside services) at the boundary. Inside the boundary, trust the types.
- Prefer `const`. Do not mutate function arguments.
- Use one shared type for one concept. Do not declare the same shape twice.

## Design

- A module has a small public interface and hides its details. Tests and callers use the interface only.
- A function does one thing. If you need "and" to describe it, split it.
- Do not add an abstraction, an option, or a parameter that has only one user.
- Do not copy code that exists in the repository. Use it or extract it.
- Put outside services (email, payment, login providers, outside APIs) behind an interface. Business code depends on the interface.
- Delete dead code. Do not comment it out.

## Errors

- Do not swallow errors. No empty `catch`.
- Throw or return errors with a message that says what failed and with which input.
- Handle errors at the boundary (route handler, job runner). Do not catch in the middle only to log and throw again.
- Do not show internal error details to the user.

## Naming and layout

- Names say what a thing is or does. No abbreviations that are not common in the project.
- Follow the file and folder patterns of the code near the change.
- A comment says why, not what. Delete comments that repeat the code.
- No `console.log` left in production code. Use the logger of the project.

## Tests

### The one question

Before each test, ask: **"Would this test fail if the implementation were wrong?"** If no, the test must not exist.

### Rules

- Test behaviour through the public interface. Do not test private functions or internal state.
- One test for each distinct behaviour. The test name says the behaviour.
- Use a table test (`it.each`) for cases that differ only in data.
- Use the lowest level that proves the behaviour:
  - Unit test: logic with no I/O. This is the default.
  - Integration test: behaviour that needs the real database, a real HTTP route, or wiring that has logic.
  - End-to-end test: only when the spec asks for it.
- Use a fake only at an outside boundary: network, time, random numbers, outside services.
- Never fake the unit under test.
- The expected value in an assertion is written by hand. Do not compute it with the same logic as the code under test.
- A test does not depend on a different test or on run order.
- For components, drive the test through user actions and assert on what the user sees.

### Tests that must not exist

- A test that repeats a constant or a config value.
- A test that returns X from a fake and then asserts X.
- A test for something the type system already prevents.
- A test that reads source text or checks the order of lines.
- A test that fakes away the failure it claims to check.
- A test of a library or the framework.
- A second test for behaviour that a different test already covers, at the same level or a higher level.
- A snapshot of a large structure with no specific assertion.

### What tests cannot check

Do not write a weak test for these. List them under "Manual checks" in the spec:

- Visual look and layout.
- Map rendering and embedded outside content.
- Real outside services (real login provider, real email, real captcha).
