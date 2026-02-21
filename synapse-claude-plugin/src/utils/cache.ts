/**
 * Local caching utility for Synapse Claude Plugin
 */

export class Cache {
    private cache: Map<string, { value: any; timestamp: number; ttl: number }>;
    private maxSize: number;

    constructor(maxSize: number = 100) {
        this.cache = new Map();
        this.maxSize = maxSize;
    }

    /**
     * Get cached value if it exists and hasn't expired
     */
    get<T>(key: string): T | null {
        const cached = this.cache.get(key);
        if (!cached) {
            return null;
        }

        // Check if expired
        if (Date.now() - cached.timestamp > cached.ttl) {
            this.cache.delete(key);
            return null;
        }

        return cached.value;
    }

    /**
     * Set cached value with TTL
     */
    set<T>(key: string, value: T, ttl: number = 300000): void { // Default 5 minutes
        // Remove oldest items if cache is full
        if (this.cache.size >= this.maxSize) {
            const firstKey = this.cache.keys().next().value;
            this.cache.delete(firstKey);
        }

        this.cache.set(key, {
            value,
            timestamp: Date.now(),
            ttl
        });
    }

    /**
     * Clear cache
     */
    clear(): void {
        this.cache.clear();
    }

    /**
     * Get cache size
     */
    size(): number {
        return this.cache.size;
    }

    /**
     * Check if key exists in cache
     */
    has(key: string): boolean {
        return this.cache.has(key);
    }

    /**
     * Remove specific key from cache
     */
    delete(key: string): boolean {
        return this.cache.delete(key);
    }
}

// Global cache instance
export const cache = new Cache();