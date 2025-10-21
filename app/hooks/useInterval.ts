import { useEffect, useRef } from 'react';

export function useInterval(fn: () => void, delay: number | null) {
  const saved = useRef<() => void>(() => {});
  useEffect(() => { saved.current = fn; }, [fn]);
  useEffect(() => {
    if (delay == null) return;
    const id = setInterval(() => saved.current(), delay);
    return () => clearInterval(id);
  }, [delay]);
}
