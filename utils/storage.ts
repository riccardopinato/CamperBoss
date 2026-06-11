import "expo-sqlite/localStorage/install";

type Listener = () => void;

const listeners = new Map<string, Set<Listener>>();
const snapshotCache = new Map<string, { raw: string; value: unknown }>();

export const storage = {
  get<T>(key: string, defaultValue: T): T {
    try {
      const raw = localStorage.getItem(key);
      if (!raw) {
        snapshotCache.delete(key);
        return defaultValue;
      }

      const cached = snapshotCache.get(key);
      if (cached?.raw === raw) {
        return cached.value as T;
      }

      const value = JSON.parse(raw) as T;
      snapshotCache.set(key, { raw, value });
      return value;
    } catch {
      snapshotCache.delete(key);
      return defaultValue;
    }
  },

  set<T>(key: string, value: T): void {
    const raw = JSON.stringify(value);
    localStorage.setItem(key, raw);
    snapshotCache.set(key, { raw, value });
    listeners.get(key)?.forEach((listener) => listener());
  },

  subscribe(key: string, listener: Listener): () => void {
    if (!listeners.has(key)) {
      listeners.set(key, new Set());
    }

    listeners.get(key)?.add(listener);
    return () => listeners.get(key)?.delete(listener);
  }
};
