# Develop: React

Rules from develop.md that apply only to React code.

- **React hooks.**
  - Derive values from props and state instead of storing them in state.
  - Turn the React Compiler on, and let it handle memoization.
  - Use `useMemo` or `useCallback` only when a stable identity or a measured cost needs it.
  - Use `useEffect` only to sync with something outside React, never to compute state.
  - Fetch data through a data-fetching layer, never in `useEffect`.
  - Move logic into a custom hook once a screen mixes concerns or the logic is used twice.
