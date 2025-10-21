import { useRef, useCallback } from 'react';

export function useDebouncePress(callback, delay = 300) {
  const isProcessing = useRef(false);
  const timeoutRef = useRef(null);

  const debouncedCallback = useCallback(() => {
    if (isProcessing.current) return;

    isProcessing.current = true;
    callback();

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(() => {
      isProcessing.current = false;
    }, delay);
  }, [callback, delay]);

  return debouncedCallback;
}
