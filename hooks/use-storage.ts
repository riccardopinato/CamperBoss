import { useCallback, useEffect, useState } from "react";
import { storage } from "@/utils/storage";

export function useStorage<T>(key: string, defaultValue: T): [T, (value: T) => void] {
  const [value, setValue] = useState<T>(() => storage.get(key, defaultValue));

  useEffect(() => {
    setValue(storage.get(key, defaultValue));
    return storage.subscribe(key, () => {
      setValue(storage.get(key, defaultValue));
    });
  }, [defaultValue, key]);

  const updateValue = useCallback(
    (newValue: T) => {
      storage.set(key, newValue);
    },
    [key]
  );

  return [value, updateValue];
}
